INSERT INTO departments (id, name, short_name)
VALUES
    (999001, 'Кафедра 802 «Мехатроника и теоретическая механика»', 'К802');

INSERT INTO departments (id, name, short_name)
VALUES (999002, 'Тестовая кафедра', '802');

INSERT INTO teachers
    (id, department_id, first_name, last_name, middle_name, email)
VALUES
    (999003, 1, 'Иван', 'Тестов', NULL, NULL);

INSERT INTO disciplines
    (id, department_id, name, credits)
VALUES
    (999004, 1, 'Тестовая дисциплина', 0);

INSERT INTO student_groups
    (id, name, admission_year, course_number)
VALUES
    (999005, 'TEST-999', 2026, 7);

INSERT INTO student_groups
    (id, name, admission_year, course_number)
VALUES
    (999013, 'TEST-998', 5, 1);

INSERT INTO courses
    (id, discipline_id, group_id, teacher_id, semester, academic_year)
VALUES
    (999006, 1, 1, 1, 13, 2026);

INSERT INTO courses
    (id, discipline_id, group_id, teacher_id, semester, academic_year)
VALUES
    (999007, 1, 1, 1, 1, 2000);

INSERT INTO courses
    (id, discipline_id, group_id, teacher_id, semester, academic_year)
VALUES
    (999010, 16, 1, 18, 5, 2026);

INSERT INTO teachers
    (id, department_id, first_name, last_name, middle_name, email)
VALUES
    (999008, 999999, 'Иван', 'Тестов', NULL, 'test008@example.com');

INSERT INTO students
    (id, group_id, first_name, last_name, middle_name, email, birth_date)
VALUES
    (999009, 999999, 'Иван', 'Тестов', NULL, 'test009@example.com', '2000-01-01');

UPDATE teachers
SET email = 'teacher01@test.mai.ru'
WHERE id = 2;

DELETE FROM departments WHERE id = 1;

BEGIN;

DELETE FROM student_groups WHERE id = 1;

SELECT count(*) AS students_in_deleted_group
FROM students WHERE group_id = 1;

ROLLBACK;
