
DROP DATABASE IF EXISTS SAO_DB;
CREATE SCHEMA IF NOT EXISTS SAO_DB;
USE SAO_DB;

-- -----------------------------------------------------
-- Table year
-- -----------------------------------------------------
CREATE TABLE year (
  ID INT NOT NULL,
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (`ID`));

-- -----------------------------------------------------
-- Table program
-- -----------------------------------------------------
CREATE TABLE program (
  ID INT NOT NULL AUTO_INCREMENT,
  programName VARCHAR(45) NOT NULL DEFAULT " ",
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (`ID`),
  UNIQUE INDEX `programName_UNIQUE` (`programName` ASC) VISIBLE);

-- -----------------------------------------------------
-- Table semester
-- -----------------------------------------------------
CREATE TABLE semester (
  ID INT NOT NULL,
  Created_At DATETIME NOT NULL DEFAULT NOW(),
  Updated_At DATETIME NOT NULL DEFAULT NOW(),
  Created_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  Updated_By VARCHAR(45) NOT NULL DEFAULT "registrar",
  PRIMARY KEY (`ID`));

-- -----------------------------------------------------
-- Table course
-- -----------------------------------------------------
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

-- -----------------------------------------------------
-- Table student
-- -----------------------------------------------------
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

-- -----------------------------------------------------
-- Table curriculum
-- -----------------------------------------------------
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

-- -----------------------------------------------------
-- Table enrollment
-- -----------------------------------------------------
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

-- -----------------------------------------------------
-- Table course_prerequisite
-- -----------------------------------------------------
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

-- helper function for calcGWA
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

-- CALC GWA

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

--Updates Student grade status
DELIMITER $$

CREATE PROCEDURE GradeUpdate (
    IN p_Student_Fullname VARCHAR(60),
    IN p_Student_Section VARCHAR(45),
    IN p_Course_Code VARCHAR(7),
    IN p_RawGrade INT 
)
BEGIN
    DECLARE v_ConvertedGrade DECIMAL(3,2);
    DECLARE v_Enrollment_ID INT DEFAULT NULL;

    -- Look for the SPECIFIC enrollment that is currently 'Ongoing'
    SELECT e.ID INTO v_Enrollment_ID 
    FROM ENROLLMENT e
    JOIN STUDENT s ON e.STUDENT_ID = s.ID_Number 
    JOIN COURSE c ON e.CURRICULUM_COURSE_ID = c.ID
    WHERE s.fullName = p_Student_Fullname 
      AND c.Code = p_Course_Code
      AND s.Section = p_Student_Section
      AND e.Grade = '(Ongoing)' -- Ensure we only update the active attempt
    LIMIT 1; 

    IF v_Enrollment_ID IS NOT NULL THEN
        -- Grade Conversion Logic...
        SET v_ConvertedGrade = CASE 
            WHEN p_RawGrade BETWEEN 95 AND 100 THEN 4.00
            WHEN p_RawGrade BETWEEN 91 AND 94  THEN 3.50
            WHEN p_RawGrade BETWEEN 87 AND 90  THEN 3.00
            WHEN p_RawGrade BETWEEN 83 AND 86  THEN 2.50
            WHEN p_RawGrade BETWEEN 79 AND 82  THEN 2.00
            WHEN p_RawGrade BETWEEN 75 AND 78  THEN 1.50
            WHEN p_RawGrade BETWEEN 70 AND 74  THEN 1.00
            ELSE 0.00 
        END;

        UPDATE ENROLLMENT
        SET Grade = CAST(v_ConvertedGrade AS CHAR(4)),
            Updated_At = NOW(),
            Updated_By = 'registrar'
        WHERE ID = v_Enrollment_ID;
    END IF;
END $$
DELIMITER 
--Viewing Student academic records
DELIMITER $$

CREATE PROCEDURE StudentEnrollmentsViewer (
    IN STUDENT_ID VARCHAR(8)
)
BEGIN
    SELECT
        STUDENT.ID_Number,
        STUDENT.fullName AS 'Full Name',
        STUDENT.YEAR,
        ENROLLMENT.CURRICULUM_SEMESTER_ID,
        ENROLLMENT.CURRICULUM_PROGRAM_ID,
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

-- CHECK PREREQUISITE TRIGGER
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


-- -----------------------------------------------------
-- Base Setup (Years, Programs, Semesters)
-- -----------------------------------------------------
INSERT INTO `YEAR` (`ID`) VALUES (2), (3);

INSERT INTO `PROGRAM` (`programName`) VALUES ('BSCS'), ('BSIT');

INSERT INTO `SEMESTER` (`ID`) VALUES (1), (2);

-- -----------------------------------------------------
-- Student Master Records
-- -----------------------------------------------------
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

--------------------------------------------------------------------------------------------------------

