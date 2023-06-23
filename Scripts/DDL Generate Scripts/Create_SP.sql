IF (object_id(N'SynapseMigration_ExtractAllSP','P') IS NOT NULL) DROP PROC SynapseMigration_ExtractAllSP
GO
Create PROCEDURE SynapseMigration_ExtractAllSP as
BEGIN
IF (object_id('tempdb.dbo.#CreateSPs','U') IS NOT NULL) DROP TABLE #CreateSPs
create table #CreateSPs(SchName varchar(100), objName varchar(200), Script nvarchar(max), DropStatement VARCHAR(1000)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateSPs
SELECT ss.[name], o.[name], sm.[definition] AS Script,
'IF (object_id('''+ ss.[name] + '.' + o.[name] + ''') IS NOT NULL) DROP PROCEDURE ['+ ss.[name] + '].[' + o.[name] +'];' as DropStatement 
  FROM sys.sql_modules AS sm
  JOIN sys.objects AS o  ON sm.object_id = o.object_id  
  JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id   
WHERE o.type='P';

SELECT * from #CreateSPs
END