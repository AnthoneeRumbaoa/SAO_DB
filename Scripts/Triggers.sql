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


-- STATUS AUTO UPDATE ON GRADE CHANGE TRIGGER
DELIMITER //

CREATE TRIGGER AutoUpdateStatus
BEFORE UPDATE ON ENROLLMENT
FOR EACH ROW
BEGIN
    DECLARE Grade_num INT;

    IF (NEW.Grade <=> OLD.Grade) = 0 THEN 
        
        IF (NEW.Grade REGEXP '^[0-9]+$') THEN
            SET Grade_num = CAST(NEW.Grade AS SIGNED);
        ELSE
            SET Grade_num = NULL; 
        END IF;

        IF (Grade_num IS NULL) THEN
            SET NEW.Status = "Active";
        ELSE
            IF (Grade_num BETWEEN 75 AND 100) THEN
                SET NEW.Status = "Passed";
            ELSE
                SET NEW.Status = "Failed";
            END IF;
        END IF;
        
    END IF;
END //

DELIMITER ;
