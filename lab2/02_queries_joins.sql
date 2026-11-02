-- ============================================================================
-- ЛР2, Часть 2.1. Многотабличные запросы (JOIN)
-- ============================================================================
-- Три запроса, каждый объединяет данные не менее чем из трёх таблиц
-- и решает свою задачу:
--   Q1 — подробная информация об операциях и связанных сущностях;
--   Q2 — выявление объектов без связанных записей (LEFT JOIN);
--   Q3 — перечень объектов, удовлетворяющих нескольким взаимосвязанным условиям.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. Полная карточка каждой попытки сдачи.
--     Для каждой ведомости: студент, группа, дисциплина, преподаватель,
--     кафедра, номер попытки, статус, оценка и даты.
--     Задача ТЗ: «получение подробной информации об операциях и связанных
--     сущностях». Задействовано 7 таблиц.
-- ----------------------------------------------------------------------------

SELECT g.id                                   AS grade_id,
       s.last_name || ' ' || s.first_name     AS student,
       sg.name                                AS group_name,
       d.name                                 AS discipline,
       t.last_name || ' ' || t.first_name     AS teacher,
       dep.short_name                         AS department,
       g.attempt_number,
       g.status,
       g.grade_value,
       g.assigned_on,
       g.graded_on
FROM grades g
JOIN students s
  ON s.id = g.student_id
JOIN student_groups sg
  ON sg.id = s.group_id
JOIN courses c
  ON c.id = g.course_id
JOIN disciplines d
  ON d.id = c.discipline_id
JOIN teachers t
  ON t.id = c.teacher_id
JOIN departments dep
  ON dep.id = d.department_id
ORDER BY sg.name, s.last_name, g.assigned_on, g.attempt_number;

-- ----------------------------------------------------------------------------
-- Q2. Студенты, по которым не открыто ни одной ведомости.
--     Задача ТЗ: «выявление объектов, у которых отсутствуют связанные
--     записи». LEFT JOIN + проверка на NULL корректно обрабатывает
--     отсутствие связанных данных. Сюда попадают и студенты групп, у
--     которых курсы ещё не назначены, и студенты с назначенными курсами,
--     но без открытых ведомостей.
-- ----------------------------------------------------------------------------

SELECT s.id,
       s.last_name,
       s.first_name,
       sg.name AS group_name
FROM students s
JOIN student_groups sg
  ON sg.id = s.group_id
LEFT JOIN grades g
  ON g.student_id = s.id
WHERE g.id IS NULL
ORDER BY sg.name, s.last_name;

-- ----------------------------------------------------------------------------
-- Q3. Кто сдал «Программирование» (кафедра 806) в осеннем семестре 2026/27
--     с первой попытки на 4 или 5.
--     Задача ТЗ: «перечень объектов, удовлетворяющих нескольким
--     взаимосвязанным условиям» (дисциплина + семестр/год + попытка + балл).
-- ----------------------------------------------------------------------------

SELECT sg.name                AS group_name,
       s.last_name,
       s.first_name,
       g.grade_value,
       g.graded_on
FROM grades g
JOIN students s
  ON s.id = g.student_id
JOIN student_groups sg
  ON sg.id = s.group_id
JOIN courses c
  ON c.id = g.course_id
JOIN disciplines d
  ON d.id = c.discipline_id
JOIN departments dep
  ON dep.id = d.department_id
WHERE d.id = 16                    -- «Программирование», кафедра 806
  AND c.semester = 5               -- осенний семестр
  AND c.academic_year = 2026
  AND g.attempt_number = 1         -- с первой попытки
  AND g.grade_value >= 4           -- на 4 или 5
ORDER BY sg.name, s.last_name;
