-- Миграция 0001 (up): операционная таблица ведомостей оценок.
--
-- Обоснование расширения модели (требование ТЗ ЛР2, часть «Общая постановка»):
-- модель ЛР1 описывает только статические сущности (кафедры, дисциплины,
-- студенты, курсы) и не содержит операционных событий. Аналитические сценарии
-- ЛР2 (состояния бизнес-процесса, даты, EXISTS/NOT EXISTS, агрегация по
-- периодам) требуют учёта событий сдачи, поэтому добавляется таблица grades.
-- Ранее созданные данные не изменяются и не удаляются.
--
-- Файл совместим с golang-migrate (инструмент сам оборачивает миграцию
-- в транзакцию), а также применим вручную через psql -f.

CREATE TABLE "grades" (
  "id" bigint PRIMARY KEY,
  "course_id" bigint NOT NULL,
  "student_id" bigint NOT NULL,
  -- Номер попытки сдачи курса: 1 — первое прохождение, далее пересдачи.
  -- Пересдачи являются повторяющимися операциями над одной сущностью
  -- (пара студент-курс), что требуется ТЗ (задание 1.1).
  "attempt_number" smallint NOT NULL
    CONSTRAINT "chk_grades_attempt_positive" CHECK ("attempt_number" >= 1),
  -- Состояния бизнес-процесса «сдача дисциплины»:
  --   assigned  — ведомость открыта, сдача ещё не состоялась;
  --   passed    — сдано;
  --   failed    — не сдано;
  --   annulled  — попытка аннулирована (не допущен, отчислен, индивидуальный план).
  "status" varchar(20) NOT NULL
    CONSTRAINT "chk_grades_status_allowed"
    CHECK ("status" IN ('assigned', 'passed', 'failed', 'annulled')),
  -- Оценка по 5-балльной шкале (2 — неудовлетворительно ... 5 — отлично).
  -- NULL допустим: ведомость в статусе assigned/annulled ещё не имеет оценки.
  -- Нижняя граница 2 — пограничное значение по ТЗ (задание 1.1).
  "grade_value" smallint
    CONSTRAINT "chk_grades_grade_value" CHECK ("grade_value" BETWEEN 2 AND 5),
  -- Дата открытия ведомости и дата выставления итога.
  "assigned_on" date NOT NULL,
  "graded_on" date,
  -- Согласованность статуса и данных:
  --   passed/failed   — оценка и дата выставления обязательны;
  --   assigned/annulled — итоговых оценки и даты быть не должно.
  CONSTRAINT "chk_grades_status_consistency" CHECK (
    ("status" IN ('passed', 'failed')
       AND "grade_value" IS NOT NULL
       AND "graded_on" IS NOT NULL
       AND "graded_on" >= "assigned_on")
    OR
    ("status" IN ('assigned', 'annulled')
       AND "grade_value" IS NULL
       AND "graded_on" IS NULL)
  ),
  -- Одна попытка сдачи конкретного курса конкретным студентом существует
  -- не более одного раза.
  CONSTRAINT "uq_grades_attempt" UNIQUE ("course_id", "student_id", "attempt_number")
);

-- Связи с основной моделью.
ALTER TABLE "grades"
  ADD CONSTRAINT "fk_grades_course"
  FOREIGN KEY ("course_id") REFERENCES "courses" ("id")
  ON DELETE RESTRICT;

ALTER TABLE "grades"
  ADD CONSTRAINT "fk_grades_student"
  FOREIGN KEY ("student_id") REFERENCES "students" ("id")
  ON DELETE CASCADE;

-- Индексы под типовые соединения и фильтры аналитических запросов ЛР2
-- (внешние ключи PostgreSQL автоматически не индексирует).
CREATE INDEX "idx_grades_student" ON "grades" ("student_id");
CREATE INDEX "idx_grades_course" ON "grades" ("course_id");
CREATE INDEX "idx_grades_status" ON "grades" ("status");
