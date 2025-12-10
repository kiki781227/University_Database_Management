USE Kiady;
GO

-- Désactiver temporairement les contraintes de clés étrangères
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Nettoyer toutes les tables (ordre inverse des dépendances)
DELETE FROM dbo.Enrollments;
DELETE FROM dbo.StudentClubs;
DELETE FROM dbo.Courses;
DELETE FROM dbo.Clubs;
DELETE FROM dbo.Students;
DELETE FROM dbo.Professors;
DELETE FROM dbo.Departments;
GO

-- Réactiver les contraintes
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';
GO

--  Réinitialiser les compteurs d'identité
DBCC CHECKIDENT ('dbo.Enrollments', RESEED, 0);
DBCC CHECKIDENT ('dbo.Courses', RESEED, 0);
DBCC CHECKIDENT ('dbo.Clubs', RESEED, 0);
DBCC CHECKIDENT ('dbo.Students', RESEED, 0);
DBCC CHECKIDENT ('dbo.ProfesSors', RESEED, 0);
DBCC CHECKIDENT ('dbo.Departments', RESEED, 0);
GO

-- Vérifier que tout est vide
SELECT 'Clubs' AS TableName, COUNT(*) AS NombreLignes FROM dbo.Clubs
UNION ALL
SELECT 'Courses', COUNT(*) FROM dbo.Courses
UNION ALL
SELECT 'Departments', COUNT(*) FROM dbo.Departments
UNION ALL
SELECT 'Enrollments', COUNT(*) FROM dbo.Enrollments
UNION ALL
SELECT 'Professors', COUNT(*) FROM dbo.Professors
UNION ALL
SELECT 'StudentClubs', COUNT(*) FROM dbo.StudentClubs
UNION ALL
SELECT 'Students', COUNT(*) FROM dbo.Students;
GO