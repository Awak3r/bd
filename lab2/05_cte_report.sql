-- ============================================================================
-- ЛР2, Часть 4. Комплексный аналитический отчёт с использованием CTE
-- ============================================================================
-- Содержательный вопрос отчёта (для руководителя учебной части):
--     «Как кафедры справляются с приёмом долгов осеннего семестра 2026/27:
--      где копятся пересдачи, какая доля студентов закрывает курс с первой
--      попытки и каков средний балл по кафедре?»
--
-- Схема вычислений:
--   Исходные данные          -> attempt_rows:
--         строки ведомостей осеннего семестра, привязанные к кафедре,
--         дисциплине и преподавателю (grades x courses x disciplines
--         x departments x teachers).
--   Промежуточные показатели -> discipline_stats:
--         по каждой дисциплине считаем попытки, выставленные итоги,
--         сдачи с первой попытки, пересдачи и средний балл.
--   Агрегация                -> department_report:
--         сворачиваем дисциплины до кафедры: суммарные попытки, доля
--         пересдач, средний балл, доля сдачи с первой попытки,
--         место кафедры по доле пересдач (DENSE_RANK).
--   Итоговый отчёт           -> финальный SELECT:
--         все кафедры, включая те, по которым осенью ведомости не
--         открывались (LEFT JOIN от справочника departments): у них
--         нулевые показатели и пояснение — таблица полная и пригодна
--         для доклада без ручных дописок.
-- ============================================================================

WITH attempt_rows AS (
    -- Исходные данные: одна строка = одна попытка сдачи осеннего семестра.
    SELECT dep.id                AS department_id,
           dep.name              AS department_name,
           d.id                  AS discipline_id,
           d.name                AS discipline_name,
           g.attempt_number,
           g.status,
           g.grade_value
    FROM grades g
    JOIN courses c
      ON c.id = g.course_id
    JOIN disciplines d
      ON d.id = c.discipline_id
    JOIN departments dep
      ON dep.id = d.department_id
    WHERE c.academic_year = 2026   -- осенний семестр 2026/27
      AND c.semester = 5
),
discipline_stats AS (
    -- Промежуточные показатели: агрегаты уровня «дисциплина».
    SELECT department_id,
           department_name,
           discipline_id,
           discipline_name,
           COUNT(*)                                                          AS attempts,
           COUNT(grade_value)                                                AS graded,
           COUNT(*) FILTER (WHERE status = 'passed' AND attempt_number = 1)  AS first_try_passed,
           COUNT(*) FILTER (WHERE attempt_number > 1)                        AS retakes,
           ROUND(AVG(grade_value) FILTER (WHERE grade_value IS NOT NULL), 2) AS avg_grade
    FROM attempt_rows
    GROUP BY department_id, department_name, discipline_id, discipline_name
),
department_report AS (
    -- Агрегация: дисциплины сворачиваются до кафедры + ранжирование.
    SELECT department_id,
           department_name,
           SUM(attempts)                                                        AS attempts,
           SUM(graded)                                                          AS graded,
           SUM(first_try_passed)                                                AS first_try_passed,
           SUM(retakes)                                                         AS retakes,
           ROUND(100.0 * SUM(retakes) / NULLIF(SUM(attempts), 0), 1)            AS retake_pct,
           ROUND(100.0 * SUM(first_try_passed) / NULLIF(SUM(graded), 0), 1)     AS first_try_pct,
           ROUND(AVG(avg_grade), 2)                                             AS avg_discipline_grade,
           DENSE_RANK() OVER (ORDER BY
               100.0 * SUM(retakes) / NULLIF(SUM(attempts), 0) DESC)            AS retake_rank
    FROM discipline_stats
    GROUP BY department_id, department_name
)
-- Итоговый отчёт: все кафедры, включая те, где ведомости осенью не открывались.
SELECT dep.short_name                                        AS department,
       dep.name                                              AS department_name,
       COALESCE(rep.attempts, 0)                             AS attempts,
       COALESCE(rep.graded, 0)                               AS graded,
       COALESCE(rep.first_try_passed, 0)                     AS first_try_passed,
       COALESCE(rep.retakes, 0)                              AS retakes,
       COALESCE(rep.retake_pct, 0.0)                         AS retake_pct,
       COALESCE(rep.first_try_pct, 0.0)                      AS first_try_pct,
       rep.avg_discipline_grade,
       rep.retake_rank,
       CASE
           WHEN rep.department_id IS NULL
               THEN 'осенние ведомости не открывались'
           ELSE 'данные за семестр 2026/27'
       END                                                   AS data_note
FROM departments dep
LEFT JOIN department_report rep
  ON rep.department_id = dep.id
ORDER BY rep.retake_rank NULLS LAST, dep.short_name;
