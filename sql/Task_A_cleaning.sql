USE Kiady;  
GO

-- Normaliser les noms
IF OBJECT_ID('dbo.fn_NormalizeName', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_NormalizeName;
GO

CREATE FUNCTION dbo.fn_NormalizeName (@name NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN
    RETURN UPPER(LTRIM(RTRIM(@name)));
END;
GO


UPDATE Students
SET Name = dbo.fn_NormalizeName(Name);

UPDATE Professors
SET Name = dbo.fn_NormalizeName(Name);

UPDATE Departments
SET Name = dbo.fn_NormalizeName(Name);

UPDATE Courses
SET CourseName = dbo.fn_NormalizeName(CourseName);

UPDATE Clubs
SET ClubName = dbo.fn_NormalizeName(ClubName);




-- 3.1 Students.Email

UPDATE Students
SET Email = LOWER(LTRIM(RTRIM(Email)));

-- Passer en NULL les emails manifestement invalides
UPDATE Students
SET Email = NULL
WHERE Email IS NOT NULL
  AND (
        Email NOT LIKE '%@%.%' 
        OR Email LIKE '% %'     
      );

-- Générer un email propre pour ceux qui n’en ont pas
UPDATE Students
SET Email =  LOWER(REPLACE(LTRIM(RTRIM(Name)), ' ', '.')) + '@university.mu'
WHERE Email IS NULL;



-- 3.2 Professors.Email

UPDATE Professors
SET Email = LOWER(LTRIM(RTRIM(Email)));

UPDATE Professors
SET Email = NULL
WHERE Email IS NOT NULL
  AND (
        Email NOT LIKE '%@%.%'
        OR Email LIKE '% %'
      );

-- Générer un email propre si manquant
UPDATE Professors
SET Email = LOWER(REPLACE(LTRIM(RTRIM(Name)), ' ', '.')) + '@university.mu'
WHERE Email IS NULL;


-- Nettoyage des CREDITS (Courses.Credits)

-- Corriger les valeurs "bruitées"
UPDATE Courses
SET Credits =
    CASE
        WHEN Credits IN (1,3,6,8) THEN Credits          
        WHEN Credits IN (2,4)       THEN 3              
        WHEN Credits IN (5,7)       THEN 6              
        ELSE 8                                          
    END;


--Nettoyage des doublons

-- Doublons Students
;WITH StudentDups AS (
    SELECT 
        StudentID,
        Name,
        DOB,
        ROW_NUMBER() OVER (
            PARTITION BY Name, DOB
            ORDER BY StudentID
        ) AS rn
    FROM Students
)
DELETE FROM StudentDups
WHERE rn > 1;


-- Doublons Enrollments
;WITH EnrollDups AS (
    SELECT 
        EnrollmentID,
        StudentID,
        CourseID,
        Semester,
        ROW_NUMBER() OVER (
            PARTITION BY StudentID, CourseID, Semester
            ORDER BY EnrollmentID
        ) AS rn
    FROM Enrollments
)
DELETE FROM EnrollDups
WHERE rn > 1;


