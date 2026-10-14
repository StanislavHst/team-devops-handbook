# Лабораторна робота №2 — внесок Стаса

## Результат роботи

Налаштовано командний Git workflow із захищеною гілкою `main`, розподілом відповідальності за файли, обов'язковим code review та контрольованим злиттям змін. Окремо реалізовано перевірку повідомлень комітів, практичне розв'язання конфлікту та автоматичне формування журналу змін.

## 1. Захист основної гілки

Для `main` створено активний ruleset [`Protect main`](https://github.com/StanislavHst/team-devops-handbook/rules/24583555). Зміни до захищеної гілки проходять через Pull Request і перевірку учасниками команди.

Власники окремих частин репозиторію визначені у файлі [`.github/CODEOWNERS`](https://github.com/StanislavHst/team-devops-handbook/blob/main/.github/CODEOWNERS). Завдяки цьому GitHub автоматично призначає відповідального reviewer для змінених файлів.

## 2. Правила командної розробки

У документі [`docs/branching.md`](https://github.com/StanislavHst/team-devops-handbook/blob/main/docs/branching.md) зафіксовано:

- створення окремої гілки для кожної задачі;
- формат назв гілок `feature/ім'я-тема`;
- використання Conventional Commits;
- перевірку змін через Pull Request;
- використання Squash and merge для чистої історії `main`.

## 3. Робота з Pull Request і code review

У [PR #3](https://github.com/StanislavHst/team-devops-handbook/pull/3) виконано роль автора змін. Під час review було знайдено проблему в перевірці пробілів. Зауваження виправлено окремим комітом, після чого зміни пройшли повторну перевірку.

У [PR #5](https://github.com/StanislavHst/team-devops-handbook/pull/5) виконано роль reviewer. Виявлено недостатнє пояснення параметрів у документації. Після виправлення автором оновлений варіант було перевірено та схвалено.

Ці два PR демонструють повний цикл code review з обох сторін: отримання зауваження та перевірку чужої роботи.

## 4. Розв'язання конфлікту

У [PR #8](https://github.com/StanislavHst/team-devops-handbook/pull/8) відтворено конфлікт у `.editorconfig`: дві незалежні гілки по-різному змінили один рядок.

Після автоматичного вибору однієї сторони утворився [синтаксично правильний, але логічно неправильний варіант](https://github.com/StanislavHst/team-devops-handbook/commit/ca857a3c6d1f7271c4b1a1cc425155fce87f4350). Значення було перевірено вручну та виправлено в [наступному коміті](https://github.com/StanislavHst/team-devops-handbook/commit/742321ef1565dcf2162978cc2fa0cd643daa2e21).

Порівняння двох станів:

```powershell
git show ca857a3:.editorconfig
git show 742321e:.editorconfig
git diff ca857a3 742321e -- .editorconfig
```

## 5. Контроль повідомлень комітів

Git hook [`.githooks/commit-msg`](https://github.com/StanislavHst/team-devops-handbook/blob/main/.githooks/commit-msg) перевіряє повідомлення до створення коміту. Допускаються повідомлення у форматі Conventional Commits, наприклад:

```text
docs(branching): explain review workflow
```

Автоматичні позитивні та негативні перевірки hook реалізовано у [`scripts/test-commit-msg.ps1`](https://github.com/StanislavHst/team-devops-handbook/blob/main/scripts/test-commit-msg.ps1).

```powershell
git config --get core.hooksPath
powershell -ExecutionPolicy Bypass -File .\scripts\test-commit-msg.ps1
git log --oneline --graph --decorate -15
```

## 6. Перевірка локального репозиторію

Локальну папку проєкту перейменовано без зміни історії та зв'язку з GitHub. Віддалений репозиторій продовжує визначатися параметром `origin`.

```powershell
Get-Location
git remote -v
git push --dry-run
```

## 7. Додаткове завдання

Реалізовано [`scripts/generate-changelog.ps1`](https://github.com/StanislavHst/team-devops-handbook/blob/main/scripts/generate-changelog.ps1), який формує [`CHANGELOG.md`](https://github.com/StanislavHst/team-devops-handbook/blob/main/CHANGELOG.md) на основі історії Git і групує Conventional Commits за типами.

Оновлення згенерованого журналу змін оформлено окремим [PR #9](https://github.com/StanislavHst/team-devops-handbook/pull/9), тому результат можна перевірити так само, як інші командні зміни.

## Висновок

У результаті створено перевірюваний командний процес: захищений `main`, визначені власники коду, робота через окремі гілки та Pull Request, обов'язковий review, контроль формату комітів, ручне розв'язання конфліктів і автоматичне ведення журналу змін.
