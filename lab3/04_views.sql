-- ЛР3, часть 2. Обычные представления (VIEW).
--
-- Скрипт идемпотентен: представления пересоздаются через DROP VIEW IF EXISTS.

-- ---------------------------------------------------------------------------
-- 2.1. Операционное представление: единая ведомость.
--      Объединяет grades, students, student_groups, courses, disciplines,
--      teachers — одна строка = одна попытка сдачи с полным контекстом.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_gradebook;

CREATE VIEW v_gradebook AS
SELECT g.id                             AS grade_id,
       s.last_name || ' ' || s.first_name AS student,
       sg.name                          AS group_name,
       d.name                           AS discipline,
       t.last_name                      AS teacher,
       c.semester,
       c.academic_year,
       g.attempt_number,
       g.status,
       g.grade_value,
       g.assigned_on,
       g.graded_on
FROM grades g
JOIN students s        ON s.id = g.student_id
JOIN student_groups sg ON sg.id = s.group_id
JOIN courses c         ON c.id = g.course_id
JOIN disciplines d     ON d.id = c.discipline_id
JOIN teachers t        ON t.id = c.teacher_id;

-- Демонстрация: изменение исходных данных сразу видно через представление.
BEGIN;

SELECT grade_id, discipline, grade_value, status
FROM v_gradebook
WHERE grade_id = 100001;

UPDATE grades SET grade_value = 3 WHERE id = 100001;

SELECT grade_id, discipline, grade_value, status
FROM v_gradebook
WHERE grade_id = 100001;

ROLLBACK;

-- После отката представление снова отдаёт исходное значение.
SELECT grade_id, discipline, grade_value, status
FROM v_gradebook
WHERE grade_id = 100001;


-- ---------------------------------------------------------------------------
-- 2.2. Аналитическое представление на основе задания 1.1
--      (средний балл по студенту) и его использование в другом запросе
--      с дополнительной фильтрацией и вычислением отклонения от группы.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_student_avg_grade;

CREATE VIEW v_student_avg_grade AS
SELECT s.id                AS student_id,
       s.last_name,
       s.first_name,
       sg.id               AS group_id,
       sg.name             AS group_name,
       COUNT(g.id)         AS graded_attempts,
       AVG(g.grade_value)  AS avg_grade
FROM students s
JOIN student_groups sg ON sg.id = s.group_id
LEFT JOIN grades g
       ON g.student_id = s.id
      AND g.grade_value IS NOT NULL
GROUP BY s.id, s.last_name, s.first_name, sg.id, sg.name;

-- Среднее по группе — среднее личных баллов всех студентов с оценками.
-- Считаем его до фильтрации, чтобы условия отчёта не меняли базу сравнения.
WITH group_comparison AS (
    SELECT v.*,
           AVG(v.avg_grade) OVER (PARTITION BY v.group_id) AS group_avg
    FROM v_student_avg_grade v
)
SELECT group_name,
       last_name,
       first_name,
       graded_attempts,
       ROUND(gc.avg_grade, 2)             AS avg_grade,
       ROUND(group_avg, 2)                AS group_avg,
       ROUND(gc.avg_grade - group_avg, 2) AS diff_from_group_avg
FROM group_comparison gc
WHERE graded_attempts >= 2
  AND gc.avg_grade < 3.5
ORDER BY group_name, gc.avg_grade, student_id;


-- ---------------------------------------------------------------------------
-- 2.3. Изменение данных через представление с WITH CHECK OPTION.
--      Представление — рабочий интерфейс курсов учебного года 2026:
--      перевести курс в другой год через него нельзя.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS v_current_courses;

CREATE VIEW v_current_courses AS
SELECT id, discipline_id, group_id, teacher_id, semester, academic_year
FROM courses
WHERE academic_year = 2026
WITH CHECK OPTION;

-- Успешное изменение: строка остаётся в условии отбора.
BEGIN;

UPDATE v_current_courses SET semester = 6 WHERE id = 1;

SELECT id, semester, academic_year FROM v_current_courses WHERE id = 1;

ROLLBACK;

-- Ловим только ожидаемое нарушение WITH CHECK OPTION. Если UPDATE не
-- отклонён, демонстрация должна завершиться ошибкой даже при отсутствии строки.
DO $$
BEGIN
    UPDATE v_current_courses SET academic_year = 2025 WHERE id = 1;
    RAISE EXCEPTION 'Ожидался отказ WITH CHECK OPTION при переносе курса 1 в 2025 год';
EXCEPTION
    WHEN with_check_option_violation THEN
        RAISE NOTICE 'Ожидаемый отказ (SQLSTATE %): %', SQLSTATE, SQLERRM;
END;
$$;
