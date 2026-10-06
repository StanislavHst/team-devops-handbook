# Team DevOps Handbook

Командний довідник із практик Git, оформлення документації та перевірки
консольних утиліт. Репозиторій створено для лабораторної роботи №2 з курсу
DevOps.

## Мета

- узгодити правила роботи з гілками та повідомленнями комітів;
- визначити спільні налаштування редактора та правила ігнорування файлів;
- створити шаблон README для консольних утиліт;
- сформувати однозначний checklist для code review;
- на практиці пройти pull request, review, виправлення зауважень і розв’язання
  конфлікту;
- зберегти чисту та зрозумілу історію гілки `main`.

## Команда

| Учасник | GitHub | Зона відповідальності |
|---|---|---|
| Стас | [@StanislavHst](https://github.com/StanislavHst) | Git workflow, правила гілок і комітів, Git hooks та автоматизація |
| Женя | [@Bishop-mstr](https://github.com/Bishop-mstr) | `.editorconfig`, `.gitignore` та документування конфлікту |
| Макс | [@MaxfeedLeyn](https://github.com/MaxfeedLeyn) | Шаблон README для CLI та checklist для code review |

## Структура

```text
.
├── .github/
│   └── CODEOWNERS
├── .githooks/
├── assets/
├── docs/
│   ├── branching.md
│   ├── code-review.md
│   ├── conflict.md
│   ├── editor-config.md
│   └── readme-template.md
├── scripts/
├── .editorconfig
├── .gitignore
├── CHANGELOG.md
└── README.md
```

## Правила внесення змін

1. Оновити локальну гілку `main`.
2. Створити окрему гілку `feature/<name>-<topic>`.
3. Зробити змістовні коміти та відправити гілку на GitHub.
4. Відкрити pull request у `main`.
5. Отримати два approvals, зокрема approval від code owner.
6. Виправляти зауваження окремими комітами без переписування історії.
7. Закрити всі review discussions.
8. Об’єднати pull request через Squash merge.

Прямі push у `main`, force push і видалення захищеної гілки заборонені
правилами репозиторію.
