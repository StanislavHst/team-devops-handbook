#!/usr/bin/env bash
set -euo pipefail

# Exit Codes
# 0 - Success
# 1 - Invalid or missing arguments
# 2 - Source directory does not exist
# 3 - Cannot create destination directory
# 4 - Archive compression failed

LOG_FILE="backup.log"
RETENTION=5
DRY_RUN=false
SOURCE_DIR=""
DEST_DIR=""

log_action() {
    local status="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$status] $message"
    echo "[$timestamp] [$status] $message" >> "$LOG_FILE"
}

show_help() {
    cat << EOF
Використання: $(basename "$0") [ОПЦІЇ] <вихідна_тека> <тека_призначення>

Призначення:
  Створює стиснений архів (.tar.gz) вказаної теки, зберігає його в цільову теку
  та автоматично видаляє застарілі копії (ротація).

Параметри:
  <вихідна_тека>       Тека, вміст якої потрібно зарезервувати (обов'язково).
  <тека_призначення>   Тека, куди зберігаються архіви (обов'язково).

Опції:
  -r, --retention N    Кількість останніх архівів для збереження (за замовчуванням: 5).
  --dry-run            Режим симуляції: показує заплановані дії без зміни файлів.
  -h, --help           Показати цю довідку та вийти.

Приклад запуску:
  $(basename "$0") --dry-run /home/user/data /var/backups
  $(basename "$0") -r 3 /home/user/data /var/backups
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -r|--retention)
            if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                log_action "ERROR" "Параметр --retention вимагає додатного числового значення."
                exit 1
            fi
            RETENTION="$2"
            shift 2
            ;;
        -*)
            log_action "ERROR" "Невідомий параметр: $1. Використовуйте --help."
            exit 1
            ;;
        *)
            if [[ -z "$SOURCE_DIR" ]]; then
                SOURCE_DIR="$1"
            elif [[ -z "$DEST_DIR" ]]; then
                DEST_DIR="$1"
            else
                log_action "ERROR" "Забагато аргументів: $1. Використовуйте --help."
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$SOURCE_DIR" ]] || [[ -z "$DEST_DIR" ]]; then
    log_action "ERROR" "Не вказано обов'язкові параметри: <вихідна_тека> або <тека_призначення>."
    echo "Запустіть '$(basename "$0") --help' для довідки."
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    log_action "ERROR" "Вихідна тека не існує: $SOURCE_DIR"
    exit 2
fi

if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$DEST_DIR" || {
        log_action "ERROR" "Неможливо створити теку призначення: $DEST_DIR"
        exit 3
    }
fi

TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"
TARGET_PATH="${DEST_DIR%/}/${ARCHIVE_NAME}"

if [[ "$DRY_RUN" == true ]]; then
    log_action "DRY-RUN" "Створення архіву [симуляція]: $TARGET_PATH з теки $SOURCE_DIR"
else
    log_action "INFO" "Початок створення архіву: $TARGET_PATH"
    if tar -czf "$TARGET_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null; then
        log_action "SUCCESS" "Архів успішно створено: $TARGET_PATH"
    else
        log_action "ERROR" "Помилка при створенні архіву через tar."
        exit 4
    fi
fi

if [[ -d "$DEST_DIR" ]]; then
    ARCHIVE_LIST=($(find "$DEST_DIR" -maxdepth 1 -name "backup_*.tar.gz" -type f | sort))
    TOTAL_ARCHIVES=${#ARCHIVE_LIST[@]}

    if [[ "$TOTAL_ARCHIVES" -gt "$RETENTION" ]]; then
        EXCESS_COUNT=$((TOTAL_ARCHIVES - RETENTION))
        log_action "INFO" "Знайдено $TOTAL_ARCHIVES архівів (ліміт: $RETENTION). Необхідно видалити: $EXCESS_COUNT."

        for ((i=0; i<EXCESS_COUNT; i++)); do
            FILE_TO_DELETE="${ARCHIVE_LIST[$i]}"
            if [[ "$DRY_RUN" == true ]]; then
                log_action "DRY-RUN" "Видалення застарілого архіву [симуляція]: $FILE_TO_DELETE"
            else
                rm -f "$FILE_TO_DELETE"
                log_action "SUCCESS" "Видалено застарілий архів: $FILE_TO_DELETE"
            fi
        done
    fi
fi

log_action "Резервне копіювання завершено успішно (Exit: 0)."
exit 0