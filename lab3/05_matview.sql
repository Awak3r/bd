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

CREATE UNIQUE INDEX uq_mv_discipline_stats_discipline
    ON mv_discipline_stats (discipline_id);

SELECT discipline_id, discipline, department, courses, attempts, passed, failed, avg_grade
FROM mv_discipline_stats
ORDER BY department, discipline_id;

SELECT discipline_id, discipline, attempts, avg_grade
FROM mv_discipline_stats
WHERE discipline_id = 16;

BEGIN;

UPDATE grades SET grade_value = 5 WHERE id = 100009;

SELECT ROUND(AVG(g.grade_value)::numeric, 2) AS live_avg_grade
FROM grades g
JOIN courses c ON c.id = g.course_id
WHERE c.discipline_id = 16;

SELECT discipline_id, avg_grade AS stale_avg_grade
FROM mv_discipline_stats
WHERE discipline_id = 16;

REFRESH MATERIALIZED VIEW CONCURRENTLY mv_discipline_stats;

SELECT discipline_id, avg_grade AS refreshed_avg_grade
FROM mv_discipline_stats
WHERE discipline_id = 16;

ROLLBACK;

SELECT discipline_id, avg_grade AS restored_avg_grade
FROM mv_discipline_stats
WHERE discipline_id = 16;
