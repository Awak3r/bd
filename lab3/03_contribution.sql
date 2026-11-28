SELECT s.last_name,
       s.first_name,
       d.name                              AS discipline,
       c.id                                AS course_id,
       g.id                                AS attempt_id,
       g.attempt_number,
       g.grade_value,
       SUM(g.grade_value) OVER (
           PARTITION BY g.student_id
       )                                   AS student_total,
       ROUND(
           100.0 * g.grade_value
                 / SUM(g.grade_value) OVER (PARTITION BY g.student_id),
           1
       )                                   AS share_pct
FROM grades g
JOIN students s    ON s.id = g.student_id
JOIN courses c     ON c.id = g.course_id
JOIN disciplines d ON d.id = c.discipline_id
WHERE g.grade_value IS NOT NULL
ORDER BY s.last_name, s.first_name, s.id, d.name, d.id, c.id, g.attempt_number, g.id;
