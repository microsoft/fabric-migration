IF (object_id(N'SynapseMigration_ExtractAllFunctions','P') IS NOT NULL) DROP PROC SynapseMigration_ExtractAllFunctions
GO
Create PROCEDURE SynapseMigration_ExtractAllFunctions as
BEGIN
IF (object_id('tempdb.dbo.#CreateFunctions','U') IS NOT NULL) DROP TABLE #CreateFunctions
CREATE TABLE #CreateFunctions(SchName varchar(100), objName varchar(200), Script nvarchar(max), DropStatement VARCHAR(1000)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateFunctions
SELECT ss.[name], o.[name], sm.[definition]
  , 'DROP FUNCTION IF EXISTS ['+ ss.name + '].[' + o.[name] +'];' As DropStatement
  FROM sys.sql_modules AS sm
  JOIN sys.objects AS o  ON sm.object_id = o.object_id  
  JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id  
 WHERE o.type='FN';

 SELECT * from #CreateFunctions;
 END