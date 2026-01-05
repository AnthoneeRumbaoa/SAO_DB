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
