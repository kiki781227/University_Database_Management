USE Kiady;  
GO

/* ============================================================
   M1. UTILISATION DES INDEX
   - Objectif : voir quels index sont vraiment utilisés
   - Utilise : sys.dm_db_index_usage_stats + sys.indexes
   ============================================================ */

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
GO


/* ============================================================
   M2. SESSIONS / REQUÊTES ACTIVES (MONITORING TEMPS RÉEL)
   - Objectif : voir les requêtes en cours, leur durée, l'état
   - Utilise : sys.dm_exec_requests + sys.dm_exec_sessions
   ============================================================ */

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
WHERE r.session_id <> @@SPID          -- exclure ta propre session
  AND r.database_id = DB_ID()        -- limiter à ta base
ORDER BY r.total_elapsed_time DESC;
GO


/* ============================================================
   M3. PRINCIPALES ATTENTES (WAITS) SUR L'INSTANCE
   - Objectif : voir les types d'attente qui dominent
   - Utilise : sys.dm_os_wait_stats
   ============================================================ */

SELECT TOP 20
    wait_type,
    wait_time_ms,
    signal_wait_time_ms,
    wait_time_ms - signal_wait_time_ms AS resource_wait_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE 'SLEEP%'  -- on enlève les waits "normaux"
ORDER BY wait_time_ms DESC;
GO


