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

SELECT * FROM studentTranscripts 
WHERE ID_Number = '2023-001';
