WITH student_avg AS (
    SELECT s.id               AS student_id,
           s.group_id,
           AVG(g.grade_value) AS avg_grade
    FROM students s
    LEFT JOIN grades g
           ON g.student_id = s.id
          AND g.grade_value IS NOT NULL
    GROUP BY s.id, s.group_id
)
SELECT sg.name               AS group_name,
       s.last_name,
       s.first_name,
       ROUND(a.avg_grade, 2) AS avg_grade,
       CASE
           WHEN a.avg_grade IS NULL THEN NULL
           ELSE RANK() OVER (
                   PARTITION BY a.group_id
                   ORDER BY a.avg_grade DESC NULLS LAST
                )
       END                   AS place
FROM student_avg a
JOIN students s        ON s.id = a.student_id
JOIN student_groups sg ON sg.id = a.group_id
ORDER BY sg.name, place NULLS LAST, s.last_name, s.first_name, s.id;
