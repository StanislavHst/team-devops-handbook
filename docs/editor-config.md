# Спільні налаштування

## .gitignore
* **.env**: чутливі приватні дані.
* **__pycache__/**: можливість виникнення конфліктів версій та ОС.
* ***.tar.gz та *.exe**: у Git публікується нескомпільований вихідний код, а не бінарні файли чи архіви.

## .editorconfig
* `root = true`: зупиняє пошук інших .editorconfig у вищих директоріях.
* `[*]``end_of_line = lf`, щоб уникнути конфліктів між користувачами Windows (crlf) та Linux/Mac (lf).
* `trim_trailing_whitespace = true`, щоб прибрати зайві пробіли.
* `insert_final_newline = true`: стандарт POSIX, необхідний для коректної роботи багатьох консольних утиліт.
* `indent_style = space`, бо ширина табуляції може відрізнятися.
* `[*.py]``indent_style = space; indent_size = 4`, стандартні значення Python.
* `[*.md]``indent_style = space; indent_size = 2`, для невеликого відступу у списках.