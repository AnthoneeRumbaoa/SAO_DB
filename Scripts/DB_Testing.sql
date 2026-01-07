DROP DATABASE IF EXISTS SAO_DB;
CREATE SCHEMA IF NOT EXISTS SAO_DB;
USE SAO_DB;

-- CREATE TABLE BEGIN --
/* TABLE FOR ACADEMIC YEARS */
CREATE TABLE year (
  ID INT NOT NULL,
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (`ID`));

/* TABLE FOR ACADEMIC PROGRAMS */
CREATE TABLE program (
  ID INT NOT NULL AUTO_INCREMENT,
  programName VARCHAR(45) NOT NULL DEFAULT " ",
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (`ID`),
  UNIQUE INDEX `programName_UNIQUE` (`programName` ASC) VISIBLE);

/* TABLE FOR SEMESTERS */
CREATE TABLE semester (
  ID INT NOT NULL,
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (`ID`));

/* TABLE FOR COURSE CATALOG */
CREATE TABLE course (
  ID INT NOT NULL AUTO_INCREMENT,
  Code VARCHAR(7) NOT NULL DEFAULT " ",
  Name VARCHAR(50) NOT NULL DEFAULT " ",
  Credit_Units INT NOT NULL DEFAULT 3,
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (`ID`),
  UNIQUE INDEX `Code_UNIQUE` (`Code` ASC) VISIBLE,
  UNIQUE INDEX `Name_UNIQUE` (`Name` ASC) VISIBLE);

/* TABLE FOR STUDENT MASTERLIST */
CREATE TABLE student (
  ID_Number VARCHAR(8) NOT NULL,
  lastName VARCHAR(30) NOT NULL DEFAULT " ",
  firstName VARCHAR(30) NOT NULL DEFAULT " ",
  fullName varchar(60) GENERATED ALWAYS AS (CONCAT(firstName, ' ', lastName)) STORED,
  Section VARCHAR(45) NOT NULL DEFAULT " ",
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  YEAR_ID INT NOT NULL,
  PRIMARY KEY (`ID_Number`),
  INDEX `lastName_index` (`lastName` ASC) VISIBLE,
  INDEX `fk_STUDENT_YEAR1_idx` (`YEAR_ID` ASC) VISIBLE,
  CONSTRAINT `fk_STUDENT_YEAR1` FOREIGN KEY (`YEAR_ID`) REFERENCES `year` (`ID`));

/* TABLE FOR PROGRAM CURRICULUM DEFINITIONS */
CREATE TABLE curriculum (
  PROGRAM_ID INT NOT NULL,
  YEAR_ID INT NOT NULL,
  SEMESTER_ID INT NOT NULL,
  COURSE_ID INT NOT NULL,
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (PROGRAM_ID, YEAR_ID, SEMESTER_ID, COURSE_ID),
  INDEX `fk_COURSE_SEMESTER_PROGRAM_COURSE1_idx` (`COURSE_ID` ASC) VISIBLE,
  INDEX `fk_COURSE_SEMESTER_PROGRAM_PROGRAM1_idx` (`PROGRAM_ID` ASC) VISIBLE,
  INDEX `fk_CURRICULUM_YEAR1_idx` (`YEAR_ID` ASC) VISIBLE,
  CONSTRAINT `fk_CURR_PROGRAM` FOREIGN KEY (PROGRAM_ID) REFERENCES program (ID),
  CONSTRAINT `fk_CURR_YEAR` FOREIGN KEY (YEAR_ID) REFERENCES year (ID),
  CONSTRAINT `fk_CURR_SEMESTER` FOREIGN KEY (SEMESTER_ID) REFERENCES semester (ID),
  CONSTRAINT `fk_CURR_COURSE` FOREIGN KEY (COURSE_ID) REFERENCES course (ID));

