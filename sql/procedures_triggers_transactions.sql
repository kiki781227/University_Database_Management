USE Kiady ;  
GO

IF OBJECT_ID('dbo.EnrollmentAudit', 'U') IS NOT NULL
    DROP TABLE dbo.EnrollmentAudit;
GO

IF OBJECT_ID('dbo.trg_Enrollments_Audit', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Enrollments_Audit;
GO

IF OBJECT_ID('dbo.sp_AddEnrollment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AddEnrollment;
GO

IF OBJECT_ID('dbo.sp_RemoveEnrollment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RemoveEnrollment;
GO

-- B1. TABLE D'AUDIT POUR LES INSCRIPTIONS

CREATE TABLE dbo.EnrollmentAudit (
    AuditID        INT IDENTITY(1,1) PRIMARY KEY,
    EnrollmentID   INT NULL,
    StudentID      INT NULL,
    CourseID       INT NULL,
    OperationType  NVARCHAR(20) NOT NULL, 
    OperationDate  DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    PerformedBy    SYSNAME       NOT NULL DEFAULT SUSER_SNAME(),
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);
GO



-- B2. PROCEDURE : INSCRIRE UN ETUDIANT A UN COURS
-- (avec transaction + contrôles)
IF OBJECT_ID('dbo.sp_AddEnrollment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AddEnrollment;
GO

CREATE PROCEDURE dbo.sp_AddEnrollment
    @StudentID INT,
    @CourseID  INT,
    @Semester  INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        -- 1) Vérifier que l'étudiant existe
        IF NOT EXISTS (SELECT 1 FROM Students WHERE StudentID = @StudentID)
        BEGIN
            RAISERROR('StudentID %d n''existe pas.', 16, 1, @StudentID);
            ROLLBACK TRAN;
            RETURN;
        END;

        -- 2) Vérifier que le cours existe
        IF NOT EXISTS (SELECT 1 FROM Courses WHERE CourseID = @CourseID)
        BEGIN
            RAISERROR('CourseID %d n''existe pas.', 16, 1, @CourseID);
            ROLLBACK TRAN;
            RETURN;
        END;

        -- 3) Vérifier que l''étudiant n''est pas déjà inscrit à ce cours ce semestre
        IF EXISTS (
            SELECT 1
            FROM Enrollments
            WHERE StudentID = @StudentID
              AND CourseID  = @CourseID
              AND Semester  = @Semester
        )
        BEGIN
            RAISERROR(
                'L''étudiant %d est déjà inscrit au cours %d pour le semestre %d.',
                16, 1, @StudentID, @CourseID, @Semester
            );
            ROLLBACK TRAN;
            RETURN;
        END;

        -- 4) Inscrire l'étudiant (Grade = NULL au début)
        INSERT INTO Enrollments (StudentID, CourseID, Semester, Grade, student_fullname)
        VALUES (@StudentID, @CourseID, @Semester, NULL, 'RABENARIVO KIADY MANITRIALA');

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        THROW;
    END CATCH
END;
GO




-- B3. PROCEDURE : DESINSCRIRE UN ETUDIANT D'UN COURS
-- (avec transaction + contrôles)
IF OBJECT_ID('dbo.sp_RemoveEnrollment', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_RemoveEnrollment;
GO

CREATE PROCEDURE dbo.sp_RemoveEnrollment
    @StudentID INT,
    @CourseID  INT,
    @Semester  INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        -- 1) Vérifier qu'il existe bien une inscription
        IF NOT EXISTS (
            SELECT 1
            FROM Enrollments
            WHERE StudentID = @StudentID
              AND CourseID  = @CourseID
              AND Semester  = @Semester
        )
        BEGIN
            RAISERROR(
                'Aucune inscription trouvée pour StudentID=%d, CourseID=%d, Semester=%d.',
                16, 1, @StudentID, @CourseID, @Semester
            );
            ROLLBACK TRAN;
            RETURN;
        END;

        -- 2) Supprimer l'inscription
        DELETE FROM Enrollments
        WHERE StudentID = @StudentID
          AND CourseID  = @CourseID
          AND Semester  = @Semester;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO




