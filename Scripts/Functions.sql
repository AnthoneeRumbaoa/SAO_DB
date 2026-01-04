-- File for SQL functions (like the GWA calculator I guess)
-- Calculate GWA
DELIMITER //

CREATE FUNCTION calcGWA (
    student_id_parameter VARCHAR(8)
    semester_id_parameter INT
)
RETURNS DECIMAL(5,2) -- example nito is 95.75
READS SQL DATA -- we need this kasi need niya makita yung data from ENROLLMENT table
BEGIN
    DECLARE total_units INT DEFAULT 0;
    DECLARE total_points DECIMAL(10,2) DEFAULT 0.00;
    DECLARE gwa DECIMAL(5,2) DEFAULT 0.00;

-- Calculate based on the 4.0 Scale Formula
    SELECT 
        SUM(Units), 
        SUM(GetNumericGrade(Grade) * Units)
    INTO 
        total_units, 
        total_points
    FROM ENROLLMENT
    WHERE STUDENT_ID = student_id_parameter
      AND CURRICULUM_SEMESTER_ID = semester_id_parameter
      -- Only include records that actually have a grade (exclude currently enrolled)
      AND Grade IS NOT NULL;

    -- Avoid division by zero
    IF total_units > 0 THEN
        SET gwa = total_points / total_units;
    ELSE
        SET gwa = 0.00;
    END IF;

    RETURN gwa;
END //

DELIMITER ;
