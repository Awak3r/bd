-- ============================================================
-- Проверка ограничений целостности.
-- Каждая операция должна быть ОТКЛОНЕНА PostgreSQL с ошибкой.
-- Тесты выполняются по одному; после каждой ошибки транзакция
-- откатывается (см. комментарий к ON DELETE тестам в конце).
-- ============================================================

-- ============================================================
-- 1. UNIQUE: дублирование имени кафедры
-- Ошибка: duplicate key value violates unique constraint "uq_departments_name"
-- ============================================================
INSERT INTO departments (id, name, short_name)
VALUES (999001, 'Кафедра 802 «Мехатроника и теоретическая механика»', 'К802');

-- ============================================================
-- 2. UNIQUE: дублирование short_name кафедры
-- Ошибка: duplicate key value violates unique constraint "uq_departments_short_name"
-- ============================================================
INSERT INTO departments (id, name, short_name)
VALUES (999002, 'Тестовая кафедра', '802');

-- ============================================================
-- 3. NOT NULL: email преподавателя обязателен
-- Ошибка: null value in column "email" violates not-null constraint
-- ============================================================
INSERT INTO teachers
    (id, department_id, first_name, last_name, middle_name, email)
VALUES
    (999003, 1, 'Иван', 'Тестов', NULL, NULL);

-- ============================================================
-- 4. CHECK: credits должен быть больше 0
-- Ошибка: new row for relation "disciplines" violates check constraint "chk_disciplines_credits_positive"
-- ============================================================
INSERT INTO disciplines
    (id, department_id, name, credits)
VALUES
    (999004, 1, 'Тестовая дисциплина', 0);

-- ============================================================
-- 5. CHECK: номер курса должен быть от 1 до 6
-- Ошибка: new row for relation "student_groups" violates check constraint "chk_groups_course_number"
-- ============================================================
INSERT INTO student_groups
    (id, name, admission_year, course_number)
VALUES
    (999005, 'TEST-999', 2026, 7);

-- ============================================================
-- 6. CHECK: admission_year должен быть от 2000 до 2100
-- Ошибка: new row for relation "student_groups" violates check constraint "chk_groups_admission_year"
-- ============================================================
INSERT INTO student_groups
    (id, name, admission_year, course_number)
VALUES
    (999013, 'TEST-998', 5, 1);

-- ============================================================
-- 7. CHECK: semester должен быть от 1 до 12
-- Ошибка: new row for relation "courses" violates check constraint "chk_courses_semester"
-- ============================================================
INSERT INTO courses
    (id, discipline_id, group_id, teacher_id, semester, academic_year)
VALUES
    (999006, 1, 1, 1, 13, 2026);

-- ============================================================
-- 8. CHECK: academic_year должен быть больше 2000
-- Ошибка: new row for relation "courses" violates check constraint "chk_courses_academic_year"
-- ============================================================
INSERT INTO courses
    (id, discipline_id, group_id, teacher_id, semester, academic_year)
VALUES
    (999007, 1, 1, 1, 1, 2000);

-- ============================================================
-- 9. Составное ограничение: повтор курса (дисциплина + группа + семестр
--    + учебный год уже существуют в data.sql)
-- Ошибка: duplicate key value violates unique constraint "uq_courses_discipline_group_semester_year"
-- ============================================================
INSERT INTO courses
    (id, discipline_id, group_id, teacher_id, semester, academic_year)
VALUES
    (999010, 16, 1, 18, 5, 2026);

-- ============================================================
-- 10. FOREIGN KEY: несуществующая кафедра
-- Ошибка: insert or update on table "teachers" violates foreign key constraint "fk_teachers_department"
-- ============================================================
INSERT INTO teachers
    (id, department_id, first_name, last_name, middle_name, email)
VALUES
    (999008, 999999, 'Иван', 'Тестов', NULL, 'test008@example.com');

-- ============================================================
-- 11. FOREIGN KEY: несуществующая группа
-- Ошибка: insert or update on table "students" violates foreign key constraint "fk_students_group"
-- ============================================================
INSERT INTO students
    (id, group_id, first_name, last_name, middle_name, email, birth_date)
VALUES
    (999009, 999999, 'Иван', 'Тестов', NULL, 'test009@example.com', '2000-01-01');

-- ============================================================
-- 12. UNIQUE при UPDATE: email преподавателя занят другим преподавателем
-- Ошибка: duplicate key value violates unique constraint "uq_teachers_email"
-- ============================================================
UPDATE teachers
SET email = 'teacher01@test.mai.ru'
WHERE id = 2;

-- ============================================================
-- 13. ON DELETE RESTRICT: нельзя удалить кафедру, пока на ней
--     работают преподаватели
-- Ошибка: update or delete on table "departments" violates foreign key constraint "fk_teachers_department" on table "teachers"
-- ============================================================
DELETE FROM departments WHERE id = 1;

-- ============================================================
-- 14. ON DELETE CASCADE: удаление группы каскадно удаляет её студентов
--     (тест в транзакции, в конце откат — данные восстанавливаются)
--     Перед DELETE: 5 студентов в группе 1.
--     Ошибка не возникает: после DELETE SELECT должен вернуть 0.
--     Роллбек возвращает базу в исходное состояние.
-- ============================================================
BEGIN;

DELETE FROM student_groups WHERE id = 1;

SELECT count(*) AS students_in_deleted_group
FROM students WHERE group_id = 1;  -- ожидается 0 (каскадное удаление)

ROLLBACK;
