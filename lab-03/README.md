# Лабораторна робота 3 — Власний DevOps-інструментарій

## 3. Git-хуки

* `hooks/pre-commit` — бере список файлів **лише з індексу** (`git diff --cached --name-only --diff-filter=ACM`) і лінтить їх: `*.sh` — `shellcheck`, `*.py` — `ruff` (правила E, F, W). Лінтується саме закомічена версія файлу (`git show :файл`), а не копія в робочій теці. Знайдено проблеми — код виходу 1, коміт не створюється.
* `hooks/pre-push` — запускає `pytest lab-03/tests`. Тести впали — код 1, пуш не відбувається.

### Встановлення

Тека `.git/hooks` не версіонується, тому хуки лежать у репозиторії, а git спрямовується на них налаштуванням `core.hooksPath` (виконати один раз у кожному клоні):

```bash
bash lab-03/hooks/install.sh
# те саме вручну:
chmod +x lab-03/hooks/pre-commit lab-03/hooks/pre-push
git config core.hooksPath lab-03/hooks
```

Альтернативи: скопіювати файли в `.git/hooks/` або зробити символічні посилання (`ln -s ../../lab-03/hooks/pre-commit .git/hooks/pre-commit`).

Перевірка: у тестовому репозиторії коміт файлу з `import os` та небезпечним `cat $foo` — відхилено з повідомленням `shellcheck`; коміт чистого `good.py` — пройшов, навіть коли поруч лежав некоректний, але не доданий в індекс файл; пуш із навмисно зламаним тестом — відхилено, із виправленим — пройшов.

### Чому хуки не є засобом контролю

Хук — це файл на комп'ютері розробника. Він **необов'язковий**: його не буде в новому клоні, поки хтось не виконав `install.sh`, його можна змінити або видалити, а `git commit --no-verify` та `git push --no-verify` обходять його одним прапорцем. Він працює в чужому, непередбачуваному середовищі («у мене немає shellcheck», «у мене інша версія Python»), тож результат залежить від машини. Сервер не може дізнатись, чи хук узагалі запускався.

Обов'язкові перевірки в конвеєрі (CI) роблять те, чого хуки не можуть: запускаються **на сервері** для кожного pull request незалежно від того, що зробив автор; працюють у чистому відтворюваному середовищі однієї версії; їх не можна пропустити, а захист гілки `main` (branch protection) забороняє злиття, поки перевірки не зелені; вони мають доступ до секретів і інфраструктури для інтеграційних тестів, збірки й розгортання та залишають публічний, аудитований слід. Тому хуки — це зручність для розробника (швидкий зворотний зв'язок до пуша), а гарантію якості дає лише конвеєр.

---

## 4. Бонус 1 — `monitor.sh`: моніторинг системи

Перевіряє **CPU**, **пам'ять**, **вільне місце на дисках** і **стан заданих процесів/сервісів**. Лише Linux (читає `/proc`), без інтерактивних елементів.

### Запуск

```bash
./monitor.sh                                    # пороги з config/monitor.conf або типові
./monitor.sh --config /etc/monitor.conf
MONITOR_MEM_MAX=1 MONITOR_PROCESSES="sshd nginx" ./monitor.sh
./monitor.sh --help
```

### Пороги — не в коді

Кожне налаштування береться з першого джерела, де воно є: **змінна середовища → конфігураційний файл → типове значення**. Тому в кроні чи в тесті поріг можна змінити, не чіпаючи файл.

| Змінна / ключ у файлі | Типово | Значення |
|---|---|---|
| `MONITOR_CPU_MAX` | 85 | завантаження процесора, % |
| `MONITOR_MEM_MAX` | 90 | використана пам'ять, % |
| `MONITOR_DISK_MAX` | 90 | заповнення диска, % |
| `MONITOR_DISK_PATHS` | `/` | точки монтування через пробіл |
| `MONITOR_PROCESSES` | — | процеси, що мають працювати (`pgrep -x`) |
| `MONITOR_SERVICES` | — | юніти systemd, що мають бути `active` |
| `MONITOR_CPU_SAMPLE` | 1 | скільки секунд міряти CPU |
| `MONITOR_LOG` | `monitor.log` поруч зі скриптом | файл журналу |

Файл конфігурації — прості рядки `КЛЮЧ=значення` з коментарями `#` (див. `config/monitor.conf`). Файл **розбирається, а не виконується** (`source` виконав би будь-який код у ньому), невідомий ключ — помилка, а не мовчазне ігнорування.

Тривога спрацьовує, коли виміряне значення **строго більше** порога.

### Як міряється

* **CPU** — `/proc/stat` читається двічі з паузою `MONITOR_CPU_SAMPLE`; завантаження = `(Δ усього − Δ простою) / Δ усього`. Одна вибірка не годиться: лічильники в `/proc/stat` накопичувальні з моменту старту, тож одне значення дало б середнє за весь час роботи машини.
* **Пам'ять** — `(MemTotal − MemAvailable) / MemTotal`. Береться `MemAvailable`, а не `MemFree`: ядро тримає вільну пам'ять під кеш диска, і за `MemFree` здорова машина виглядала б майже переповненою.
* **Диск** — `df -P` (формат POSIX, один рядок на файлову систему).
* **Процеси** — `pgrep -x` (точний збіг імені, щоб `nginx` не збігся з `nginx-helper`).
* **Сервіси** — `systemctl is-active`; якщо `systemctl` немає — рядок `level=ERROR` і ненульовий код, а не мовчазний «все гаразд».

### Формат виводу

Кожен рядок самодостатній — його можна знайти в журналі через `grep`, не дивлячись на сусідні:

```
<дата час> host=<хост> run=<pid> level=<OK|ALERT|ERROR|SUMMARY> metric=<метрика> value=<значення> threshold=<поріг> msg="<текст>"
```

