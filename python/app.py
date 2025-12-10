# app.py
import os
import streamlit as st
import pandas as pd

from db_utils import run_select, run_non_query, run_sql_script
from config import SQL_DIR

# Configuration de la page & chemins
st.set_page_config(page_title="University DB - Kiady", layout="wide")



# Utilitaires
def show_table(name: str, query: str):
    """Affiche une table SQL dans un dataframe Streamlit."""
    st.subheader(name)
    try:
        df = run_select(query)
        st.dataframe(df)
    except Exception as e:
        st.error(f"Erreur lors du chargement de {name} : {e}")



# Navigation
st.sidebar.title("Navigation")
section = st.sidebar.radio(
    "Section",
    [
        "Scripts SQL (maintenance)",
        "Données & Nettoyage (Task A)",
        "Rapports avancés (Task A)",
        "Opérations inscriptions (Task B)",
        "Monitoring (Task B)",
    ],
)


# SECTION 1 : DONNÉES & NETTOYAGE (TASK A)
if section == "Données & Nettoyage (Task A)":
    st.title("Données & Nettoyage (Task A)")

    st.write(
        "Affichage rapide des tables principales (TOP 50 lignes) pour vérifier "
        "le résultat des imports et du nettoyage."
    )

    col1, col2 = st.columns(2)

    with col1:
        if st.button("Voir Students"):
            show_table("Students", "SELECT TOP 50 * FROM Students ORDER BY StudentID;")

        if st.button("Voir Professors"):
            show_table("Professors", "SELECT TOP 50 * FROM Professors ORDER BY ProfessorID;")

        if st.button("Voir Departments"):
            show_table("Departments", "SELECT TOP 50 * FROM Departments ORDER BY DepartmentID;")

    with col2:
        if st.button("Voir Courses"):
            show_table("Courses", "SELECT TOP 50 * FROM Courses ORDER BY CourseID;")

        if st.button("Voir Enrollments"):
            show_table("Enrollments", "SELECT TOP 50 * FROM Enrollments ORDER BY EnrollmentID DESC;")

        # si Clubs n'existe pas, ce bouton renverra une erreur (ce n'est pas bloquant)
        if st.button("Voir Clubs"):
            show_table("Clubs", "SELECT TOP 50 * FROM Clubs ORDER BY ClubID;")

    st.info(
        "Cette section sert surtout à vérifier visuellement le résultat du nettoyage :\n"
        "- noms normalisés\n"
        "- emails régénérés\n"
        "- crédits corrigés (1,3,6,8)\n"
        "- absence de doublons, etc."
    )


# SECTION 2 : RAPPORTS AVANCÉS (TASK A)
elif section == "Rapports avancés (Task A)":
    st.title("Rapports avancés (Task A)")

    rapport = st.selectbox(
        "Choisir un rapport",
        [
            "Q1 - Stats par département",
            "Q2 - Classement étudiants par département",
            "Q3 - PIVOT crédits par département",
            "Q4 - Top 5 cours par moyenne de note",
        ],
    )

    if rapport == "Q1 - Stats par département":
        query = """
        SELECT 
            d.DepartmentID,
            d.Name AS DepartmentName,
            COUNT(DISTINCT s.StudentID)   AS NbStudents,
            COUNT(DISTINCT p.ProfessorID) AS NbProfessors,
            COUNT(DISTINCT c.CourseID)    AS NbCourses,
            AVG(CAST(c.Credits AS FLOAT)) AS AvgCredits,
            AVG(CAST(e.Grade  AS FLOAT))  AS AvgGrade
        FROM Departments d
        LEFT JOIN Courses     c ON c.DepartmentID = d.DepartmentID
        LEFT JOIN Enrollments e ON e.CourseID     = c.CourseID
        LEFT JOIN Students    s ON s.StudentID    = e.StudentID
        LEFT JOIN Professors  p ON p.DepartmentID = d.DepartmentID
        GROUP BY d.DepartmentID, d.Name
        ORDER BY d.Name;
        """
        df = run_select(query)
        st.subheader("Q1 – Statistiques globales par département")
        st.dataframe(df)

    elif rapport == "Q2 - Classement étudiants par département":
        query = """
        WITH StudentAvg AS (
            SELECT 
                s.StudentID,
                s.Name           AS StudentName,
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
        SELECT 
            DepartmentID,
            StudentID,
            StudentName,
            AvgGrade,
            NbCourses,
            RankInDept
        FROM StudentRank
        ORDER BY DepartmentID, RankInDept, StudentName;
        """
        df = run_select(query)
        st.subheader("Q2 – Classement des étudiants par département")
        st.dataframe(df)

    elif rapport == "Q3 - PIVOT crédits par département":
        query = """
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
        ) AS src
        PIVOT (
            COUNT(Credits) FOR Credits IN ([1],[3],[6],[8])
        ) AS p
        ORDER BY DepartmentName;
        """
        df = run_select(query)
        st.subheader("Q3 – Répartition des cours par crédits (PIVOT 1/3/6/8)")
        st.dataframe(df)

    elif rapport == "Q4 - Top 5 cours par moyenne de note":
        query = """
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
        HAVING COUNT(*) >= 3
        ORDER BY AvgGrade DESC;
        """
        df = run_select(query)
        st.subheader("Q4 – Top 5 des cours par moyenne de note (min 3 inscriptions)")
        st.dataframe(df)