/* TABLE FOR STUDENT ENROLLMENT AND GRADING */
CREATE TABLE enrollment (
  ID INT NOT NULL AUTO_INCREMENT,
  Grade VARCHAR(9) NOT NULL DEFAULT "(Ongoing)",
  Status ENUM('Passed', 'Failed', 'Active') NOT NULL DEFAULT 'Active',
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  STUDENT_ID VARCHAR(8) NOT NULL,
  CURRICULUM_PROGRAM_ID INT NOT NULL,
  CURRICULUM_YEAR_ID INT NOT NULL,
  CURRICULUM_SEMESTER_ID INT NOT NULL,
  CURRICULUM_COURSE_ID INT NOT NULL,
  PRIMARY KEY (ID),
  INDEX `fk_ENROLLMENT_STUDENT1_idx` (`STUDENT_ID` ASC) VISIBLE,
  UNIQUE INDEX `unique_student_course_time` (`STUDENT_ID`, `CURRICULUM_COURSE_ID`, `CURRICULUM_YEAR_ID`, `CURRICULUM_SEMESTER_ID`),
  INDEX `fk_ENROLLMENT_CURRICULUM1_idx` (`CURRICULUM_SEMESTER_ID`, `CURRICULUM_COURSE_ID`, `CURRICULUM_PROGRAM_ID`, `CURRICULUM_YEAR_ID`) VISIBLE,
  CONSTRAINT `fk_enroll_student` FOREIGN KEY (STUDENT_ID) REFERENCES student (ID_Number),
  CONSTRAINT `fk_enroll_curr` FOREIGN KEY (CURRICULUM_PROGRAM_ID, CURRICULUM_YEAR_ID, CURRICULUM_SEMESTER_ID, CURRICULUM_COURSE_ID) 
    REFERENCES curriculum (PROGRAM_ID, YEAR_ID, SEMESTER_ID, COURSE_ID));

/* TABLE FOR COURSE PREREQUISITES */
CREATE TABLE course_prerequisite (
  PREREQUISITE_ID INT NOT NULL,
  COURSE_ID INT NOT NULL,
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (PREREQUISITE_ID, COURSE_ID),
  INDEX `fk_COURSE_PREREQUISITE_COURSE1_idx` (`COURSE_ID` ASC) VISIBLE,
  CONSTRAINT `fk_pre_course` FOREIGN KEY (PREREQUISITE_ID) REFERENCES course (ID),
  CONSTRAINT `fk_parent_course` FOREIGN KEY (COURSE_ID) REFERENCES course (ID));
-- CREATE TABLE END --

-- FUNCTION BEGIN --
/* HELPER FUNCTION FOR GETNUMERICGRADE */
DELIMITER //
 
CREATE FUNCTION GetNumericGrade (p_grade VARCHAR(9))
RETURNS DECIMAL(3,2)
DETERMINISTIC
BEGIN
    -- Map R and F to 0 for GWA calculation
    IF p_grade = 'F' OR p_grade = 'R' OR p_grade IS NULL THEN
        RETURN 0.00;
    -- Return decimal value if numeric
    ELSEIF (p_grade REGEXP '^[0-9]+(\.[0-9]+)?$') THEN
        RETURN CAST(p_grade AS DECIMAL(3,2));
    ELSE
        RETURN 0.00;
    END IF;
END //
 
DELIMITER ;

/* FUNCTION FOR CALCULATING GWA */
DELIMITER //

