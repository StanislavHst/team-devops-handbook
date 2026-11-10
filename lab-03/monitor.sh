#!/usr/bin/env bash
# monitor.sh — checks CPU, memory, disk space and processes/services of this
# machine and signals when a threshold is exceeded. Designed for cron.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Exit codes
readonly E_OK=0
readonly E_ALERT=1     # at least one threshold exceeded / service down
readonly E_USAGE=2     # bad parameters, bad or missing config

usage() {
    cat <<'EOF'
monitor.sh — check CPU, memory, disk space and processes/services of this
machine; log every result and exit non-zero if any threshold is exceeded.
Linux only (reads /proc). No interactive elements: safe to run from cron.

USAGE
  monitor.sh [--config <file>] [--help]

SETTINGS (environment variable wins over config file, config file over default)
  MONITOR_CPU_MAX       CPU usage threshold, %            (default: 85)
  MONITOR_MEM_MAX       memory used threshold, %          (default: 90)
  MONITOR_DISK_MAX      disk used threshold, %            (default: 90)
  MONITOR_DISK_PATHS    space-separated mount points      (default: "/")
  MONITOR_PROCESSES     space-separated process names that must be running
                        (checked with pgrep -x)           (default: none)
  MONITOR_SERVICES      space-separated systemd units that must be active
                        (checked with systemctl)          (default: none)
  MONITOR_CPU_SAMPLE    seconds to sample CPU over        (default: 1)
  MONITOR_LOG           log file                          (default: monitor.log next to the script)

  An alert fires when the measured value is STRICTLY GREATER than the threshold.

CONFIG FILE
  KEY=VALUE lines using the names above, '#' starts a comment. Default location:
  config/monitor.conf next to the script, or the file given with --config
  (also MONITOR_CONFIG). The file is parsed, never executed.

OUTPUT
  One self-contained line per check:
  <date time> host=<host> run=<pid> level=<OK|ALERT|ERROR|SUMMARY> metric=<m> value=<v> threshold=<t> msg="<text>"
  (run=<pid> identifies one run, so lines of overlapping runs can be told apart)

EXIT CODES
  0  all checks passed
  1  a threshold was exceeded or a process/service is down
  2  invalid parameters or configuration

EXAMPLE
  ./monitor.sh
  MONITOR_MEM_MAX=1 MONITOR_PROCESSES="sshd nginx" ./monitor.sh --config config/monitor.conf
  */5 * * * * /opt/lab-03/monitor.sh >/dev/null 2>&1      # crontab entry
EOF
}

# ---------- arguments ----------
CONFIG_FILE="${MONITOR_CONFIG:-}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --config)  [[ $# -ge 2 ]] || { echo "monitor.sh: --config requires a value" >&2; exit "$E_USAGE"; }
                   CONFIG_FILE="$2"; shift 2 ;;
        --help|-h) usage; exit "$E_OK" ;;
        *)         echo "monitor.sh: unknown option: $1 (see --help)" >&2; exit "$E_USAGE" ;;
    esac
done

# ---------- configuration ----------
KEYS=(CPU_MAX MEM_MAX DISK_MAX DISK_PATHS PROCESSES SERVICES CPU_SAMPLE LOG)
declare -A DEFAULTS=(
    [CPU_MAX]=85 [MEM_MAX]=90 [DISK_MAX]=90 [DISK_PATHS]="/"
    [PROCESSES]="" [SERVICES]="" [CPU_SAMPLE]=1 [LOG]="$SCRIPT_DIR/monitor.log"
)
declare -A FILE_CFG=()

if [[ -z "$CONFIG_FILE" && -f "$SCRIPT_DIR/config/monitor.conf" ]]; then
    CONFIG_FILE="$SCRIPT_DIR/config/monitor.conf"
fi

