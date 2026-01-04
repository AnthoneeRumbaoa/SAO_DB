-- File for SQL functions (like the GWA calculator I guess)
-- Calculate GWA
DELIMITER //

CREATE FUNCTION calcGWA (
    student_id_parameter VARCHAR(8)
)
RETURNS DECIMAL(5,2) -- example nito is 95.75
READS SQL DATA -- we need this kasi need niya makita yung data from ENROLLMENT table
BEGIN
    DECLARE total_units INT;
    DECLARE weighted_sum DECIMAL(10,2);
    DECLARE gwa DECIMAL(5,2);

    -- Get totals for the specific student where they passed
    SELECT SUM(Units), SUM(CAST(Grade AS DECIMAL(5,2)) * Units)
    INTO total_units, weighted_sum
    FROM ENROLLMENT
    WHERE STUDENT_ID = student_id_parameter AND Status = 'Passed';

    -- Avoid division by zero
    IF total_units > 0 THEN
        SET gwa = weighted_sum / total_units;
    ELSE
        SET gwa = 0.00;
    END IF;

    RETURN gwa;
END //

DELIMITER ;


SELECT ID_Number, firstName, lastName, CalculateGWA(ID_Number) AS GWA FROM STUDENT;