CREATE FUNCTION calcGWA (
    p_student_id VARCHAR(8)
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total_units INT DEFAULT 0;
    DECLARE v_weighted_sum DECIMAL(12,2) DEFAULT 0.00;

    SELECT 
        SUM(cr.Credit_Units), 
        SUM(GetNumericGrade(enr.Grade) * cr.Credit_Units)
    INTO v_total_units, v_weighted_sum
    FROM ENROLLMENT enr 
    JOIN COURSE cr ON enr.CURRICULUM_COURSE_ID = cr.ID
    WHERE enr.STUDENT_ID = p_student_id
      AND enr.Grade != '(Ongoing)';

    IF v_total_units > 0 THEN
        RETURN v_weighted_sum / v_total_units;
    ELSE
        RETURN 0.00;
    END IF;
END //

DELIMITER ;
-- FUNCTION END --

-- STORED PROCEDURE BEGIN --
/* STORED PROCEDURE FOR ADDING A STUDENT */
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

/*STORED PROCEDURE FOR ADDING A COURSE*/
DELIMITER $$

CREATE PROCEDURE AddCourse (
  IN new_COURSE_NAME VARCHAR(50),
  IN new_COURSE_CODE VARCHAR(7),
  IN new_COURSE_UNITS INT
)
BEGIN
    IF NOT EXISTS (
      SELECT 1 FROM COURSE WHERE COURSE.Name = new_COURSE_NAME OR COURSE.Code = new_COURSE_CODE
  ) THEN
      INSERT INTO COURSE (
          Code,
          Name,
          Credit_Units
      )
      VALUES (
          new_COURSE_CODE,
          new_COURSE_NAME,
          new_COURSE_UNITS
      );
    END IF;
END $$
DELIMITER ;

/*STORED PROCEDURE FOR ADDING A PROGRAM*/
DELIMITER $$

CREATE PROCEDURE AddProgram(
  IN new_PROGRAM_NAME VARCHAR(45)
)
  BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM PROGRAM WHERE PROGRAM.programName = new_PROGRAM_NAME
      ) THEN
          INSERT INTO PROGRAM (programName) VALUES (new_PROGRAM_NAME);
      END IF;
  END $$
DELIMITER ;

/*STORED PROCEDURE FOR ADDING A NEW CURRICULUM ENTRY*/
DELIMITER $$

CREATE PROCEDURE AddCurriculum (
    IN entry_PROGRAM_NAME VARCHAR(45),
    IN entry_YEAR INT,
    IN entry_SEMESTER INT,
    IN entry_COURSE_CODE VARCHAR(7)
)
    BEGIN
        DECLARE entry_PROGRAM_ID INT;
        DECLARE entry_COURSE_ID INT;
    
        SELECT ID INTO entry_PROGRAM_ID FROM PROGRAM p WHERE p.programName = entry_PROGRAM_NAME;
        SELECT ID INTO entry_COURSE_ID FROM COURSE c WHERE c.Code = entry_COURSE_CODE;

      IF NOT EXISTS (
        SELECT 1 FROM CURRICULUM 
        WHERE CURRICULUM.PROGRAM_ID = entry_PROGRAM_ID
        AND CURRICULUM.YEAR_ID = entry_YEAR
        AND CURRICULUM.SEMESTER_ID = entry_SEMESTER
        AND CURRICULUM.COURSE_ID = entry_COURSE_ID
      ) THEN
          INSERT INTO CURRICULUM (
              PROGRAM_ID, 
              YEAR_ID, 
              SEMESTER_ID, 
              COURSE_ID
          )
          VALUES (
              entry_PROGRAM_ID,
              entry_YEAR,
              entry_SEMESTER,
              entry_COURSE_ID
          );
        END IF;
    END $$
DELIMITER ;


/* STORED PROCEDURE FOR ENROLLING A STUDENT */
DELIMITER $$

CREATE PROCEDURE StudentEnroll (
    IN STUDENT_FULLNAME VARCHAR(60),
    IN COURSE_CODE VARCHAR(50),
    IN PROGRAM_NAME VARCHAR(45),
    IN YEAR_ID INT,
    IN SEMESTER_ID INT
)
BEGIN
    DECLARE course_id INT;
    DECLARE program_id INT;
    DECLARE student_id VARCHAR(8);

    SELECT ID INTO course_id FROM COURSE WHERE Code = COURSE_CODE;
    SELECT ID INTO program_id FROM PROGRAM WHERE programName = PROGRAM_NAME;
    SELECT ID_Number INTO student_id FROM STUDENT WHERE fullName = STUDENT_FULLNAME;

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
        student_id,
        SEMESTER_ID,
        course_id,
        program_id,
        YEAR_ID
    );
END $$

DELIMITER ;