-- B4. TRIGGER D'AUDIT SUR ENROLLMENTS
-- (INSERT / DELETE / UPDATE => log dans EnrollmentAudit)
IF OBJECT_ID('dbo.trg_Enrollments_Audit', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Enrollments_Audit;
GO

CREATE TRIGGER dbo.trg_Enrollments_Audit
ON dbo.Enrollments
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @op NVARCHAR(20);

    -- INSERT uniquement
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
        SET @op = 'INSERT';

    -- DELETE uniquement
    ELSE IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
        SET @op = 'DELETE';

    -- UPDATE (il y a à la fois inserted et deleted)
    ELSE
        SET @op = 'UPDATE';

    -- On logge les valeurs "nouvelles" si possible (inserted), sinon les anciennes (deleted)
    INSERT INTO dbo.EnrollmentAudit (EnrollmentID, StudentID, CourseID, OperationType)
    SELECT 
        COALESCE(i.EnrollmentID, d.EnrollmentID),
        COALESCE(i.StudentID,    d.StudentID),
        COALESCE(i.CourseID,     d.CourseID),
        @op
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON i.EnrollmentID = d.EnrollmentID;
END;
GO



---- TESTS 

---- Voir quelques étudiants et cours pour choisir des IDs
--SELECT TOP 5 * FROM Students ORDER BY StudentID;
--SELECT TOP 5 * FROM Courses  ORDER BY CourseID;
--GO



---- TEST 1 : INSCRIPTION RÉUSSIE (TRANSACTION COMMIT)
--EXEC dbo.sp_AddEnrollment 
--    @StudentID = 2,
--    @CourseID  = 4,
--    @Semester  = 1;
--GO

---- Vérifier dans Enrollments
--SELECT TOP 10 *
--FROM Enrollments
--WHERE StudentID = 2 AND CourseID = 4
--ORDER BY EnrollmentID DESC;

---- Vérifier dans la table d'audit
--SELECT TOP 10 *
--FROM EnrollmentAudit
--ORDER BY AuditID DESC;
--GO


---- TEST 2 : INSCRIPTION EN DOUBLE (TRANSACTION ROLLBACK)
---- -> doit lever une erreur RAISERROR et ne pas ajouter de ligne
--EXEC dbo.sp_AddEnrollment 
--    @StudentID = 2,
--    @CourseID  = 4,
--    @Semester  = 1;
--GO

---- Vérifier qu'il n'y a toujours qu'une seule inscription
--SELECT *
--FROM Enrollments
--WHERE StudentID = 2 AND CourseID = 4 AND Semester = 1;
--GO



---- TEST 3 : DESINSCRIPTION (DELETE + AUDIT)
--EXEC dbo.sp_RemoveEnrollment
--    @StudentID = 2,
--    @CourseID  = 4,
--    @Semester  = 1;
--GO

---- Vérifier que l'inscription a disparu
--SELECT *
--FROM Enrollments
--WHERE StudentID = 2 AND CourseID = 4 AND Semester = 1;

---- Vérifier l'audit (tu dois voir une ligne DELETE)
--SELECT TOP 10 *
--FROM EnrollmentAudit
--ORDER BY AuditID DESC;
--GO


-- TEST 4 : UPDATE D'UNE NOTE (pour montrer l'audit UPDATE)
-- Recréer une inscription pour le test UPDATE
EXEC dbo.sp_AddEnrollment 
    @StudentID = 2,
    @CourseID  = 4,
    @Semester  = 1;
GO

-- Mettre une note (UPDATE sur Enrollments)
UPDATE Enrollments
SET Grade = 75.5
WHERE StudentID = 2 AND CourseID = 4 AND Semester = 1;
GO

-- Vérifier l'audit : tu dois voir au moins un INSERT et un UPDATE
SELECT TOP 10 *
FROM EnrollmentAudit
ORDER BY AuditID DESC;
GO

