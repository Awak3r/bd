CREATE TABLE "departments" (
  "id" bigint PRIMARY KEY,
  "name" varchar(150) CONSTRAINT "uq_departments_name" UNIQUE NOT NULL,
  "short_name" varchar(30) CONSTRAINT "uq_departments_short_name" UNIQUE NOT NULL
);

CREATE TABLE "teachers" (
  "id" bigint PRIMARY KEY,
  "department_id" bigint NOT NULL,
  "first_name" varchar(50) NOT NULL,
  "last_name" varchar(50) NOT NULL,
  "middle_name" varchar(50),
  "email" varchar(150) CONSTRAINT "uq_teachers_email" UNIQUE NOT NULL
);

CREATE TABLE "disciplines" (
  "id" bigint PRIMARY KEY,
  "department_id" bigint NOT NULL,
  "name" varchar(150) NOT NULL,
  "credits" smallint NOT NULL CONSTRAINT "chk_disciplines_credits_positive" CHECK ("credits" > 0)
);

CREATE TABLE "student_groups" (
  "id" bigint PRIMARY KEY,
  "name" varchar(30) CONSTRAINT "uq_groups_name" UNIQUE NOT NULL,
  "admission_year" smallint NOT NULL CONSTRAINT "chk_groups_admission_year" CHECK ("admission_year" BETWEEN 2000 AND 2100),
  "course_number" smallint NOT NULL CONSTRAINT "chk_groups_course_number" CHECK ("course_number" BETWEEN 1 AND 6)
);

CREATE TABLE "students" (
  "id" bigint PRIMARY KEY,
  "group_id" bigint NOT NULL,
  "first_name" varchar(50) NOT NULL,
  "last_name" varchar(50) NOT NULL,
  "middle_name" varchar(50),
  "email" varchar(150) CONSTRAINT "uq_students_email" UNIQUE NOT NULL,
  "birth_date" date NOT NULL
);

CREATE TABLE "courses" (
  "id" bigint PRIMARY KEY,
  "discipline_id" bigint NOT NULL,
  "group_id" bigint NOT NULL,
  "teacher_id" bigint NOT NULL,
  "semester" smallint NOT NULL CONSTRAINT "chk_courses_semester" CHECK ("semester" BETWEEN 1 AND 12),
  "academic_year" smallint NOT NULL CONSTRAINT "chk_courses_academic_year" CHECK ("academic_year" > 2000),
  CONSTRAINT "uq_courses_discipline_group_semester_year"
    UNIQUE ("discipline_id", "group_id", "semester", "academic_year")
);


ALTER TABLE "teachers"
  ADD CONSTRAINT "fk_teachers_department"
  FOREIGN KEY ("department_id") REFERENCES "departments" ("id")
  ON DELETE RESTRICT;

ALTER TABLE "disciplines"
  ADD CONSTRAINT "fk_disciplines_department"
  FOREIGN KEY ("department_id") REFERENCES "departments" ("id")
  ON DELETE RESTRICT;

ALTER TABLE "students"
  ADD CONSTRAINT "fk_students_group"
  FOREIGN KEY ("group_id") REFERENCES "student_groups" ("id")
  ON DELETE CASCADE;

ALTER TABLE "courses"
  ADD CONSTRAINT "fk_courses_discipline"
  FOREIGN KEY ("discipline_id") REFERENCES "disciplines" ("id")
  ON DELETE RESTRICT;

ALTER TABLE "courses"
  ADD CONSTRAINT "fk_courses_group"
  FOREIGN KEY ("group_id") REFERENCES "student_groups" ("id")
  ON DELETE CASCADE;

ALTER TABLE "courses"
  ADD CONSTRAINT "fk_courses_teacher"
  FOREIGN KEY ("teacher_id") REFERENCES "teachers" ("id")
  ON DELETE RESTRICT;
