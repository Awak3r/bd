BEGIN;

INSERT INTO disciplines (id, department_id, name, credits)
VALUES (21, 4, 'Компьютерные сети', 4);

INSERT INTO courses (id, discipline_id, group_id, teacher_id, semester, academic_year)
VALUES (31, 21, 1, 18, 5, 2026);

INSERT INTO grades (id, course_id, student_id, attempt_number, status, assigned_on)
VALUES (200001, 31, 1, 1, 'assigned', '2026-11-16'),
       (200002, 31, 2, 1, 'assigned', '2026-11-16'),
       (200003, 31, 3, 1, 'assigned', '2026-11-16');

UPDATE grades
SET status = 'passed', grade_value = 4, graded_on = '2026-11-15'
WHERE id = 100004 AND status = 'assigned';

UPDATE grades
SET status = 'annulled'
WHERE course_id = 10 AND status = 'assigned';

DELETE FROM grades
WHERE id = 100029 AND status = 'annulled';

COMMIT;

BEGIN;

UPDATE grades
SET grade_value = 3
WHERE student_id = 5 AND status = 'passed';

SELECT id, grade_value FROM grades WHERE student_id = 5 ORDER BY id;

ROLLBACK;

SELECT id, grade_value FROM grades WHERE student_id = 5 ORDER BY id;
