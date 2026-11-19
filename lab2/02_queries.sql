-- 1. Студент, дисциплина и результат каждой попытки сдачи.
SELECT s.last_name, s.first_name, d.name AS discipline,
       g.attempt_number, g.status, g.grade_value
FROM grades g
JOIN students s ON s.id = g.student_id
JOIN courses c ON c.id = g.course_id
JOIN disciplines d ON d.id = c.discipline_id
ORDER BY s.last_name, c.id, g.attempt_number;

-- 2. Курсы, по которым ещё нет ни одной ведомости.
SELECT c.id AS course_id, d.name AS discipline
FROM courses c
JOIN disciplines d ON d.id = c.discipline_id
LEFT JOIN grades g ON g.course_id = c.id
WHERE g.id IS NULL
ORDER BY c.id;

-- 3. Сдавшие программирование с первой попытки на 4 или 5.
SELECT s.last_name, s.first_name, d.name AS discipline, g.grade_value
FROM grades g
JOIN students s ON s.id = g.student_id
JOIN courses c ON c.id = g.course_id
JOIN disciplines d ON d.id = c.discipline_id
WHERE d.name = 'Программирование'
  AND g.attempt_number = 1
  AND g.grade_value >= 4
ORDER BY s.last_name;

-- 4. Количество попыток каждого статуса по учебным группам.
SELECT sg.name AS group_name, g.status, COUNT(*) AS attempts
FROM grades g
JOIN courses c ON c.id = g.course_id
JOIN student_groups sg ON sg.id = c.group_id
GROUP BY sg.id, sg.name, g.status
ORDER BY sg.name, g.status;

-- 5. Дисциплины со средним баллом по попыткам ниже 3.7.
SELECT d.name AS discipline, ROUND(AVG(g.grade_value), 2) AS avg_grade
FROM grades g
JOIN courses c ON c.id = g.course_id
JOIN disciplines d ON d.id = c.discipline_id
GROUP BY d.id, d.name
HAVING AVG(g.grade_value) < 3.7
ORDER BY avg_grade;

-- 6. Количество оценённых попыток, средний и лучший балл по месяцам.
SELECT date_trunc('month', graded_on)::date AS month,
       COUNT(*) AS graded_attempts,
       ROUND(AVG(grade_value), 2) AS avg_grade,
       MAX(grade_value) AS best_grade
FROM grades
WHERE graded_on IS NOT NULL
GROUP BY date_trunc('month', graded_on)
ORDER BY month;