INSERT INTO `COURSE` (`ID`, `Code`, `Name`) VALUES 
(1, 'PROG1', 'Programming 1'), (2, 'PROG2', 'Programming 2'), 
(3, 'WEBDEV1', 'Web Dev 1'), (4, 'WEBDEV2', 'Web Dev 2'), 
(5, 'DATAMA1', 'Database Mgmt 1'), (6, 'DATAMA2', 'Database Mgmt 2');

INSERT INTO `COURSE_PREREQUISITE` (`PREREQUISITE_ID`, `COURSE_ID`) VALUES (1, 2), (3, 4), (5, 6);

INSERT INTO `CURRICULUM` (`PROGRAM_ID`, `YEAR_ID`, `SEMESTER_ID`, `COURSE_ID`) VALUES
(1, 2, 1, 5), (1, 2, 2, 2), (1, 2, 2, 3), (1, 2, 2, 4), (1, 2, 2, 6), (1, 3, 1, 1),
(1, 3, 1, 5), (1, 3, 2, 2), (1, 3, 2, 5), (1, 3, 2, 6), (2, 2, 1, 1), (2, 2, 1, 3),
(2, 2, 1, 5), (2, 2, 2, 1), (2, 2, 2, 2), (2, 2, 2, 3), (2, 2, 2, 4), (2, 2, 2, 5),
(2, 2, 2, 6), (2, 3, 1, 1), (2, 3, 1, 3), (2, 3, 1, 5), (2, 3, 2, 1), (2, 3, 2, 2),
(2, 3, 2, 3), (2, 3, 2, 4), (2, 3, 2, 6);

