IF (object_id(N'migration.SynapseMigration_ExtractAllViews','P') IS NOT NULL) DROP PROC migration.SynapseMigration_ExtractAllViews
GO
Create PROCEDURE migration.SynapseMigration_ExtractAllViews as
BEGIN
IF (object_id('tempdb.dbo.#CreateViews','U') IS NOT NULL) DROP TABLE #CreateViews
CREATE TABLE #CreateViews(SchName varchar(100), objName varchar(200), Script nvarchar(max),  DropStatement VARCHAR(1000)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateViews
SELECT ss.[name], o.[name]  
  ,CAST(sm.[definition] AS NVARCHAR(MAX))   AS Script
  ,'IF (object_id('''+ ss.[name] + '.' + o.[name] + ''',''V'') IS NOT NULL) DROP VIEW ['+ ss.name + '].[' + o.[name] +'];' As DropStatement
  FROM sys.sql_modules AS sm
  JOIN sys.objects AS o  ON sm.object_id = o.object_id  
  JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id  
WHERE o.type='V' AND sm.definition NOT LIKE 'CREATE MATERIALIZED VIEW%' AND ss.[name] NOT IN ('INFORMATION_SCHEMA','sys','sysdiag','migration');

SELECT * FROM #CreateViews

END