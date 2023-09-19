IF (object_id(N'migration.SynapseMigration_ExtractAllFunctions','P') IS NOT NULL) DROP PROC migration.SynapseMigration_ExtractAllFunctions
GO
Create PROCEDURE migration.SynapseMigration_ExtractAllFunctions as
BEGIN
IF (object_id('tempdb.dbo.#CreateFunctions','U') IS NOT NULL) DROP TABLE #CreateFunctions
CREATE TABLE #CreateFunctions(SchName varchar(100), objName varchar(200), Script nvarchar(max), DropStatement VARCHAR(1000)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateFunctions
SELECT ss.[name], o.[name], CAST(sm.[definition] AS nvarchar(max)) AS Script
  , 'DROP FUNCTION IF EXISTS ['+ ss.name + '].[' + o.[name] +'];' As DropStatement
  FROM sys.sql_modules AS sm
  JOIN sys.objects AS o  ON sm.object_id = o.object_id  
  JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id  
 WHERE o.type='FN' AND ss.[name] NOT IN ('INFORMATION_SCHEMA','sys','sysdiag','migration');

 SELECT * from #CreateFunctions;
 END