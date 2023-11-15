IF (object_id(N'migration.SynapseMigration_ExtractSchemas','P') IS NOT NULL) DROP PROC migration.SynapseMigration_ExtractSchemas
GO
Create PROCEDURE migration.SynapseMigration_ExtractSchemas as
BEGIN
IF (object_id('tempdb.dbo.#CreateSchemas','U') IS NOT NULL) DROP TABLE #CreateSchemas
CREATE TABLE #CreateSchemas(SchName varchar(100), Script nvarchar(max), DropStatement VARCHAR(1000)) with(distribution=round_Robin,heap) 
INSERT INTO #CreateSchemas
SELECT ss.[name], 'CREATE SCHEMA '+ ss.[name]+';' as Script
  , 'IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = '''+ss.[name]+''') DROP SCHEMA ['+ ss.[name] + '];' as DropStatement 
  FROM sys.schemas AS ss
  WHERE ss.[name] NOT IN ('INFORMATION_SCHEMA','sys','sysdiag','migration')

 SELECT * from #CreateSchemas;
 END