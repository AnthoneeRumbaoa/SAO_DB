-- File for SQL functions (like the GWA calculator I guess)

--helper function
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

-- Calculate GWA
DELIMITER //
 
CREATE FUNCTION calcGWA (
    p_student_id VARCHAR(8),
    p_semester_id INT
)
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_total_units INT DEFAULT 0;
    DECLARE v_weighted_sum DECIMAL(10,2) DEFAULT 0.00;
 
    SELECT 
        SUM(Units), 
        SUM(GetNumericGrade(Grade) * Units)
    INTO v_total_units, v_weighted_sum
    FROM ENROLLMENT
    WHERE STUDENT_ID = p_student_id
      AND CURRICULUM_SEMESTER_ID = p_semester_id
      AND Grade != '(Ongoing)'; -- Exclude classes that aren't finished
 
    IF v_total_units > 0 THEN
        RETURN v_weighted_sum / v_total_units;
    ELSE
        RETURN 0.00;
    END IF;
END //
 
DELIMITER ;
