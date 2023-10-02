--set nocount on
--DROP TABLE SQL_Unsupported01
CREATE TABLE Synapse_Unsupported(ExprName varchar(200),ExprCode varchar(200))
--select * from Synapse_Unsupported

INSERT INTO Synapse_Unsupported
SELECT 'Triggers','TRIGGER 'UNION ALL 
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
SELECT 'Memory Optimized Tables','MEMORY_OPTIMIZED'UNION ALL 
SELECT 'Full Text Search','FULLTEXT'UNION ALL 
SELECT 'Row Count','ROWCOUNT'
--ADD checks for: Distribution, Partition, indexes

GO
--Create Procedure CheckForUnsupportedCode as
SELECT ss.[name], o.[name],x.[value],c.ExprName,c.ExprCode
  FROM sys.sql_modules AS sm
  INNER JOIN sys.objects AS o  ON sm.object_id = o.object_id  
  INNER JOIN sys.schemas AS ss ON o.schema_id = ss.schema_id   
  CROSS APPLY STRING_SPLIT(sm.[definition], char(13)) x
  INNER JOIN Synapse_Unsupported c on upper(x.value) like Upper(concat('%',c.ExprCode,'%'))
WHERE o.type='P' and ss.[name] NOT IN ('INFORMATION_SCHEMA','sys','sysdiag','migration')
group by ss.[name], o.[name],x.[value],c.ExprName,c.ExprCode

