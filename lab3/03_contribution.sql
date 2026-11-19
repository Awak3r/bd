-- ЛР3, задание 1.3. Анализ вклада отдельных операций в общий показатель.
--
-- Задача: вклад каждой оценённой попытки в суммарный «балльный фонд» студента.
--
-- Каждая попытка остаётся отдельной строкой (детализация не теряется),
-- а рядом выводятся обобщённый показатель и доля в процентах.
-- Строки с NULL-баллом исключены: они не входят в сумму и дали бы пустой
-- знаменатель при подсчёте доли.

SELECT s.last_name,
       s.first_name,
       d.name                              AS discipline,
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
ORDER BY s.last_name, s.first_name, d.name, g.attempt_number;
