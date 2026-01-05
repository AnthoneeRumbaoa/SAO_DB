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
        SUM(Credit_Units), 
        SUM(GetNumericGrade(Grade) * Credit_Units)
    INTO v_total_units, v_weighted_sum
    FROM ENROLLMENT enr 
    JOIN CURRICULUM cur ON enr.CURRICULUM_COURSE_ID = cur.COURSE_ID
    JOIN COURSE cr ON cur.COURSE_ID = cr.ID
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