# SECTION 3 : OPÉRATIONS INSCRIPTIONS (TASK B)
elif section == "Opérations inscriptions (Task B)":
    st.title("Opérations d'inscriptions (Task B)")

    # --------- Formulaire d'inscription ----------
    st.subheader("Inscrire un étudiant à un cours")

    with st.form("add_enrollment_form"):
        student_id = st.number_input("StudentID", min_value=1, step=1)
        course_id = st.number_input("CourseID", min_value=1, step=1)
        semester = st.number_input("Semester", min_value=1, max_value=4, step=1)
        submitted = st.form_submit_button("Inscrire (sp_AddEnrollment)")

        if submitted:
            err = run_non_query(
                "EXEC dbo.sp_AddEnrollment @StudentID=?, @CourseID=?, @Semester=?;",
                [int(student_id), int(course_id), int(semester)],
            )
            if err:
                st.error(f"Erreur lors de l'inscription : {err}")
            else:
                st.success("Inscription réalisée avec succès ")

    # --------- Formulaire de désinscription ----------
    st.subheader("Désinscrire un étudiant d'un cours")

    with st.form("remove_enrollment_form"):
        student_id_rm = st.number_input("StudentID (remove)", min_value=1, step=1)
        course_id_rm = st.number_input("CourseID (remove)", min_value=1, step=1)
        semester_rm = st.number_input("Semester (remove)", min_value=1, max_value=4, step=1)
        submitted_rm = st.form_submit_button("Désinscrire (sp_RemoveEnrollment)")

        if submitted_rm:
            err = run_non_query(
                "EXEC dbo.sp_RemoveEnrollment @StudentID=?, @CourseID=?, @Semester=?;",
                [int(student_id_rm), int(course_id_rm), int(semester_rm)],
            )
            if err:
                st.error(f"Erreur lors de la désinscription : {err}")
            else:
                st.success("Désinscription réalisée avec succès ")

    # --------- Journal d'audit ----------
    st.subheader("Journal des opérations (EnrollmentAudit)")

    if st.button("Voir les 50 dernières opérations d'audit"):
        try:
            df_audit = run_select(
                "SELECT TOP 50 * FROM EnrollmentAudit ORDER BY AuditID DESC;"
            )
            st.dataframe(df_audit)
        except Exception as e:
            st.error(f"Erreur lors de la lecture de EnrollmentAudit : {e}")



