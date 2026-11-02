# Лабораторная работа № 2

SQL-запросы и аналитические сценарии для реляционной БД (домен ЛР1: вуз).

Схема вычислений и состав файлов:

```
lab2/
  migrations/
    0001_add_grades.up.sql          — операционная таблица grades (расширение модели)
    0001_add_grades.down.sql        — откат расширения
    0002_seed_grades_data.up.sql    — тестовые данные (91 ведомость)
    0002_seed_grades_data.down.sql  — откат данных
  01_dml.sql                        — Часть 1.2: INSERT/UPDATE/DELETE/ROLLBACK
  02_queries_joins.sql              — Часть 2.1: 3 запроса с JOIN
  03_queries_aggregates.sql         — Часть 2.2: 3 запроса с GROUP BY
  04_subqueries.sql                 — Часть 3: 4 запроса с подзапросами
  05_cte_report.sql                 — Часть 4: аналитический отчёт с CTE
```

## Порядок применения

Через `psql` (из каталога `lab2/`):

```bash
psql "$DATABASE_URL" -f migrations/0001_add_grades.up.sql
psql "$DATABASE_URL" -f migrations/0002_seed_grades_data.up.sql
psql "$DATABASE_URL" -f 01_dml.sql
psql "$DATABASE_URL" -f 02_queries_joins.sql
psql "$DATABASE_URL" -f 03_queries_aggregates.sql
psql "$DATABASE_URL" -f 04_subqueries.sql
psql "$DATABASE_URL" -f 05_cte_report.sql
```

Или через golang-migrate (формат файлов совпадает):

```bash
migrate -path migrations -database "$DATABASE_URL" up      # применить все
migrate -path migrations -database "$DATABASE_URL" down 1  # откатить последнюю
```

## Замечания

- `01_dml.sql` выполнять в autocommit (не оборачивать весь файл в транзакцию):
  пункт 5 демонстрирует частичный откат через `ROLLBACK`.
- Идентификаторы данных: миграция 0002 — диапазон `100000-199999`,
  сценарий DML — `200000+`, поэтому откат миграций не задевает чужие данные.
- Предметная область не менялась; расширение (`grades`) обосновано в
  комментарии к миграции 0001 и соответствует требованию ТЗ о сохранении
  ранее созданных данных.
