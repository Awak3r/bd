-- 1. Попытки сдачи за осенний семестр 2026/27 с указанием кафедры.
WITH semester_grades AS (
    SELECT d.department_id, g.status, g.grade_value
    FROM grades g
    JOIN courses c ON c.id = g.course_id
    JOIN disciplines d ON d.id = c.discipline_id
    WHERE c.academic_year = 2026 AND c.semester = 5
),
-- 2. Признак неудачной попытки: 1 — не сдано, 0 — остальные статусы.
attempt_indicators AS (
    SELECT department_id, grade_value,
           CASE WHEN status = 'failed' THEN 1 ELSE 0 END AS failed
    FROM semester_grades
),
-- 3. Количество попыток, неудач и средний балл по кафедрам.
department_stats AS (
    SELECT department_id,
           COUNT(*) AS attempts,
           SUM(failed) AS failed_attempts,
           ROUND(AVG(grade_value), 2) AS avg_grade
    FROM attempt_indicators
    GROUP BY department_id
)
-- 4. Итоговый отчёт по кафедрам с попытками сдачи.
SELECT dep.short_name AS department,
       ds.attempts, ds.failed_attempts, ds.avg_grade
FROM department_stats ds
JOIN departments dep ON dep.id = ds.department_id
ORDER BY ds.failed_attempts DESC, dep.short_name;
