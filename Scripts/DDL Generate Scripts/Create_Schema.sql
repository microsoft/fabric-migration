IF (object_id(N'SynapseMigration_ExtractSchemas','P') IS NOT NULL) DROP PROC SynapseMigration_ExtractSchemas
GO
Create PROCEDURE SynapseMigration_ExtractSchemas as
BEGIN
IF (object_id('tempdb.dbo.#CreateSchemas','U') IS NOT NULL) DROP TABLE #CreateSchemas
CREATE TABLE #CreateSchemas(SchName varchar(100), Script nvarchar(max), DropStatement VARCHAR(1000)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateSchemas
SELECT ss.[name], 'CREATE SCHEMA '+ ss.[name]+';'
  , 'IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = '''+ss.[name]+''') DROP SCHEMA ['+ ss.[name] + '];' as DropStatement 
  FROM sys.schemas AS ss

 SELECT * from #CreateSchemas;
 END