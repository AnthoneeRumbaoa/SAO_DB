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
