#### V1__init.sql

Baseline migration.  
Початкова версія схеми, створена лише для фіксації стартового стану БД у Flyway. SQL-змін не містить. Використовується для `baselineOnMigrate=true`.

---

#### V2__add_date_to_release.sql

Додано стовпець `date_` типу `date` до таблиці `release_`.

---

#### V3__delete_date_from_review.sql

Видалено стовпець `review_date` з таблиці `review`.

---

#### V4__create_investment_table.sql

Створено таблицю `investment`:

- `id` — первинний ключ;
- `name` — назва інвестиції;
- `amount` — сума інвестиції;
- `date_` — дата;
- `project` — зовнішній ключ на `project(project_id)`.

Для зовнішнього ключа налаштовано:

- `ON DELETE SET NULL`;
- `ON UPDATE CASCADE`.

Таблиця реалізує зв’язок між `investment` і `project` типу «багато-до-одного».