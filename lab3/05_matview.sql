DROP MATERIALIZED VIEW IF EXISTS mv_discipline_stats;

CREATE MATERIALIZED VIEW mv_discipline_stats AS
SELECT d.id AS discipline_id,
       d.name AS discipline,
       COUNT(g.grade_value) AS graded_attempts,
       ROUND(AVG(g.grade_value), 2) AS avg_grade
FROM disciplines d
LEFT JOIN courses c ON c.discipline_id = d.id
LEFT JOIN grades g ON g.course_id = c.id
GROUP BY d.id, d.name;

SELECT discipline, graded_attempts, avg_grade
FROM mv_discipline_stats
ORDER BY discipline_id;
