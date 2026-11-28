SELECT s.last_name,
       s.first_name,
       d.name                                  AS discipline,
       c.id                                    AS course_id,
       g.id                                    AS attempt_id,
       g.attempt_number,
       g.status,
       g.assigned_on,
       LAG(g.assigned_on) OVER w               AS prev_assigned_on,
       g.assigned_on - LAG(g.assigned_on) OVER w AS days_since_prev
FROM grades g
JOIN students s    ON s.id = g.student_id
JOIN courses c     ON c.id = g.course_id
JOIN disciplines d ON d.id = c.discipline_id
WINDOW w AS (
    PARTITION BY g.student_id, c.discipline_id
    ORDER BY g.assigned_on, g.id
)
ORDER BY s.last_name, s.first_name, s.id, d.name, d.id, g.assigned_on, g.id;
