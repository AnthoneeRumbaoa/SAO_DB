-- Adding a Student
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
            Created_By,
            Updated_By,
            YEAR_ID
        )
        VALUES (
            ID_Number,
            lastName,
            firstName,
            Section,
            'registrar',
            'registrar',
            Year
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
        Grade,
        Status,
        Created_By,
        Updated_By,
        STUDENT_ID,
        CURRICULUM_SEMESTER_ID,
        CURRICULUM_COURSE_ID,
        CURRICULUM_PROGRAM_ID,
        CURRICULUM_YEAR_ID
    )
    VALUES (
        '(Ongoing)',
        'Active',
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
    IN p_ENROLLMENT_ID INT,
    IN p_RawGrade INT -- Input scale 1-100
)
BEGIN
    DECLARE v_ConvertedGrade DECIMAL(3,2);

    -- Convert 100-point scale to 4-point scale (Decimal)
    SET v_ConvertedGrade = CASE 
        WHEN p_RawGrade BETWEEN 95 AND 100 THEN 4.00
        WHEN p_RawGrade BETWEEN 91 AND 94  THEN 3.50
        WHEN p_RawGrade BETWEEN 87 AND 90  THEN 3.00
        WHEN p_RawGrade BETWEEN 83 AND 86  THEN 2.50
        WHEN p_RawGrade BETWEEN 79 AND 82  THEN 2.00
        WHEN p_RawGrade BETWEEN 75 AND 78  THEN 1.50
        WHEN p_RawGrade BETWEEN 70 AND 74  THEN 1.00
        ELSE 0.00 -- Trigger will see 0.00 and set Status to 'Failed'
    END;

    -- Update the Enrollment record
    -- The Trigger 'AutoUpdateStatus' will automatically set the Status column
    UPDATE ENROLLMENT
    SET
        Grade = CAST(v_ConvertedGrade AS CHAR),
        Updated_At = NOW(),
        Updated_By = 'registrar'
    WHERE ID = p_ENROLLMENT_ID;
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
        ENROLLMENT.Status
    FROM ENROLLMENT
    JOIN STUDENT
        ON ENROLLMENT.STUDENT_ID = STUDENT.ID_Number
    JOIN COURSE
        ON ENROLLMENT.CURRICULUM_COURSE_ID = COURSE.ID
    WHERE STUDENT.ID_Number = STUDENT_ID;
END $$

DELIMITER ;

--USAGE EXAMPLE
-- 1. Add a new student
CALL AddStudent('2024-038', 'Reyes', 'Daniel', 'A', 3);

-- 2. Enroll the student in a course
CALL StudentEnroll('2024-038', 1, 5, 1, 3);

-- 3. Update the student’s grade
CALL GradeUpdate(101, 92);

-- 4. View student records
CALL StudentEnrollmentsViewer('2024-038');

