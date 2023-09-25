--set nocount on
IF (OBJECT_ID(N'TempDB..#Synapse_Unsupported','U') IS NOT NULL)
DROP TABLE #Synapse_Unsupported
GO
CREATE TABLE #Synapse_Unsupported with(distribution=Round_Robin,heap) AS
SELECT 'Triggers' ExprName,'TRIGGER ' ExprCode UNION ALL 
SELECT 'XML',' XML 'UNION ALL 
SELECT 'JSON',' JSON 'UNION ALL 
SELECT 'MATCH',' MATCH'UNION ALL 
SELECT 'Cursor',' CURSOR 'UNION ALL 
SELECT 'Text Data Type',' TEXT 'UNION ALL 
SELECT 'Image Data Type',' IMAGE 'UNION ALL 
SELECT 'HierachyId Data Type',' HIERARCHYID 'UNION ALL 
SELECT 'Row Version Data Type',' ROWVERSION 'UNION ALL 
SELECT 'SQL Variant Data Type',' SQL_VARIANT 'UNION ALL 
SELECT 'Choose Function',' CHOOSE 'UNION ALL 
SELECT 'Logical If',' IIF 'UNION ALL 
SELECT 'Parse Function',' PARSE 'UNION ALL 
SELECT 'String Escape Function',' STRING_ESCAPE 'UNION ALL 
SELECT 'Translate Function',' TRANSLATE 'UNION ALL 
SELECT 'OpenXML Function',' OPENXML 'UNION ALL 
SELECT 'Open Data Source Function',' OPENDATASOURCE 'UNION ALL 
SELECT 'Open Query Function',' OPENQUERY 'UNION ALL 
SELECT 'Open Rowset Function',' OPENROWSET 'UNION ALL 
SELECT 'Check Sum Agg Function',' CHECKSUM_AGG 'UNION ALL 
SELECT 'Grouping Id Function',' GROUPING_ID 'UNION ALL 
SELECT 'Continue Statement',' CONTINUE'UNION ALL 
SELECT 'GOTO Statement',' GOTO 'UNION ALL 
SELECT 'RETURN Statement',' RETURN 'UNION ALL 
SELECT 'USE Statement',' USE 'UNION ALL 
SELECT 'WaitFor Statement',' WAITFOR 'UNION ALL 
SELECT 'Not Greater Than Operator','!>'UNION ALL 
SELECT 'Not Less Than Operator','!<'UNION ALL 
SELECT 'NText Data Type','NTEXT 'UNION ALL 
SELECT 'Geometry Data Type',' GEOMETRY 'UNION ALL 
SELECT 'Geography Data Type',' GEOGRAPHY 'UNION ALL 
SELECT 'filestream',' FILESTREAM 'UNION ALL 
SELECT 'FileTable',' FILETABLE'UNION ALL 
SELECT 'Memory Optimized Tables','MEMORY_OPTIMIZED 'UNION ALL 
SELECT 'Full Text Search','FULLTEXT 'UNION ALL 
SELECT 'Table Definition','HASH'UNION ALL 
SELECT 'Table Definition','REPLICATE'UNION ALL 
SELECT 'Table Definition','ROUND_ROBIN'UNION ALL 
SELECT 'Table Definition','PARTITION'UNION ALL 
SELECT 'Table Definition','COLUMNSTORE INDEX'UNION ALL 
SELECT 'Table Definition','CLUSTERED INDEX'UNION ALL 
SELECT 'Table Definition','NONCLUSTERED INDEX'UNION ALL 
SELECT 'Table Definition',' IDENTITY'UNION ALL 
SELECT 'Row Count','ROWCOUNT'

GO
--Create Procedure CheckForUnsupportedCode as
SELECT ss.[name] SchemaName, o.[name] SPName,x.[value] CodeToReview,c.ExprName CodeCategory,c.ExprCode CodeKeyWord
  FROM sys.sql_modules AS sm
 INNER JOIN sys.objects AS o  ON sm.object_id = o.object_id  
 INNER JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id   
 CROSS APPLY STRING_SPLIT(sm.[definition], char(13)) x
 INNER JOIN #Synapse_Unsupported c ON UPPER(x.value) like Upper(concat('%',c.ExprCode,'%'))
 WHERE o.type='P' AND ss.[name] NOT IN ('INFORMATION_SCHEMA','sys','sysdiag','migration')
 GROUP BY ss.[name], o.[name],x.[value],c.ExprName,c.ExprCode
