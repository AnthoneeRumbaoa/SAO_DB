-- Empty

--Adding a Student
DELIMITER $$

CREATE PROCEDURE AddStudent (
    IN ID_Number VARCHAR(8),
    IN lastName VARCHAR(30),
    IN firstName VARCHAR(30),
    IN Section VARCHAR(45),
    IN Year INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM STUDENT WHERE STUDENT.ID_Number = ID_Number
    ) THEN
        INSERT INTO STUDENT (
            ID_Number,
            lastName,
            firstName,
            Section,
            Year,
            Created_At,
            Updated_At,
            Created_By,
            Updated_By
        )
        VALUES (
            ID_Number,
            lastName,
            firstName,
            Section,
            Year,
            NOW(),
            NOW(),
            'registrar',
            'registrar'
        );
    END IF;
END $$

DELIMITER ;

--Enrolling a student into a subject
DELIMITER $$

CREATE PROCEDURE StudentEnroll (
    IN STUDENT_ID VARCHAR(8),
    IN SEMESTER_ID INT,
    IN COURSE_ID INT,
    IN PROGRAM_ID INT,
    IN YEAR_ID INT
)
BEGIN
    INSERT INTO ENROLLMENT (
        Units,
        Grade,
        Status,
        Created_At,
        Updated_At,
        Created_By,
        Updated_By,
        STUDENT_ID,
        CURRICULUM_SEMESTER_ID,
        CURRICULUM_COURSE_ID,
        CURRICULUM_PROGRAM_ID,
        CURRICULUM_YEAR_ID
    )
    VALUES (
        3,
        'INC',
        'Active',
        NOW(),
        NOW(),
        'registrar',
        'registrar',
        STUDENT_ID,
        SEMESTER_ID,
        COURSE_ID,
        PROGRAM_ID,
        YEAR_ID
    );
END $$

DELIMITER ;

--Updates Student grade status
DELIMITER $$

CREATE PROCEDURE GradeUpdate (
    IN ENROLLMENT_ID INT,
    IN Grade VARCHAR(9),
    IN Status VARCHAR(10)
)
BEGIN
    UPDATE ENROLLMENT
    SET
        Grade = Grade,
        Status = Status,
        Updated_At = NOW(),
        Updated_By = 'registrar'
    WHERE ID = ENROLLMENT_ID;
END $$

DELIMITER ;

--Viewing Student academic records
DELIMITER $$

CREATE PROCEDURE StudentEnrollmentsViewer (
    IN STUDENT_ID VARCHAR(8)
)
BEGIN
    SELECT
        STUDENT.ID_Number,
        STUDENT.firstName,
        STUDENT.lastName,
        COURSE.Code,
        COURSE.Name AS Course,
        ENROLLMENT.Grade,
        ENROLLMENT.Status,
        ENROLLMENT.Units
    FROM ENROLLMENT
    JOIN STUDENT
        ON ENROLLMENT.STUDENT_ID = STUDENT.ID_Number
    JOIN COURSE
        ON ENROLLMENT.CURRICULUM_COURSE_ID = COURSE.ID
    WHERE STUDENT.ID_Number = STUDENT_ID;
END $$

DELIMITER ;