# SECTION 4 : MONITORING (TASK B)
elif section == "Monitoring (Task B)":
    st.title("Monitoring (Task B)")

    st.write("Requêtes de monitoring basées sur les DMV de SQL Server.")

    mon_choice = st.selectbox(
        "Choisir une vue de monitoring",
        [
            "M1 - Utilisation des index",
            "M2 - Requêtes actives",
            "M3 - Principales attentes (waits)",
        ],
    )

    if mon_choice == "M1 - Utilisation des index":
        query = """
        SELECT 
            DB_NAME(s.database_id)     AS db_name,
            OBJECT_NAME(s.[object_id]) AS table_name,
            i.name                     AS index_name,
            s.user_seeks,
            s.user_scans,
            s.user_lookups,
            s.user_updates
        FROM sys.dm_db_index_usage_stats s
        JOIN sys.indexes i
          ON i.[object_id] = s.[object_id]
         AND i.index_id     = s.index_id
        WHERE s.database_id = DB_ID()
        ORDER BY (s.user_seeks + s.user_scans + s.user_lookups) DESC;
        """
        df = run_select(query)
        st.subheader("M1 – Utilisation des index")
        st.dataframe(df)

    elif mon_choice == "M2 - Requêtes actives":
        query = """
        SELECT 
            r.session_id,
            s.login_name,
            s.host_name,
            r.status,
            r.command,
            r.cpu_time,
            r.total_elapsed_time,
            DB_NAME(r.database_id) AS db_name,
            SUBSTRING(
                t.text,
                r.statement_start_offset/2 + 1,
                (CASE WHEN r.statement_end_offset = -1 
                      THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2
                      ELSE r.statement_end_offset END - r.statement_start_offset
                )/2 + 1
            ) AS running_query
        FROM sys.dm_exec_requests r
        JOIN sys.dm_exec_sessions s
          ON r.session_id = s.session_id
        CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
        WHERE r.session_id <> @@SPID
          AND r.database_id = DB_ID()
        ORDER BY r.total_elapsed_time DESC;
        """
        df = run_select(query)
        st.subheader("M2 – Requêtes actives sur la base")
        st.dataframe(df)

    elif mon_choice == "M3 - Principales attentes (waits)":
        query = """
        SELECT TOP 20
            wait_type,
            wait_time_ms,
            signal_wait_time_ms,
            wait_time_ms - signal_wait_time_ms AS resource_wait_ms
        FROM sys.dm_os_wait_stats
        WHERE wait_type NOT LIKE 'SLEEP%'
        ORDER BY wait_time_ms DESC;
        """
        df = run_select(query)
        st.subheader("M3 – Principales attentes (wait stats) sur l'instance")
        st.dataframe(df)


# SECTION 5 : SCRIPTS SQL (MAINTENANCE)
elif section == "Scripts SQL (maintenance)":
    st.title("Scripts SQL (maintenance)")

    st.markdown(
        "Ici tu peux exécuter directement les scripts `.sql` du dossier **sql/** :  \n"
        "- création / suppression des tables  \n"
        "- insertion des données (Avec bruits) \n"
        "- nettoyage (Task A)  \n"
        "- procédures & triggers (Task B)"
    )

    col1, col2 = st.columns(2)

    with col1:
        if st.button("Créer les tables (create_tables.sql)"):
            try:
                run_sql_script(os.path.join(SQL_DIR, "create_tables.sql"))
                st.success("create_tables.sql exécuté ")
            except Exception as e:
                st.error(f"Erreur : {e}")

        if st.button("Insérer les données (insert_data.sql)"):
            try:
                run_sql_script(os.path.join(SQL_DIR, "insert_data.sql"))
                st.success("insert_data.sql exécuté ")
            except Exception as e:
                st.error(f"Erreur : {e}")

        if st.button("Nettoyage Task A (Task_A_cleaning.sql)"):
            try:
                run_sql_script(os.path.join(SQL_DIR, "Task_A_cleaning.sql"))
                st.success("Task_A_cleaning.sql exécuté ")
            except Exception as e:
                st.error(f"Erreur : {e}")

    with col2:
        if st.button("Procédures & triggers Task B (procedures_triggers_transactions.sql)"):
            try:
                run_sql_script(os.path.join(SQL_DIR, "procedures_triggers_transactions.sql"))
                st.success("procedures_triggers_transactions.sql exécuté ")
            except Exception as e:
                st.error(f"Erreur : {e}")

        if st.button("Supprimer toutes les tables (DropTables.sql)"):
            try:
                run_sql_script(os.path.join(SQL_DIR, "DropTables.sql"))
                st.success("DropTables.sql exécuté  (toutes les tables ont été supprimées)")
            except Exception as e:
                st.error(f"Erreur : {e}")

    st.info(
        " Attention : ces scripts modifient directement la base (création / suppression / "
        "insertion / nettoyage). À utiliser avec précaution."
    )
