-- ============================================================================
-- ЛР2, Часть 3. Подзапросы и поиск нетривиальных ситуаций (4 запроса)
-- ============================================================================
--   S1 — сравнение с вычисляемым показателем (среднее по группе);
--   S2 — проверка существования связанных данных (EXISTS);
--   S3 — поиск отсутствующих событий (NOT EXISTS);
--   S4 — коррелированный подзапрос.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- S1. Студенты, чей средний балл выше среднего балла их группы.
--     Группа сравнения определяется предметной областью: студенты одной
--     учебной группы сдают один и тот же набор курсов, поэтому среднее
--     по группе — естественная точка отсчёта. Подзапрос в HAVING
--     коррелирует с внешним запросом по s.group_id.
-- ----------------------------------------------------------------------------

SELECT sg.name                                      AS group_name,
       s.last_name,
       s.first_name,
       COUNT(g.id)                                  AS graded_attempts,
       ROUND(AVG(g.grade_value)::numeric, 2)        AS student_avg,
       ROUND((SELECT AVG(g2.grade_value)
              FROM grades g2
              JOIN students s2 ON s2.id = g2.student_id
              WHERE s2.group_id = s.group_id
                AND g2.grade_value IS NOT NULL)::numeric, 2) AS group_avg
FROM grades g
JOIN students s
  ON s.id = g.student_id
JOIN student_groups sg
  ON sg.id = s.group_id
WHERE g.grade_value IS NOT NULL
GROUP BY s.id, s.last_name, s.first_name, sg.name, s.group_id
HAVING AVG(g.grade_value) > (SELECT AVG(g2.grade_value)
                             FROM grades g2
                             JOIN students s2 ON s2.id = g2.student_id
                             WHERE s2.group_id = s.group_id
                               AND g2.grade_value IS NOT NULL)
ORDER BY sg.name, student_avg DESC;

-- ----------------------------------------------------------------------------
-- S2. Студенты, пересдававшие курс и в итоге сдавшие его.
--     EXISTS: существует хотя бы одна предыдущая попытка (attempt_number
--     меньше текущей) со статусом failed — дополнительное условие,
--     отсекающее повторные попытки, аннулированные без «двойки».
-- ----------------------------------------------------------------------------

SELECT sg.name                        AS group_name,
       s.last_name,
       s.first_name,
       d.name                         AS discipline,
       g.attempt_number               AS retake_no,
       g.grade_value                  AS retake_grade
FROM grades g
JOIN students s
  ON s.id = g.student_id
JOIN student_groups sg
  ON sg.id = s.group_id
JOIN courses c
  ON c.id = g.course_id
JOIN disciplines d
  ON d.id = c.discipline_id
WHERE g.status = 'passed'
  AND g.attempt_number >= 2
  AND EXISTS (SELECT 1
              FROM grades prev
              WHERE prev.course_id = g.course_id
                AND prev.student_id = g.student_id
                AND prev.attempt_number < g.attempt_number
                AND prev.status = 'failed')
ORDER BY sg.name, s.last_name, discipline;

-- ----------------------------------------------------------------------------
-- S3. Пары «студент — курс» осеннего семестра 2026/27, по которым
--     ведомость ещё не открыта.
--     NOT EXISTS: отсутствие события имеет содержательный смысл —
--     по этим курсам преподаватель ещё не открыл ведомость, и именно
--     эти сдачи ожидаются до конца семестра.
-- ----------------------------------------------------------------------------

SELECT sg.name        AS group_name,
       s.last_name,
       s.first_name,
       d.name         AS discipline,
       c.id           AS course_id
FROM courses c
JOIN disciplines d
  ON d.id = c.discipline_id
JOIN student_groups sg
  ON sg.id = c.group_id
JOIN students s
  ON s.group_id = c.group_id
WHERE c.semester = 5
  AND c.academic_year = 2026
  AND NOT EXISTS (SELECT 1
                  FROM grades g
                  WHERE g.course_id = c.id
                    AND g.student_id = s.id)
ORDER BY sg.name, d.name, s.last_name;

-- ----------------------------------------------------------------------------
-- S4. Коррелированный подзапрос: попытки студента, где балл выше его
--     собственного среднего по всем попыткам. Условие внутреннего запроса
--     зависит от текущей строки внешнего (g.student_id) и вычисляет
--     индивидуальный показатель для каждой сущности.
-- ----------------------------------------------------------------------------

SELECT s.last_name,
       s.first_name,
       d.name                                        AS discipline,
       g.grade_value,
       g.attempt_number,
       ROUND((SELECT AVG(g2.grade_value)
              FROM grades g2
              WHERE g2.student_id = g.student_id
                AND g2.grade_value IS NOT NULL)::numeric, 2) AS personal_avg
FROM grades g
JOIN students s
  ON s.id = g.student_id
JOIN courses c
  ON c.id = g.course_id
JOIN disciplines d
  ON d.id = c.discipline_id
WHERE g.grade_value IS NOT NULL
  AND g.grade_value > (SELECT AVG(g2.grade_value)
                       FROM grades g2
                       WHERE g2.student_id = g.student_id
                         AND g2.grade_value IS NOT NULL)
ORDER BY s.last_name, s.first_name, g.grade_value DESC;
