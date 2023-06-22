IF (object_id('tempdb.dbo.#CreateSPs','U') IS NOT NULL) DROP TABLE #CreateSPs
create table #CreateSPs(SchName varchar(100), objName varchar(200), objType varchar(200), Code nvarchar(max)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateSPs
SELECT ss.[name], o.[name], o.[type_desc], sm.[definition]  
  FROM sys.sql_modules AS sm
  JOIN sys.objects AS o  ON sm.object_id = o.object_id  
  JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id   
WHERE o.type='P'