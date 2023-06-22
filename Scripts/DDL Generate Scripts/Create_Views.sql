IF (object_id(N'SynapseMigration_ExtractAllViews','P') IS NOT NULL) DROP PROC SynapseMigration_ExtractAllViews
GO
Create PROCEDURE SynapseMigration_ExtractAllViews as
BEGIN
IF (object_id('tempdb.dbo.#CreateViews','U') IS NOT NULL) DROP TABLE #CreateViews
CREATE TABLE #CreateViews(SchName varchar(100), objName varchar(200), objType varchar(200), Code nvarchar(max)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateViews
SELECT ss.[name], o.[name], o.[type_desc], sm.[definition]  
  FROM sys.sql_modules AS sm
  JOIN sys.objects AS o  ON sm.object_id = o.object_id  
  JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id  
WHERE o.type='V' AND sm.definition NOT LIKE 'CREATE MATERIALIZED VIEW%';

Select * from #CreateViews;
END