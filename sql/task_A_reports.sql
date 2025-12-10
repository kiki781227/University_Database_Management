USE Kiady;  
GO


-- Q1 : Statistiques globales par département
WITH DeptStats AS (
    SELECT 
        d.DepartmentID,
        d.Name AS DepartmentName,
        COUNT(DISTINCT s.StudentID)      AS NbStudents,
        COUNT(DISTINCT p.ProfessorID)    AS NbProfessors,
        COUNT(DISTINCT c.CourseID)       AS NbCourses,
        AVG(CAST(c.Credits AS FLOAT))    AS AvgCredits,
        AVG(CAST(e.Grade  AS FLOAT))     AS AvgGrade
    FROM Departments d
    LEFT JOIN Courses     c ON c.DepartmentID = d.DepartmentID
    LEFT JOIN Enrollments e ON e.CourseID     = c.CourseID
    LEFT JOIN Students    s ON s.StudentID    = e.StudentID
    LEFT JOIN Professors  p ON p.DepartmentID = d.DepartmentID
    GROUP BY d.DepartmentID, d.Name
)
SELECT *
FROM DeptStats
ORDER BY DepartmentName;
GO


-- Q2 : Moyenne et classement des étudiants par département
WITH StudentAvg AS (
    SELECT 
        s.StudentID,
        s.Name              AS StudentName,
        c.DepartmentID,
        AVG(CAST(e.Grade AS FLOAT)) AS AvgGrade,
        COUNT(DISTINCT e.CourseID)  AS NbCourses
    FROM Students s
    JOIN Enrollments e ON e.StudentID = s.StudentID
    JOIN Courses     c ON c.CourseID  = e.CourseID
    WHERE e.Grade IS NOT NULL
    GROUP BY s.StudentID, s.Name, c.DepartmentID
),
StudentRank AS (
    SELECT 
        *,
        DENSE_RANK() OVER (
            PARTITION BY DepartmentID
            ORDER BY AvgGrade DESC
        ) AS RankInDept
    FROM StudentAvg
)
SELECT *
FROM StudentRank
ORDER BY DepartmentID, RankInDept, StudentName;
GO


-- Q3 : PIVOT - nombre de cours par département et par crédits
--       (colonnes 1,3,6,8 crédits)
SELECT 
    DepartmentName,
    ISNULL([1], 0) AS Credits_1,
    ISNULL([3], 0) AS Credits_3,
    ISNULL([6], 0) AS Credits_6,
    ISNULL([8], 0) AS Credits_8
FROM (
    SELECT 
        d.Name   AS DepartmentName,
        c.Credits
    FROM Departments d
    JOIN Courses     c ON c.DepartmentID = d.DepartmentID
) src
PIVOT (
    COUNT(Credits) FOR Credits IN ([1],[3],[6],[8])
) p
ORDER BY DepartmentName;
GO


-- Q4 : Top 5 des cours par moyenne de note (avec HAVING)
SELECT TOP 5
    c.CourseID,
    c.CourseName,
    d.Name AS DepartmentName,
    AVG(CAST(e.Grade AS FLOAT)) AS AvgGrade,
    COUNT(*) AS NbEnrollments
FROM Courses c
JOIN Departments d ON d.DepartmentID = c.DepartmentID
JOIN Enrollments e ON e.CourseID     = c.CourseID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.CourseName, d.Name
HAVING COUNT(*) >= 3      -- on garde les cours avec au moins 3 inscriptions
ORDER BY AvgGrade DESC;
GO

