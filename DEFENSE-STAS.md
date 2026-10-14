# Захист лабораторної №2 — внесок Стаса

## Короткий висновок

У цій лабораторній я налаштував захищений командний Git workflow: правила для `main`, розподіл відповідальності через `CODEOWNERS`, правила гілок і комітів, перевірку Pull Request, розв'язання конфлікту та локальний Git hook. Додатково реалізував автоматичне формування `CHANGELOG.md` з історії Git.

## 1. Захист `main` і відповідальність за файли

**Показати:**

- [ruleset `Protect main`](https://github.com/StanislavHst/team-devops-handbook/rules/24583555);
- [`.github/CODEOWNERS`](https://github.com/StanislavHst/team-devops-handbook/blob/main/.github/CODEOWNERS).

**Сказати:**

> Для `main` я налаштував ruleset, тому зміни мають проходити через Pull Request і перевірку. У `CODEOWNERS` вказані відповідальні за різні частини репозиторію, щоб GitHub автоматично запитував потрібного reviewer.

## 2. Правила командної роботи

**Показати:** [документацію Git workflow](https://github.com/StanislavHst/team-devops-handbook/blob/main/docs/branching.md).

**Сказати:**

> Ми використовуємо окремі гілки у форматі `feature/ім'я-тема`, Conventional Commits і Pull Request для кожної завершеної зміни. Для злиття використовуємо Squash and merge, щоб одна задача залишала в `main` один зрозумілий коміт.

## 3. Pull Request і code review

**Показати:**

- [PR #3 — моя зміна з виправленням після review](https://github.com/StanislavHst/team-devops-handbook/pull/3);
- [PR #5 — перевірений мною PR іншого учасника](https://github.com/StanislavHst/team-devops-handbook/pull/5).

**Сказати:**

> У PR #3 я був автором. Reviewer знайшов реальну проблему у перевірці пробілів, після чого я виправив її окремим комітом. У PR #5 я був reviewer: залишив конкретне зауваження до документації, автор виправив його, і тільки після цього я схвалив зміни.

## 4. Розв'язання конфлікту

**Показати:**

- [PR #8 — демонстрація конфлікту](https://github.com/StanislavHst/team-devops-handbook/pull/8);
- [неправильний варіант після автоматичного вибору](https://github.com/StanislavHst/team-devops-handbook/commit/ca857a3c6d1f7271c4b1a1cc425155fce87f4350);
- [виправлений варіант](https://github.com/StanislavHst/team-devops-handbook/commit/742321ef1565dcf2162978cc2fa0cd643daa2e21).

**Сказати:**

> Конфлікт виник у `.editorconfig`, тому що дві гілки по-різному змінювали той самий рядок. Спочатку я навмисно показав, що автоматичний вибір однієї сторони може дати синтаксично правильний, але логічно неправильний результат. Потім вручну перевірив значення, виправив його і повторно відправив зміни на review.

**Команди для демонстрації:**

```powershell
git show ca857a3:.editorconfig
git show 742321e:.editorconfig
git diff ca857a3 742321e -- .editorconfig
```

## 5. Git hook і чиста історія

**Показати:**

- [`.githooks/commit-msg`](https://github.com/StanislavHst/team-devops-handbook/blob/main/.githooks/commit-msg);
- [`scripts/test-commit-msg.ps1`](https://github.com/StanislavHst/team-devops-handbook/blob/main/scripts/test-commit-msg.ps1).

**Сказати:**

> Hook перевіряє повідомлення коміту до його створення та пропускає лише погоджений формат Conventional Commits. Шлях до hooks зберігається в конфігурації Git, а тестовий скрипт перевіряє як правильні, так і неправильні приклади повідомлень.

**Команди для демонстрації:**

```powershell
git config --get core.hooksPath
powershell -ExecutionPolicy Bypass -File .\scripts\test-commit-msg.ps1
git log --oneline --graph --decorate -15
```

## 6. Локальна папка та віддалений репозиторій

**Сказати:**

> Назва локальної папки не впливає на Git-репозиторій. Зв'язок із GitHub визначає remote `origin`, тому після перейменування я перевірив шлях, remote і можливість push.

**Команди для демонстрації:**

```powershell
Get-Location
git remote -v
git push --dry-run
```

## 7. Додаткове завдання

**Показати:**

- [`scripts/generate-changelog.ps1`](https://github.com/StanislavHst/team-devops-handbook/blob/main/scripts/generate-changelog.ps1);
- [`CHANGELOG.md`](https://github.com/StanislavHst/team-devops-handbook/blob/main/CHANGELOG.md);
- [PR #9 — актуалізація згенерованого changelog](https://github.com/StanislavHst/team-devops-handbook/pull/9).

**Сказати:**

> Як додаткове завдання я автоматизував формування `CHANGELOG.md`. Скрипт читає історію Git, групує Conventional Commits за типами та створює однаковий відтворюваний результат без ручного копіювання записів.

## Фінальна фраза

> У результаті я не просто додав окремі файли, а побудував перевірюваний командний процес: захищений `main`, відповідальні власники коду, робота через Pull Request, обов'язковий review, контроль формату комітів, практика розв'язання конфлікту та автоматичний changelog.
