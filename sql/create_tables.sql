USE Kiady
GO

-- Table : Departments (sans FK pour éviter dépendance circulaire)
CREATE TABLE Departments (
    DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    HeadOfDepartment INT NULL,
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);
GO

-- Table : Professors
CREATE TABLE Professors (
    ProfessorID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    DepartmentID INT NOT NULL,
    Email NVARCHAR(100) NULL, -- On met en NULL juste pour la simu
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);
GO

-- Ajout FK HeadOfDepartment (dépendance circulaire)
ALTER TABLE Departments
ADD CONSTRAINT FK_Departments_HeadOfDepartment
FOREIGN KEY (HeadOfDepartment) REFERENCES Professors(ProfessorID);
GO

-- Table : Students
CREATE TABLE Students (
    StudentID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NULL,
    Email NVARCHAR(100) NULL, -- On met en NULL juste pour la simu
    DOB DATE NOT NULL,
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);

-- Table : Courses
CREATE TABLE Courses (
    CourseID INT IDENTITY(1,1) PRIMARY KEY,
    CourseName NVARCHAR(100) NOT NULL,
    Credits INT NOT NULL, -- Pas de CHECK pour la simu ( Nb: les credits valides sont [1,3,6,8] )
    DepartmentID INT NOT NULL,
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);

-- Table : Clubs
CREATE TABLE Clubs (
    ClubID INT IDENTITY(1,1) PRIMARY KEY,
    ClubName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255),
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);

-- Table : Enrollments
CREATE TABLE Enrollments (
    EnrollmentID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT NOT NULL,
    CourseID INT NOT NULL,
    Semester NVARCHAR(20),
    Grade DECIMAL(4,2) CHECK (Grade BETWEEN 0 AND 100),
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID),
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);

-- Table : StudentClubs (Many-to-Many)
CREATE TABLE StudentClubs (
    StudentID INT NOT NULL,
    ClubID INT NOT NULL,
    PRIMARY KEY (StudentID, ClubID),
    FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    FOREIGN KEY (ClubID) REFERENCES Clubs(ClubID),
    student_fullname NVARCHAR(30) NOT NULL DEFAULT 'RABENARIVO KIADY MANITRIALA'
);