# Спільні налаштування

## .gitignore
* **.env**: чутливі приватні дані.
* **__pycache__/**: можливість виникнення конфліктів версій та ОС.
* ***.tar.gz та *.exe**: у Git публікується нескомпільований вихідний код, а не бінарники чи архіви.

## .editorconfig
* `[*]``end_of_line = lf`, щоб уникнути конфліктів між користувачами Windows (crlf) та Linux/Mac (lf). `trim_trailing_whitespace = true`, щоб прибрати зайві пробіли.
* `[*.py]``indent_style = space; indent_size = 4`, стандартні значення Python.
* `[*.md]``indent_style = space; indent_size = 2`, для невеликого відступу у списках.