Поле `run=` — ідентифікатор запуску. Воно з'явилось не випадково: коли два запуски стартують в одну хвилину, їхні рядки в спільному журналі перемішуються, і без `run=` незрозуміло, якому запуску належить рядок.

### Коди виходу

| Код | Значення |
|---|---|
| 0 | усі перевірки пройдені |
| 1 | перевищено поріг або процес/сервіс не працює |
| 2 | неправильні параметри чи конфігурація (немає файлу, невідомий ключ, `MONITOR_CPU_MAX=abc`) |

### Перевірка: штучно занижені пороги

```
$ ./monitor.sh
2026-11-10 19:28:58 host=vm run=1820 level=OK metric=cpu value=1.5 threshold=85 msg="CPU usage is 1.5% (limit 85%)"
2026-11-10 19:28:58 host=vm run=1820 level=OK metric=memory value=6.0 threshold=90 msg="memory usage is 6.0% (limit 90%)"
2026-11-10 19:28:58 host=vm run=1820 level=OK metric=disk:/ value=31 threshold=90 msg="disk usage of / is 31% (limit 90%)"
2026-11-10 19:28:58 host=vm run=1820 level=SUMMARY metric=overall value=alerts=0 threshold=- msg="all checks passed"
код виходу: 0

$ MONITOR_MEM_MAX=1 MONITOR_DISK_MAX=1 MONITOR_PROCESSES="bash definitely-not-running" ./monitor.sh
2026-11-10 19:28:59 host=vm run=1845 level=OK metric=cpu value=1.0 threshold=85 msg="CPU usage is 1.0% (limit 85%)"
2026-11-10 19:28:59 host=vm run=1845 level=ALERT metric=memory value=6.0 threshold=1 msg="memory usage is 6.0% which exceeds 1%"
2026-11-10 19:28:59 host=vm run=1845 level=ALERT metric=disk:/ value=31 threshold=1 msg="disk usage of / is 31% which exceeds 1%"
2026-11-10 19:28:59 host=vm run=1845 level=OK metric=process:bash value=running threshold=- msg="process bash is running"
2026-11-10 19:28:59 host=vm run=1845 level=ALERT metric=process:definitely-not-running value=not_running threshold=- msg="process definitely-not-running is not running"
2026-11-10 19:28:59 host=vm run=1845 level=SUMMARY metric=overall value=alerts=3 threshold=- msg="3 problem(s) found"
код виходу: 1
```

Процесор перевірено окремо: поки дві команди `while :; do :; done` вантажили машину, `MONITOR_CPU_MAX=5` дав `level=ALERT metric=cpu value=100.0 threshold=5`.

### Запуск за розкладом через `cron`

Запис у `crontab -e` (у реальному використанні — раз на 5 хвилин, тут для демонстрації — щохвилини):

```cron
PATH=/usr/local/bin:/usr/bin:/bin
# звичайний запис: нормальні пороги
* * * * * /home/claude/work/lab-03/monitor.sh >/dev/null 2>&1
# демонстраційний запис: штучно низький поріг пам'яті і процес, якого немає
* * * * * MONITOR_MEM_MAX=1 MONITOR_PROCESSES="no-such-daemon" /home/claude/work/lab-03/monitor.sh >/dev/null 2>&1
```

* Шлях до скрипта **абсолютний**: cron запускає команди з іншої робочої теки й зі спрощеним `PATH`.
* `>/dev/null 2>&1`: скрипт сам пише журнал, а без перенаправлення cron намагається відправити вивід поштою.
* Змінні задаються прямо в рядку cron — тому два записи мають різні пороги без зміни файлів.

Фрагмент `monitor.log` після трьох хвилин роботи демона cron (по два запуски щохвилини; для стислості лише тривоги й підсумки, групувати за `run=`):

```
2026-11-10 17:26:02 run=1276 level=SUMMARY ... value=alerts=0 msg="all checks passed"
2026-11-10 17:26:02 run=1277 level=ALERT   metric=memory value=5.8 msg="memory usage is 5.8% which exceeds 1%"
2026-11-10 17:26:02 run=1277 level=ALERT   metric=process:no-such-daemon value=not_running msg="process no-such-daemon is not running"
2026-11-10 17:26:02 run=1277 level=SUMMARY ... value=alerts=2 msg="2 problem(s) found"
2026-11-10 17:27:02 run=1337 level=ALERT   metric=memory value=5.8 msg="memory usage is 5.8% which exceeds 1%"
2026-11-10 17:27:02 run=1337 level=ALERT   metric=process:no-such-daemon value=not_running msg="process no-such-daemon is not running"
2026-11-10 17:27:02 run=1337 level=SUMMARY ... value=alerts=2 msg="2 problem(s) found"
2026-11-10 17:27:02 run=1338 level=SUMMARY ... value=alerts=0 msg="all checks passed"
2026-11-10 17:28:02 run=1410 level=ALERT   metric=memory value=5.6 msg="memory usage is 5.6% which exceeds 1%"
2026-11-10 17:28:02 run=1410 level=ALERT   metric=process:no-such-daemon value=not_running msg="process no-such-daemon is not running"
2026-11-10 17:28:02 run=1410 level=SUMMARY ... value=alerts=2 msg="2 problem(s) found"
2026-11-10 17:28:02 run=1411 level=SUMMARY ... value=alerts=0 msg="all checks passed"
```

Час у журналі — 17:2x, хоча на годиннику було 19:2x (UTC+2): cron запускає завдання без `TZ` користувача, тож скрипт бачить UTC. Це варто пам'ятати, зіставляючи журнал із іншими джерелами; за потреби в crontab додається `TZ=Europe/Kyiv`.
