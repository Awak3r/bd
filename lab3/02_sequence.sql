-- ЛР3, задание 1.2. Анализ последовательности событий.
--
-- Задача: интервалы между последовательными попытками сдать одну дисциплину.
--
-- Один объект        = пара (студент, дисциплина).
-- Однозначный порядок = assigned_on, затем id как детерминированный
--                       tie-breaker (одинаковая дата выдачи не должна давать
--                       произвольный порядок строк).
-- Первая попытка     = остаётся в выборке; prev_assigned_on и days_since_prev
--                       для неё NULL, а не пропуск строки.

SELECT s.last_name,
       s.first_name,
       d.name                                  AS discipline,
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
ORDER BY s.last_name, s.first_name, d.name, g.assigned_on, g.id;
