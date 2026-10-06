# Гілки, коміти та pull requests

Цей документ визначає єдиний Git workflow для командної роботи над handbook.

## 1. Захищена гілка `main`

`main` містить лише перевірені зміни. Для неї діє активний GitHub Ruleset
`Protect main`:

- усі зміни потрапляють через pull request;
- потрібні два approvals;
- для файлів із `CODEOWNERS` потрібен approval code owner;
- новий commit скидає застарілі approvals;
- усі review conversations мають бути закриті;
- дозволено лише Squash merge;
- історія має бути лінійною;
- force push і видалення гілки заборонені;
- bypass list порожній, тому правила діють також для власника репозиторію.

Прямий push у `main` не використовується навіть для маленьких виправлень.

## 2. Назви гілок

Формат:

```text
<type>/<name>-<topic>
```

Дозволені типи:

| Тип | Призначення |
|---|---|
| `feature` | Нова змістовна частина handbook або автоматизація |
| `fix` | Виправлення дефекту в уже наявній поведінці |
| `docs` | Окрема зміна лише документації |

Правильні приклади:

```text
feature/stas-branching
feature/zhenya-editor-config
feature/max-readme-review
fix/max-ssh-example
docs/zhenya-conflict-explanation
```

Неправильні приклади:

```text
new-branch
my_changes
fix
stas
final-version
```

Назва має показувати автора і тему без відкривання pull request.

## 3. Створення робочої гілки

Перед кожною новою зміною потрібно почати з актуального `main`:

```bash
git switch main
git pull --rebase origin main
git switch -c feature/<name>-<topic>
git branch --show-current
```

Не можна створювати свою гілку від feature-гілки іншого учасника. Інакше в
pull request можуть потрапити чужі коміти й файли.

## 4. Формат повідомлень комітів

Використовується формат Conventional Commits:

```text
type(scope): imperative summary
```

Дозволені типи:

| Тип | Коли використовувати |
|---|---|
| `feat` | Додано нову можливість або автоматизацію |
| `fix` | Виправлено неправильну поведінку |
| `docs` | Змінено документацію |
| `chore` | Налаштовано репозиторій або допоміжні файли |
| `refactor` | Перебудовано реалізацію без зміни поведінки |
| `test` | Додано або змінено перевірки |
| `ci` | Змінено CI-конфігурацію |
| `build` | Змінено процес складання |

Вимоги до summary:

- англійською мовою, щоб повідомлення були однорідними;
- починається з дієслова в наказовій формі: `add`, `define`, `document`,
  `ignore`, `validate`;
- описує одну логічну зміну;
- не закінчується крапкою;
- має від 5 до 72 символів після двокрапки.

Правильні повідомлення:

```text
docs(branching): explain feature branch workflow
fix(config): ignore environment files
chore(repo): configure code owners
feat(changelog): generate report from git history
```

Неправильні повідомлення:

```text
fix
fix2
update
try again
wip
final version
Added files.
```

Погані варіанти не пояснюють, що саме змінилося, і засмічують історію.

## 5. Підготовка commit

Перед додаванням файлів:

```bash
git status --short
git diff
```

Додавати потрібно конкретні файли:

```bash
git add docs/branching.md
git diff --cached
git diff --cached --check
```

`git add .` не використовується без попередньої перевірки status, тому що він
може випадково додати секрети, тимчасові файли або чужі зміни.

Після перевірки staged diff:

```bash
git commit -m "docs(branching): explain feature branch workflow"
git push -u origin feature/<name>-<topic>
```

## 6. Pull request

Pull request відкривається з робочої гілки в `main` і містить:

- короткий Conventional Commit title;
- перелік зроблених змін;
- інструкцію перевірки;
- відомі обмеження, якщо вони є.

Приклад опису:

```markdown
## Що зроблено
- додано правила назв гілок;
- визначено формат повідомлень комітів;
- описано review та Squash merge.

## Як перевірити
- переглянути приклади правильних і неправильних назв;
- виконати `git diff --check`;
- перевірити, що внутрішні посилання Markdown працюють.
```

Draft PR не використовують для фінальної перевірки, оскільки code owners не
запитуються автоматично, доки PR не переведено в `Ready for review`.

## 7. Code review

Кожен основний PR проходить таку послідовність:

1. Reviewer читає опис і весь diff у вкладці `Files changed`.
2. Reviewer залишає щонайменше одне змістовне зауваження до конкретного рядка.
3. Reviewer надсилає review через `Request changes`.
4. Автор виправляє зауваження в тій самій гілці.
5. Виправлення оформлюється окремим commit.
6. Автор виконує звичайний `git push` без `--force`.
7. Попередні approvals стають stale.
8. Reviewers перевіряють новий commit і повторно натискають `Approve`.
9. Conversation закривається тільки після виправлення або аргументованого
   відхилення зауваження.
10. Після двох approvals виконується Squash merge.

Приклад окремого commit після review:

```text
docs(branching): clarify branch cleanup workflow
```

Після початку review заборонено:

```bash
git commit --amend
git rebase -i
git push --force
```

Ці команди переписують SHA перевірених комітів і ускладнюють аудит review.

## 8. Чому використовується Squash merge

Feature-гілка навмисно зберігає окремий початковий commit і окремий commit із
виправленням після review. Це робить процес перевірки видимим у pull request.

Squash merge перетворює всі коміти PR на один змістовний commit у `main`.
Таким чином:

- review-історія залишається в pull request;
- `main` не містить технічних `fix review` або `try again`;
- один merged PR відповідає одній завершеній зміні;
- `git log` легко читати під час захисту.

## 9. Оновлення після merge

Після успішного Squash merge:

```bash
git switch main
git pull --rebase origin main
git branch -d feature/<name>-<topic>
git fetch --prune
```

Через squash локальний Git іноді не вважає feature-гілку буквально merged. У
такому разі після перевірки merged PR дозволено видалити лише цю завершену
локальну гілку:

```bash
git branch -D feature/<name>-<topic>
```

Remote feature-гілки автоматично видаляються після merge налаштуванням
репозиторію.

## 10. Перевірка чистої історії

```bash
git switch main
git pull --rebase origin main
git log --oneline --decorate --graph -20
```

У `main` не повинно бути повідомлень:

```text
fix
fix2
try again
wip
update
```

У PowerShell їх можна знайти так:

```powershell
git log --format="%s" |
  Select-String -Pattern "^(fix|fix2|wip|try again|update)$"
```

Порожній результат означає, що таких повідомлень немає.