/* STORED PROCEDURE FOR UPDATING GRADES */
DELIMITER $$

CREATE PROCEDURE GradeUpdate (
    IN p_Student_Fullname VARCHAR(60),
    IN p_Course_Code VARCHAR(7),
    IN p_Year_ID INT,      
    IN p_Semester_ID INT,  
    IN p_RawGrade VARCHAR(9) -- Changed to VARCHAR(9)
)
BEGIN
    DECLARE v_FinalGrade CHAR(9);
    DECLARE v_NumericGrade INT;
    DECLARE v_Enrollment_ID INT DEFAULT NULL;

    IF NOT (p_RawGrade REGEXP '^(\(Ongoing\)|R|F)$' OR p_RawGrade REGEXP '^([1-9]|[1-9][0-9]|100)$') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Grade Input. Allowed: (Ongoing), R, F, or 1-100.';
    END IF;

    SELECT e.ID INTO v_Enrollment_ID 
    FROM ENROLLMENT e
    JOIN STUDENT s ON e.STUDENT_ID = s.ID_Number 
    JOIN COURSE c ON e.CURRICULUM_COURSE_ID = c.ID
    WHERE s.fullName = p_Student_Fullname 
      AND c.Code = p_Course_Code
      AND e.CURRICULUM_YEAR_ID = p_Year_ID
      AND e.CURRICULUM_SEMESTER_ID = p_Semester_ID
    LIMIT 1; 

    IF v_Enrollment_ID IS NOT NULL THEN
        IF p_RawGrade REGEXP '^([1-9]|[1-9][0-9]|100)$' THEN
            SET v_NumericGrade = CAST(p_RawGrade AS UNSIGNED);
            
            SET v_FinalGrade = CASE 
                WHEN v_NumericGrade BETWEEN 95 AND 100 THEN '4.00'
                WHEN v_NumericGrade BETWEEN 91 AND 94  THEN '3.50'
                WHEN v_NumericGrade BETWEEN 87 AND 90  THEN '3.00'
                WHEN v_NumericGrade BETWEEN 83 AND 86  THEN '2.50'
                WHEN v_NumericGrade BETWEEN 79 AND 82  THEN '2.00'
                WHEN v_NumericGrade BETWEEN 75 AND 78  THEN '1.50'
                WHEN v_NumericGrade BETWEEN 70 AND 74  THEN '1.00'
                ELSE '0.00' 
            END;
        ELSE
            SET v_FinalGrade = p_RawGrade;
        END IF;

        UPDATE ENROLLMENT
        SET Grade = v_FinalGrade,
            Updated_At = NOW(),
            Updated_By = 'registrar'
        WHERE ID = v_Enrollment_ID;
        
    ELSE
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Record not found for this Student, Course, Year, and Semester.';
    END IF;
END $$

DELIMITER ;
  
/* STORED PROCEDURE FOR VIEWING STUDENT ENROLLMENTS */
DELIMITER $$

CREATE PROCEDURE StudentEnrollmentsViewer (
    IN STUDENT_ID VARCHAR(8)
)
BEGIN
    SELECT
        STUDENT.ID_Number,
        STUDENT.fullName AS 'Full Name',
        STUDENT.YEAR_ID AS 'Year',
        ENROLLMENT.CURRICULUM_SEMESTER_ID AS 'Semester',
        PROGRAM.programName AS 'Program',
        COURSE.Code,
        COURSE.Name AS Course,
        ENROLLMENT.Grade,
        ENROLLMENT.Status
    FROM ENROLLMENT
    JOIN STUDENT
        ON ENROLLMENT.STUDENT_ID = STUDENT.ID_Number
    JOIN COURSE
        ON ENROLLMENT.CURRICULUM_COURSE_ID = COURSE.ID
    JOIN PROGRAM
        ON ENROLLMENT.CURRICULUM_PROGRAM_ID = PROGRAM.ID
    WHERE STUDENT.ID_Number = STUDENT_ID;
END $$

DELIMITER ;
-- STORED PROCEDURE END --