-- INSERT INTO `ENROLLMENT` (`ID`, `Grade`, `Status`, `STUDENT_ID`, `CURRICULUM_SEMESTER_ID`, `CURRICULUM_COURSE_ID`, `CURRICULUM_PROGRAM_ID`, `CURRICULUM_YEAR_ID`) VALUES
-- (1, '92', 'Passed', '2024-001', 1, 1, 2, 2),
-- (2, '70', 'Failed', '2024-002', 1, 1, 2, 2),
-- (3, '85', 'Passed', '2024-003', 1, 5, 1, 2),
-- (4, '76', 'Passed', '2024-006', 1, 3, 2, 3),
-- (5, '90', 'Passed', '2024-013', 1, 1, 2, 3),
-- (6, '95', 'Passed', '2024-014', 1, 5, 2, 2),
-- (8, '88', 'Passed', '2024-016', 1, 1, 2, 3),
-- (9, '78', 'Passed', '2024-017', 1, 3, 2, 2),
-- (10, '80', 'Passed', '2024-018', 1, 1, 2, 2),
-- (11, '91', 'Passed', '2024-019', 1, 5, 2, 3),
-- (12, '72', 'Failed', '2024-020', 1, 1, 1, 3),
-- (13, '85', 'Passed', '2024-021', 1, 5, 2, 2),
-- (14, '90', 'Passed', '2024-022', 1, 3, 2, 2),
-- (15, '75', 'Passed', '2024-023', 1, 1, 2, 3),
-- (16, '89', 'Passed', '2024-024', 1, 5, 1, 2),
-- (18, '94', 'Passed', '2024-026', 1, 3, 2, 3),
-- (19, '77', 'Passed', '2024-027', 1, 5, 1, 2),
-- (20, '93', 'Passed', '2024-028', 1, 1, 2, 3),
-- (21, '88', 'Passed', '2024-001', 2, 2, 2, 2),
-- (22, '84', 'Passed', '2024-003', 2, 6, 1, 2),
-- (23, '92', 'Passed', '2024-006', 2, 4, 2, 3),
-- (24, '78', 'Passed', '2024-014', 2, 6, 2, 2),
-- (25, '82', 'Passed', '2024-016', 2, 2, 2, 3),
-- (26, '79', 'Passed', '2024-017', 2, 4, 2, 2),
-- (27, '89', 'Passed', '2024-018', 2, 2, 2, 2),
-- (28, '92', 'Passed', '2024-019', 2, 6, 2, 3),
-- (29, '87', 'Passed', '2024-021', 2, 6, 2, 2),
-- (30, '91', 'Passed', '2024-022', 2, 4, 2, 2),
-- (31, '86', 'Passed', '2024-023', 2, 2, 2, 3),
-- (32, '81', 'Passed', '2024-024', 2, 6, 1, 2),
-- (34, '90', 'Passed', '2024-026', 2, 4, 2, 3),
-- (35, '76', 'Passed', '2024-027', 2, 6, 1, 2),
-- (36, '88', 'Passed', '2024-028', 2, 2, 2, 3),
-- (37, '85', 'Passed', '2024-029', 1, 1, 2, 2),
-- (38, '79', 'Passed', '2024-030', 1, 5, 1, 2),
-- (39, '70', 'Failed', '2024-031', 1, 3, 2, 3),
-- (40, '84', 'Passed', '2024-032', 1, 1, 2, 2),
-- (41, '92', 'Passed', '2024-033', 1, 5, 1, 3),
-- (42, '81', 'Passed', '2024-034', 1, 1, 2, 2),
-- (43, '93', 'Passed', '2024-035', 1, 3, 2, 3),
-- (44, '87', 'Passed', '2024-036', 1, 1, 1, 3),
-- (45, '65', 'Failed', '2024-004', 1, 5, 2, 2),
-- (47, '80', 'Passed', '2024-001', 2, 3, 2, 2),
-- (48, '79', 'Passed', '2024-002', 2, 5, 2, 2),
-- (49, '91', 'Passed', '2024-003', 2, 2, 1, 2),
-- (50, '85', 'Passed', '2024-006', 2, 6, 2, 3),
-- (51, '82', 'Passed', '2024-013', 2, 2, 2, 3),
-- (52, '75', 'Passed', '2024-014', 2, 3, 2, 2),
-- (54, '85', 'Passed', '2024-016', 2, 3, 2, 3),
-- (55, '79', 'Passed', '2024-017', 2, 2, 2, 2),
-- (56, '88', 'Passed', '2024-018', 2, 6, 2, 2),
-- (57, '92', 'Passed', '2024-019', 2, 2, 2, 3),
-- (58, '78', 'Passed', '2024-020', 2, 5, 1, 3),
-- (59, '87', 'Passed', '2024-021', 2, 2, 2, 2),
-- (60, '83', 'Passed', '2024-022', 2, 6, 2, 2),
-- (61, '86', 'Passed', '2024-023', 2, 2, 2, 3),
-- (62, '81', 'Passed', '2024-024', 2, 3, 1, 2),
-- (64, '90', 'Passed', '2024-026', 2, 6, 2, 3),
-- (65, '83', 'Passed', '2024-027', 2, 2, 1, 2),
-- (66, '94', 'Passed', '2024-028', 2, 3, 2, 3),
-- (67, '79', 'Passed', '2024-029', 2, 2, 2, 2),
-- (68, '82', 'Passed', '2024-030', 2, 6, 1, 2),
-- (69, '72', 'Failed', '2024-031', 2, 1, 2, 3),
-- (70, '85', 'Passed', '2024-032', 2, 6, 2, 2),
-- (71, '88', 'Passed', '2024-033', 2, 2, 1, 3),
-- (72, '93', 'Passed', '2024-034', 2, 6, 2, 2),
-- (73, '91', 'Passed', '2024-035', 2, 2, 2, 3),
-- (74, '84', 'Passed', '2024-036', 2, 6, 1, 3),
-- (75, '89', 'Passed', '2024-004', 2, 1, 2, 2),
-- (77, '(Ongoing)', 'Active', '2024-001', 2, 6, 2, 2),
-- (78, '(Ongoing)', 'Active', '2024-002', 2, 4, 2, 2),
-- (79, '(Ongoing)', 'Active', '2024-003', 2, 6, 1, 2),
-- (80, '(Ongoing)', 'Active', '2024-006', 2, 2, 2, 3),
-- (81, '(Ongoing)', 'Active', '2024-013', 2, 4, 2, 3),
-- (82, '(Ongoing)', 'Active', '2024-014', 2, 6, 2, 2),
-- (84, '(Ongoing)', 'Active', '2024-016', 2, 6, 2, 3),
-- (85, '(Ongoing)', 'Active', '2024-017', 2, 4, 2, 2),
-- (86, '(Ongoing)', 'Active', '2024-018', 2, 2, 2, 2),
-- (87, '(Ongoing)', 'Active', '2024-019', 2, 3, 2, 3),
-- (88, '(Ongoing)', 'Active', '2024-020', 2, 6, 1, 3),
-- (89, '(Ongoing)', 'Active', '2024-021', 2, 4, 2, 2),
-- (90, '(Ongoing)', 'Active', '2024-022', 2, 2, 2, 2),
-- (91, '(Ongoing)', 'Active', '2024-023', 2, 6, 2, 3),
-- (92, '(Ongoing)', 'Active', '2024-024', 2, 4, 1, 2),
-- (94, '(Ongoing)', 'Active', '2024-026', 2, 4, 2, 3),
-- (95, '(Ongoing)', 'Active', '2024-027', 2, 6, 1, 2),
-- (96, '(Ongoing)', 'Active', '2024-028', 2, 2, 2, 3),
-- (97, '(Ongoing)', 'Active', '2024-029', 2, 3, 2, 2),
-- (98, '(Ongoing)', 'Active', '2024-030', 2, 6, 1, 2),
-- (99, '(Ongoing)', 'Active', '2024-031', 2, 1, 2, 3),
-- (100, '(Ongoing)', 'Active', '2024-032', 2, 3, 2, 2);
