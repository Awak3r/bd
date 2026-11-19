-- 1. Дисциплины с числом кредитов выше среднего по своей кафедре.
SELECT d.name, d.credits
FROM disciplines d
WHERE d.credits > (
    SELECT AVG(d2.credits)
    FROM disciplines d2
    WHERE d2.department_id = d.department_id
)
ORDER BY d.name;

-- 2. Студенты, успешно сдавшие курс на пересдаче.
SELECT s.id, s.last_name, s.first_name
FROM students s
WHERE EXISTS (
    SELECT 1
    FROM grades g
    WHERE g.student_id = s.id
      AND g.attempt_number > 1
      AND g.status = 'passed'
)
ORDER BY s.last_name;

-- 3. Студенты, у которых нет ни одной ведомости.
SELECT s.id, s.last_name, s.first_name
FROM students s
WHERE NOT EXISTS (
    SELECT 1
    FROM grades g
    WHERE g.student_id = s.id
)
ORDER BY s.last_name;

-- 4. Количество попыток сдачи каждого студента.
SELECT s.id, s.last_name, s.first_name,
       (SELECT COUNT(*) FROM grades g WHERE g.student_id = s.id) AS attempts
FROM students s
ORDER BY attempts DESC, s.last_name;
