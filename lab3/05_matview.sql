-- ЛР3, часть 3. MATERIALIZED VIEW с обоснованием
--          часть 4. Допустимая задержка и политика обновления
--
-- Скрипт идемпотентен: представление и индекс пересоздаются.

-- ---------------------------------------------------------------------------
-- 3. Материализованное представление mv_discipline_stats.
--
-- Что считает: сводку по каждой дисциплине — сколько курсов её читают, сколько
-- попыток сдачи было, сколько из них успешных и проваленных, средний балл.
--
-- Почему материализованное представление, а не обычное:
--   * агрегат строится по всей таблице grades (попытки всех студентов за все
--     годы) с соединением disciplines -> courses -> grades;
--   * такие сводки нужны для регулярных отчётов по кафедрам (сравнение
--     дисциплин, поиск «провальных» предметов) и читаются гораздо чаще, чем
--     меняются оценки;
--   * цена пересчёта высока, цена чтения готового результата — одна выборка,
--     поэтому результат выгодно хранить физически.
--
-- LEFT JOIN сохранён, чтобы в отчёт попадали и дисциплины без курсов/оценок
-- (у них attempts = 0), — отчёт не должен «терять» предметы.
-- ---------------------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS mv_discipline_stats;

CREATE MATERIALIZED VIEW mv_discipline_stats AS
SELECT d.id                               AS discipline_id,
       d.name                             AS discipline,
       dep.short_name                     AS department,
       COUNT(DISTINCT c.id)               AS courses,
       COUNT(g.id)                        AS attempts,
       COUNT(g.id) FILTER (WHERE g.status = 'passed') AS passed,
       COUNT(g.id) FILTER (WHERE g.status = 'failed') AS failed,
       ROUND(AVG(g.grade_value)::numeric, 2) AS avg_grade
FROM disciplines d
JOIN departments dep ON dep.id = d.department_id
LEFT JOIN courses c  ON c.discipline_id = d.id
LEFT JOIN grades g   ON g.course_id = c.id
GROUP BY d.id, d.name, dep.short_name;

-- Уникальный индекс обязателен для REFRESH MATERIALIZED VIEW CONCURRENTLY:
-- по нему PostgreSQL сопоставляет старые и новые строки и обновляет только
-- изменившиеся, не блокируя читателей на время пересчёта.
CREATE UNIQUE INDEX uq_mv_discipline_stats_discipline
    ON mv_discipline_stats (discipline_id);

-- Сводка в готовом виде.
SELECT discipline_id, discipline, department, courses, attempts, passed, failed, avg_grade
FROM mv_discipline_stats
ORDER BY department, discipline_id;

-- ---------------------------------------------------------------------------
-- Демонстрация устаревания: MV не меняется при изменении базовых таблиц.
-- ---------------------------------------------------------------------------
-- Исходное значение по дисциплине 16 «Программирование».
SELECT discipline_id, discipline, attempts, avg_grade
FROM mv_discipline_stats
WHERE discipline_id = 16;

BEGIN;

-- Исправляем оценку в попытке 100009 (курс 1, дисциплина 16): было 3, стало 5.
UPDATE grades SET grade_value = 5 WHERE id = 100009;

-- Живой пересчёт по базовым таблицам видит новое значение...
SELECT ROUND(AVG(g.grade_value)::numeric, 2) AS live_avg_grade
FROM grades g
JOIN courses c ON c.id = g.course_id
WHERE c.discipline_id = 16;

-- ...а материализованное представление отдаёт старое, пока его не обновили.
SELECT discipline_id, avg_grade AS stale_avg_grade
FROM mv_discipline_stats
WHERE discipline_id = 16;

ROLLBACK;

-- После отката базовые данные и MV снова согласованы.

-- ---------------------------------------------------------------------------
-- Обновление MV.
-- ---------------------------------------------------------------------------

-- Полный пересчёт: блокирует чтение представления на время выполнения.
REFRESH MATERIALIZED VIEW mv_discipline_stats;

-- Пересчёт без блокировки читателей (нужен уникальный индекс, создан выше).
-- ВНИМАНИЕ: REFRESH ... CONCURRENTLY нельзя выполнять внутри транзакции —
-- поэтому в этом скрипте он идёт отдельным оператором в режиме autocommit.
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_discipline_stats;

-- ---------------------------------------------------------------------------
-- 4. Допустимая задержка и политика обновления.
--
-- Допустимая задержка: до 1 суток. Сводка по дисциплинам — управленческий
-- отчёт, а не оперативный экран: решения по учебному процессу принимаются на
-- горизонте недель, поэтому суточная задержка не искажает картину.
--
-- Политика обновления:
--   * плановый ночной REFRESH MATERIALIZED VIEW CONCURRENTLY (например, из
--     pg_cron или systemd-таймера) — раз в сутки, вне учебной нагрузки;
--   * ручной REFRESH сразу после закрытия ведомости по дисциплине, если отчёт
--     нужен по «свежим» данным;
--   * CONCURRENTLY выбран, чтобы ночной пересчёт не блокировал отчёты и
--     дневную работу с представлением.
--
-- Почему не обновляем в реальном времени (триггеры / после каждого INSERT):
--   * полный пересчёт агрегата по всей grades на каждую попытку сдачи дорог и
--     бьёт по самой горячей таблице;
--   * выигрыш от свежести нулевой — данные и так нужны раз в сутки.
-- ---------------------------------------------------------------------------
