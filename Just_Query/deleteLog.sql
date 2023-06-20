USE 
----1
SUEN4
GO
-- Truncate the log by changing the database recovery model to SIMPLE.
ALTER DATABASE 
----2
SUEN4
SET RECOVERY SIMPLE;
GO
-- Shrink the truncated log file to 1 MB.
DBCC SHRINKFILE (
----3
suen_log, 1
);  -- here 2 is the file ID for trasaction log file,you can also mention the log file name (dbname_log)
GO
-- Reset the database recovery model.
ALTER DATABASE
----4
SUEN4
SET RECOVERY FULL;
GO

Check for Shrink
_log (only)
C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA
