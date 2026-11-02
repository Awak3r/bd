-- ============================================================================
-- ЛР2, Часть 2.2. Агрегация и группировка (3 аналитических запроса)
-- ============================================================================
--   A1 — количественные показатели по группам;
--   A2 — средние показатели с фильтрацией групп через HAVING;
--   A3 — сравнение показателей между временными периодами.
-- Используемые агрегатные функции: COUNT, SUM, AVG, MIN, MAX (5 из 5).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- A1. Ведомости по группам: сколько попыток, сколько студентов участвовало,
--     сколько попыток каждого статуса. Количественные показатели по группам.
-- ----------------------------------------------------------------------------

SELECT sg.name                                                    AS group_name,
       COUNT(*)                                                   AS attempts_total,
       COUNT(DISTINCT g.student_id)                               AS students_involved,
       COUNT(*) FILTER (WHERE g.status = 'passed')                AS passed_cnt,
       COUNT(*) FILTER (WHERE g.status = 'failed')                AS failed_cnt,
       COUNT(*) FILTER (WHERE g.status = 'assigned')              AS open_cnt,
       COUNT(*) FILTER (WHERE g.status = 'annulled')              AS annulled_cnt
FROM grades g
JOIN students s
  ON s.id = g.student_id
JOIN student_groups sg
  ON sg.id = s.group_id
GROUP BY sg.name
ORDER BY sg.name;

-- ----------------------------------------------------------------------------
-- A2. Дисциплины с проблемной успеваемостью: средний балл по всем попыткам
--     ниже 3.7 при не менее чем 5 попытках. Фильтрация групп через HAVING;
--     одновременно расчёт суммарных и средних показателей (AVG, COUNT,
--     MIN, MAX).
-- ----------------------------------------------------------------------------

SELECT d.name                                        AS discipline,
       dep.short_name                                AS department,
       COUNT(*)                                      AS attempts,
       ROUND(AVG(g.grade_value)::numeric, 2)         AS avg_grade,
       MIN(g.grade_value)                            AS min_grade,
       MAX(g.grade_value)                            AS max_grade
FROM grades g
JOIN courses c
  ON c.id = g.course_id
JOIN disciplines d
  ON d.id = c.discipline_id
JOIN departments dep
  ON dep.id = d.department_id
WHERE g.grade_value IS NOT NULL
GROUP BY d.id, d.name, dep.short_name
HAVING COUNT(*) >= 5
   AND AVG(g.grade_value) < 3.7
ORDER BY avg_grade, d.name;

-- ----------------------------------------------------------------------------
-- A3. Динамика успеваемости по месяцам выставления итогов: сравнение
--     показателей между временными периодами. Доля не сданных попыток
--     считается через SUM(CASE ...).
-- ----------------------------------------------------------------------------

SELECT date_trunc('month', g.graded_on)::date                       AS month,
       COUNT(*)                                                     AS graded_total,
       ROUND(AVG(g.grade_value)::numeric, 2)                        AS avg_grade,
       MIN(g.grade_value)                                           AS min_grade,
       MAX(g.grade_value)                                           AS max_grade,
       SUM(CASE WHEN g.grade_value <= 3 THEN 1 ELSE 0 END)          AS weak_cnt,
       ROUND(100.0 * SUM(CASE WHEN g.grade_value <= 3 THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                         AS weak_pct
FROM grades g
WHERE g.graded_on IS NOT NULL
GROUP BY date_trunc('month', g.graded_on)
ORDER BY month;
