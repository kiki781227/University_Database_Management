USE Kiady;
--SELECT * FROM dbo.Clubs
--SELECT * FROM dbo.Courses
--SELECT * FROM dbo.Departments
--SELECT * FROM dbo.Enrollments
--SELECT * FROM dbo.Professors
--SELECT * FROM dbo.Students
--SELECT * FROM dbo.StudentClubs
--SELECT * FROM Enrollments WHERE Grade > 80;


BULK INSERT dbo.Clubs
FROM 'D:\kiki\BD3\Projet - RABENARIVO KIADY MANITRIALA\data\clubs.csv'
WITH(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR =  '0x0a'
);


BULK INSERT dbo.Courses
FROM 'D:\kiki\BD3\Projet - RABENARIVO KIADY MANITRIALA\data\courses.csv'
WITH(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR =  '0x0a'
);


BULK INSERT dbo.Departments
FROM 'D:\kiki\BD3\Projet - RABENARIVO KIADY MANITRIALA\data\departments.csv'
WITH(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR =  '0x0a'
);


BULK INSERT dbo.Professors
FROM 'D:\kiki\BD3\Projet - RABENARIVO KIADY MANITRIALA\data\professors.csv'
WITH(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR =  '0x0a'
);


BULK INSERT dbo.Enrollments
FROM 'D:\kiki\BD3\Projet - RABENARIVO KIADY MANITRIALA\data\enrollments.csv'
WITH(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR =  '0x0a'
);


BULK INSERT dbo.Students
FROM 'D:\kiki\BD3\Projet - RABENARIVO KIADY MANITRIALA\data\students.csv'
WITH(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR =  '0x0a'
);


BULK INSERT dbo.StudentClubs
FROM 'D:\kiki\BD3\Projet - RABENARIVO KIADY MANITRIALA\data\student_clubs.csv'
WITH(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR =  '0x0a'
);