if [[ -n "$CONFIG_FILE" ]]; then
    [[ -f "$CONFIG_FILE" && -r "$CONFIG_FILE" ]] || {
        echo "monitor.sh: config file not found or not readable: $CONFIG_FILE" >&2; exit "$E_USAGE"; }
    lineno=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        lineno=$((lineno + 1))
        line="${line%%#*}"                                   # strip comments
        line="${line#"${line%%[![:space:]]*}"}"              # trim left
        line="${line%"${line##*[![:space:]]}"}"              # trim right
        [[ -z "$line" ]] && continue
        if [[ "$line" != *=* ]]; then
            echo "monitor.sh: $CONFIG_FILE:$lineno: expected KEY=VALUE" >&2; exit "$E_USAGE"
        fi
        key="${line%%=*}"; val="${line#*=}"
        key="${key%"${key##*[![:space:]]}"}"
        val="${val#"${val%%[![:space:]]*}"}"
        val="${val#\"}"; val="${val%\"}"                     # optional double quotes
        key="${key#MONITOR_}"
        if [[ ! " ${KEYS[*]} " == *" $key "* ]]; then
            echo "monitor.sh: $CONFIG_FILE:$lineno: unknown setting '$key'" >&2; exit "$E_USAGE"
        fi
        FILE_CFG[$key]="$val"
    done <"$CONFIG_FILE"
fi

declare -A CFG=()
for key in "${KEYS[@]}"; do
    envname="MONITOR_$key"
    if [[ -n "${!envname+x}" ]]; then
        CFG[$key]="${!envname}"
    elif [[ -n "${FILE_CFG[$key]+x}" ]]; then
        CFG[$key]="${FILE_CFG[$key]}"
    else
        CFG[$key]="${DEFAULTS[$key]}"
    fi
done

is_number() { [[ "$1" =~ ^[0-9]+([.][0-9]+)?$ ]]; }
for key in CPU_MAX MEM_MAX DISK_MAX; do
    if ! { is_number "${CFG[$key]}" && awk -v v="${CFG[$key]}" 'BEGIN{exit !(v<=100)}'; }; then
        echo "monitor.sh: MONITOR_$key must be a number between 0 and 100, got '${CFG[$key]}'" >&2
        exit "$E_USAGE"
    fi
done
is_number "${CFG[CPU_SAMPLE]}" || { echo "monitor.sh: MONITOR_CPU_SAMPLE must be a number" >&2; exit "$E_USAGE"; }
[[ -r /proc/stat && -r /proc/meminfo ]] || { echo "monitor.sh: needs Linux /proc" >&2; exit "$E_USAGE"; }

LOG_FILE="${CFG[LOG]}"
HOST="$(hostname 2>/dev/null || echo unknown)"
ALERTS=0

# emit <level> <metric> <value> <threshold> <message>
emit() {
    local level="$1" metric="$2" value="$3" threshold="$4" msg="$5" line
    line="$(date '+%Y-%m-%d %H:%M:%S') host=$HOST run=$$ level=$level metric=$metric value=$value threshold=$threshold msg=\"$msg\""
    printf '%s\n' "$line"
    printf '%s\n' "$line" >>"$LOG_FILE" 2>/dev/null || true
    if [[ "$level" == "ALERT" ]]; then
        ALERTS=$((ALERTS + 1))
    fi
}

exceeds() { awk -v v="$1" -v t="$2" 'BEGIN{exit !(v>t)}'; }

check_threshold() {   # <metric> <value> <max> <unit-text>
    local metric="$1" value="$2" max="$3" what="$4"
    if exceeds "$value" "$max"; then
        emit ALERT "$metric" "$value" "$max" "$what is ${value}% which exceeds ${max}%"
    else
        emit OK "$metric" "$value" "$max" "$what is ${value}% (limit ${max}%)"
    fi
}

# ---------- CPU: two samples of /proc/stat ----------
cpu_usage() {
    local a b
    a="$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat)"
    sleep "${CFG[CPU_SAMPLE]}"
    b="$(awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat)"
    awk -v a="$a" -v b="$b" 'BEGIN{
        split(a, x, " "); split(b, y, " ");
        total = y[1] - x[1]; idle = y[2] - x[2];
        if (total <= 0) { print "0.0"; exit }
        printf "%.1f\n", (total - idle) * 100 / total }'
}

# ---------- memory: (MemTotal - MemAvailable) / MemTotal ----------
mem_usage() {
    awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{
        if (t <= 0) { print "0.0"; exit }
        printf "%.1f\n", (t - a) * 100 / t }' /proc/meminfo
}

# ---------- disk ----------
disk_usage() {   # <path> -> integer percent used
    df -P -- "$1" 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}'
}

check_threshold cpu "$(cpu_usage)" "${CFG[CPU_MAX]}" "CPU usage"
check_threshold memory "$(mem_usage)" "${CFG[MEM_MAX]}" "memory usage"

read -ra DISKS <<<"${CFG[DISK_PATHS]}"
for path in "${DISKS[@]}"; do
    pct="$(disk_usage "$path" || true)"
    if [[ -z "$pct" ]]; then
        emit ERROR "disk:$path" "n/a" "${CFG[DISK_MAX]}" "cannot read disk usage of $path"
        ALERTS=$((ALERTS + 1))
    else
        check_threshold "disk:$path" "$pct" "${CFG[DISK_MAX]}" "disk usage of $path"
    fi
done

read -ra PROCS <<<"${CFG[PROCESSES]}"
for p in "${PROCS[@]}"; do
    if pgrep -x -- "$p" >/dev/null 2>&1; then
        emit OK "process:$p" running - "process $p is running"
    else
        emit ALERT "process:$p" not_running - "process $p is not running"
    fi
done

read -ra SVCS <<<"${CFG[SERVICES]}"
for s in "${SVCS[@]}"; do
    if ! command -v systemctl >/dev/null 2>&1; then
        emit ERROR "service:$s" unknown - "systemctl is not available, cannot check service $s"
        ALERTS=$((ALERTS + 1))
    elif state="$(systemctl is-active -- "$s" 2>/dev/null)"; then
        emit OK "service:$s" "$state" - "service $s is $state"
    else
        emit ALERT "service:$s" "${state:-unknown}" - "service $s is ${state:-unknown} (expected active)"
    fi
done

if [[ "$ALERTS" -gt 0 ]]; then
    emit SUMMARY overall "alerts=$ALERTS" - "$ALERTS problem(s) found"
    exit "$E_ALERT"
fi
emit SUMMARY overall "alerts=0" - "all checks passed"
exit "$E_OK"