-- TRIGGER BEGIN --

/*TRIGGERS TO AUTOMATICALLY UPDATE Updated_At FOR SOME TABLES*/

DELIMITER $$

CREATE TRIGGER UpdateStudentTimestamp
BEFORE UPDATE ON STUDENT
FOR EACH ROW
BEGIN
    SET NEW.Updated_At = NOW();
END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER UpdateProgramTimestamp
BEFORE UPDATE ON PROGRAM
FOR EACH ROW
BEGIN
    SET NEW.Updated_At = NOW();
END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER UpdateCourseTimestamp
BEFORE UPDATE ON COURSE
FOR EACH ROW
BEGIN
    SET NEW.Updated_At = NOW();
END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER UpdateEnrollmentTimestamp
BEFORE UPDATE ON ENROLLMENT
FOR EACH ROW
BEGIN
    SET NEW.Updated_At = NOW();
END $$

DELIMITER ;

/* TRIGGER TO ENFORCE PREREQUISITE CHECKS */
DELIMITER //

CREATE TRIGGER CheckPrerequisite
BEFORE INSERT ON ENROLLMENT
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM COURSE_PREREQUISITE 
        WHERE COURSE_ID = NEW.CURRICULUM_COURSE_ID
    ) THEN
        IF EXISTS (
            SELECT 1 
            FROM COURSE_PREREQUISITE cp
            WHERE cp.COURSE_ID = NEW.CURRICULUM_COURSE_ID
              AND cp.PREREQUISITE_ID NOT IN (
                  SELECT CURRICULUM_COURSE_ID
                  FROM ENROLLMENT 
                  WHERE STUDENT_ID = NEW.STUDENT_ID
                    AND Status = 'Passed'
              )
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Enrollment Denied: Missing required prerequisites.';
        END IF;
    END IF;
END 
// DELIMITER ;


DELIMITER //

/* TRIGGER TO AUTOMATICALLY UPDATE STATUS BASED ON GRADE */
CREATE TRIGGER AutoUpdateStatus
BEFORE UPDATE ON ENROLLMENT
FOR EACH ROW
BEGIN
    DECLARE v_grade_val DECIMAL(3,2);
 
    IF (NEW.Grade <=> OLD.Grade) = 0 THEN 
        IF NEW.Grade = 'F' OR NEW.Grade = 'R' THEN
            SET NEW.Status = 'Failed';
        ELSEIF (NEW.Grade REGEXP '^[0-9]+(\.[0-9]+)?$') THEN
            SET v_grade_val = CAST(NEW.Grade AS DECIMAL(3,2));
            IF v_grade_val >= 1.00 THEN
                SET NEW.Status = 'Passed';
            ELSE
                SET NEW.Status = 'Failed';
            END IF;
        ELSE
            SET NEW.Status = 'Active';
        END IF;
    END IF;
END //
 
DELIMITER ;
-- TRIGGER END --

-- VIEW BEGIN ---
/* VIEW FOR STUDENT TRANSCRIPTS */
CREATE VIEW studentTranscripts AS
SELECT 
    e.ID AS Enrollment_ID,
    s.ID_Number,
    CONCAT(s.lastName, ', ', s.firstName) AS Student_Name,
    c.Code AS Course_Code,
    c.Name AS Course_Title,
    e.Grade,
    e.Status
FROM ENROLLMENT e
JOIN STUDENT s ON e.STUDENT_ID = s.ID_Number
JOIN COURSE c ON e.CURRICULUM_COURSE_ID = c.ID; 

/*VIEW FOR DEANS LISTERS*/
CREATE VIEW deansList AS
SELECT 
    s.ID_Number, 
    s.firstName, 
    s.lastName, 
    calcGWA(s.ID_Number) AS GWA,
    SUM(cr.Credit_Units) AS Total_Units
FROM STUDENT s
JOIN ENROLLMENT enr ON s.ID_Number = enr.STUDENT_ID
JOIN COURSE cr ON enr.CURRICULUM_COURSE_ID = cr.ID
WHERE 
    -- Exclude students who have any single grade lower than 2.00, or an R/F
    NOT EXISTS (
        SELECT 1 
        FROM ENROLLMENT e2 
        WHERE e2.STUDENT_ID = s.ID_Number 
        AND (
            GetNumericGrade(e2.Grade) < 2.00 
            OR e2.Grade IN ('R', 'F')
        )
    )
    -- Only consider completed courses for the unit count
    AND enr.Grade != '(Ongoing)'
GROUP BY s.ID_Number
HAVING 
    -- GWA must be at least 3.50
    GWA >= 3.50 
    -- Total units taken must be 15 or more
    AND Total_Units >= 15;
-- VIEW END --

-- INSERT INTO BEGIN --
/* BASE SETUP DATA */
INSERT INTO `YEAR` (`ID`) VALUES (2), (3);

INSERT INTO `PROGRAM` (`programName`) VALUES ('BSCS'), ('BSIT');

INSERT INTO `SEMESTER` (`ID`) VALUES (1), (2);

/* STUDENT MASTER RECORDS */
INSERT INTO `STUDENT` (`ID_Number`, `lastName`, `firstName`, `Section`, `YEAR_ID`) VALUES 
('2024-001', 'Abril', 'Sheryn Mae', 'A', 2),
('2024-002', 'Ananayo', 'Breneth Jian', 'A', 2),
('2024-003', 'Bacani', 'Jonard', 'A', 2),
('2024-004', 'Biñas', 'Kurt Gabriel', 'A', 2),
('2024-005', 'Buncab', 'Lance Gabriel', 'A', 2),
('2024-006', 'Chavez', 'Amiel Diamond', 'A', 3),
('2024-007', 'Corpuz', 'Terrence Josh', 'A', 3),
('2024-008', 'Guzman', 'Klein Vincent De', 'A', 3),
('2024-009', 'Cruz', 'Carlrich Dela', 'A', 2),
('2024-010', 'Fama', 'Alijah Miguel', 'A', 2),
('2024-011', 'Garcia', 'Ashton Brian', 'A', 2),
('2024-012', 'Gemillan', 'Miles Angelo', 'A', 2),
('2024-013', 'Genova', 'Carl Dheyniel', 'A', 3),
('2024-014', 'Gutierrez', 'Yumilka', 'A', 2),
('2024-015', 'Juane', 'Lancelot Jerico', 'A', 2),
('2024-016', 'Laus', 'Angelo John Benedict', 'A', 3),
('2024-017', 'Lopez', 'John Christian', 'A', 2),
('2024-018', 'Mandac', 'Gian Patrick Luis', 'A', 2),
('2024-019', 'Mendoza', 'Vinz Szymone', 'A', 3),
('2024-020', 'Nacalaban', 'Chelsea Hillary', 'A', 3),
('2024-021', 'Nagales', 'Qelvin Joszeler', 'A', 2),
('2024-022', 'Nipas', 'Eunice', 'A', 2),
('2024-023', 'Nollen', 'Elijah Crisehea', 'A', 3),
('2024-024', 'Ochoa', 'John Adrian', 'A', 2),
('2024-025', 'Padilla', 'Neichaela Antonia', 'A', 2),
('2024-026', 'Peñada', 'Charl Christopher', 'A', 3),
('2024-027', 'Recto', 'Rehan Rafael', 'A', 2),
('2024-028', 'Revelar', 'Xander', 'A', 3),
('2024-029', 'Ronquillo', 'Karol Joy', 'A', 2),
('2024-030', 'Rumbaoa', 'Anthonee Jhel', 'A', 2),
('2024-031', 'Sultan', 'Jan Samuel', 'A', 3),
('2024-032', 'Tobias', 'Heinrich', 'A', 2),
('2024-033', 'Villa', 'Andrei Antonio', 'A', 3),
('2024-034', 'Viray', 'Kristoff Aadryk', 'A', 2),
('2024-035', 'Whitwell', 'Daniel James', 'A', 3),
('2024-036', 'Mangulabnan', 'Edgardo Jr.', 'A', 3);

INSERT INTO `COURSE` (`ID`, `Code`, `Name`) VALUES 
(1, 'PROG1', 'Programming 1'), (2, 'PROG2', 'Programming 2'), 
(3, 'WEBDEV1', 'Web Dev 1'), (4, 'WEBDEV2', 'Web Dev 2'), 
(5, 'DATAMA1', 'Database Mgmt 1'), (6, 'DATAMA2', 'Database Mgmt 2');

INSERT INTO `COURSE_PREREQUISITE` (`PREREQUISITE_ID`, `COURSE_ID`) VALUES (1, 2), (3, 4), (5, 6);

/* CURRICULUM MAPPING */
INSERT INTO `CURRICULUM` (`PROGRAM_ID`, `YEAR_ID`, `SEMESTER_ID`, `COURSE_ID`) VALUES
(1, 2, 1, 5), (1, 2, 2, 2), (1, 2, 2, 3), (1, 2, 2, 4), (1, 2, 2, 6), (1, 3, 1, 1),
(1, 3, 1, 5), (1, 3, 2, 2), (1, 3, 2, 5), (1, 3, 2, 6), (2, 2, 1, 1), (2, 2, 1, 3),
(2, 2, 1, 5), (2, 2, 2, 1), (2, 2, 2, 2), (2, 2, 2, 3), (2, 2, 2, 4), (2, 2, 2, 5),
(2, 2, 2, 6), (2, 3, 1, 1), (2, 3, 1, 3), (2, 3, 1, 5), (2, 3, 2, 1), (2, 3, 2, 2),
(2, 3, 2, 3), (2, 3, 2, 4), (2, 3, 2, 6);

/* ENROLLMENT RECORDS */
INSERT INTO `ENROLLMENT` (`ID`, `Grade`, `Status`, `STUDENT_ID`, `CURRICULUM_SEMESTER_ID`, `CURRICULUM_COURSE_ID`, `CURRICULUM_PROGRAM_ID`, `CURRICULUM_YEAR_ID`) VALUES
(1, '92', 'Passed', '2024-001', 1, 1, 2, 2),
(2, '70', 'Failed', '2024-002', 1, 1, 2, 2),
(3, '85', 'Passed', '2024-003', 1, 5, 1, 2),
(4, '76', 'Passed', '2024-006', 1, 3, 2, 3),
(5, '90', 'Passed', '2024-013', 1, 1, 2, 3),
(6, '95', 'Passed', '2024-014', 1, 5, 2, 2),
(8, '88', 'Passed', '2024-016', 1, 1, 2, 3),
(9, '78', 'Passed', '2024-017', 1, 3, 2, 2),
(10, '80', 'Passed', '2024-018', 1, 1, 2, 2),
(11, '91', 'Passed', '2024-019', 1, 5, 2, 3),
(12, '72', 'Failed', '2024-020', 1, 1, 1, 3),
(13, '85', 'Passed', '2024-021', 1, 5, 2, 2),
(14, '90', 'Passed', '2024-022', 1, 3, 2, 2),
(15, '75', 'Passed', '2024-023', 1, 1, 2, 3),
(16, '89', 'Passed', '2024-024', 1, 5, 1, 2),
(18, '94', 'Passed', '2024-026', 1, 3, 2, 3),
(19, '77', 'Passed', '2024-027', 1, 5, 1, 2),
(20, '93', 'Passed', '2024-028', 1, 1, 2, 3),
(21, '88', 'Passed', '2024-001', 2, 2, 2, 2),
(22, '84', 'Passed', '2024-003', 2, 6, 1, 2),
(23, '92', 'Passed', '2024-006', 2, 4, 2, 3),
(24, '78', 'Passed', '2024-014', 2, 6, 2, 2),
(25, '82', 'Passed', '2024-016', 2, 2, 2, 3);
-- INSERT INTO END --
