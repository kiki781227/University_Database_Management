USE Kiady;
GO

-- 1. Trouver et supprimer TOUTES les contraintes FK automatiquement
DECLARE @sql NVARCHAR(MAX) = '';

SELECT @sql += 'ALTER TABLE ' + QUOTENAME(SCHEMA_NAME(fk.schema_id)) + '.' + 
               QUOTENAME(OBJECT_NAME(fk.parent_object_id)) + 
               ' DROP CONSTRAINT ' + QUOTENAME(fk.name) + ';' + CHAR(13)
FROM sys.foreign_keys fk;

EXEC sp_executesql @sql;
GO

-- 2. Maintenant supprimer toutes les tables
DROP TABLE IF EXISTS dbo.Enrollments;
DROP TABLE IF EXISTS dbo.StudentClubs;
DROP TABLE IF EXISTS dbo.Courses;
DROP TABLE IF EXISTS dbo.Students;
DROP TABLE IF EXISTS dbo.Clubs;
DROP TABLE IF EXISTS dbo.Departments;  -- Corrigé: Departments (pas Departements)
DROP TABLE IF EXISTS dbo.Professors;
GO

-- 3. Vérifier qu'il ne reste aucune table
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
  AND TABLE_SCHEMA = 'dbo';
GO



