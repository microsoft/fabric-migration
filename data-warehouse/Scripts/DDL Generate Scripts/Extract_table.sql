IF (object_id(N'migration.SynapseMigration_ExtractAllDDL','P') IS NOT NULL) DROP PROC migration.SynapseMigration_ExtractAllDDL
GO
Create PROCEDURE migration.SynapseMigration_ExtractAllDDL as
BEGIN
/*
    Extract Table Definitions
*/
IF (object_id('tempdb.dbo.#tbl','U') IS NOT NULL) DROP TABLE #tbl
create table #tbl with(distribution=round_robin,heap) as
select tbl.object_id,sc.name SchName, tbl.name tblName , c.column_id colid, c.name colname, t.name as coltype, c.max_length colmaxlength, c.precision colprecision,
    c.scale colscale, c.is_nullable colnullable, c.collation_name
from sys.columns c
    join sys.tables tbl on tbl.object_id=c.object_id
    join sys.types t on t.user_type_id = c.user_type_id
	inner join sys.schemas sc on  tbl.schema_id=sc.schema_id
    left join sys.default_constraints dc on c.default_object_id =dc.object_id and c.object_id =dc.parent_object_id;
/*
    Extract Table Constraints
*/
IF (object_id('tempdb.dbo.#tbl_constr','U') IS NOT NULL) DROP TABLE #tbl_constr
create table #tbl_constr with(distribution=round_robin,heap) as
SELECT ic.[object_id]
      ,ic.[column_id]
      ,kc.name 
	  ,kc.type_desc
	  ,kc.is_enforced
	  ,c.name ColName
      , c.is_nullable
	  , null definition
  FROM [sys].[index_columns] ic
  inner join [sys].[key_constraints] kc on kc.parent_object_id=ic.object_id and kc.unique_index_id=ic.index_id
  inner join [sys].[default_constraints] dc on kc.parent_object_id=dc.parent_object_id 
  inner join sys.columns c on c.column_id=ic.column_id and c.object_id=ic.object_id
UNION ALL
SELECT kc.[parent_object_id] object_id
	  ,kc.[parent_column_id] column_id
      ,kc.[name] kcName
      ,kc.[type_desc]
	  ,null is_enforced
      ,c.name colName
	  ,c.is_nullable
      ,kc.[definition]
  FROM [sys].[default_constraints] kc
  inner join sys.columns c on c.column_id=kc.parent_column_id and c.object_id=kc.parent_object_id;

/*
    Join Data Set For type mapping
*/
IF (object_id('tempdb.dbo.#tbl_fin','U') IS NOT NULL) DROP TABLE #tbl_fin;
create table #tbl_fin with(distribution=round_robin,heap) as
select t.*, tc.type_desc, tc.is_enforced, tc.definition from dbo.#tbl t
left join dbo.#tbl_constr tc on t.object_id=tc.object_id and t.colid=tc.column_id;

-- /*
-- Category	               Supported data types
-- ----------------------- --------------------
-- Exact numerics          bit
--                         bigint
--                         int
--                         smallint
--                         decimal
--                         numeric
-- Approximate numerics	   float
--                         real
-- Date and time	       date
--                         datetime2
--                         time
-- Character strings	   char
--                         varchar
-- Binary strings	       varbinary
--                         uniqueidentifer

-- Unsupported data type	Alternatives available
-- ------------------------ ----------------------
-- money/smallmoney	        decimal
-- datetime/smalldatetime	datetime2.
-- nchar/nvarchar	        char and varchar respectively
-- text/ntext	            varchar.
-- image	                varbinary.

-- Type Mapping
-- -----------------------
-- bit              bit
-- bigint           bigint
-- int              int
-- smallint         smalint
-- decimal          decimal(1..38,1..38)
-- numeric          numeric(p,s)
-- float            float
-- real             real
-- date             date
-- datetime2        datetime2(0..6)
-- time             time(0..6)
-- char             char(1..8000)
-- varchar          varchar(1..8000)
-- varbinary        varbinary
-- binary           varbinary
-- uniqueidentifer  uniqueidentifer
-- money	        decimal(1..38,1..38)
-- smallmoney	    decimal(1..38,1..38)
-- smalldatetime    datetime2(0..6)
-- datetime	        datetime2(0..6)
-- nchar	        char(1..8000)
-- nvarchar	        varchar(1..8000)
-- text             varchar(1..8000)
-- ntext            varchar(1..8000)
-- image	        varbinary(1..8000)
-- */
IF (object_id('tempdb.dbo.#tbl_Defs','U') IS NOT NULL) DROP TABLE #tbl_Defs
create table #tbl_Defs with(distribution=round_robin,heap) as
select SchName
            ,tblName
            ,'['+colname+']' as colname
            ,colid
            ,CASE WHEN type_desc = 'UNIQUE_CONSTRAINT' THEN CONCAT('['+colname+']',' ',NewTypeDef, ' ', colnullable,' /*UNIQUE',case when is_enforced=0 THEN ' NOT ENFORCED*/' END)
                  WHEN type_desc = 'PRIMARY_KEY_CONSTRAINT' THEN CONCAT('['+colname+']',' ',NewTypeDef,' ', colnullable,' /*PRIMARY KEY NONCLUSTERED',case when is_enforced=0 THEN ' NOT ENFORCED' END, '*/')
                  WHEN type_desc = 'DEFAULT_CONSTRAINT' THEN CONCAT('['+colname+']',' ',NewTypeDef,' ',colnullable,' /*DEFAULT',definition,'*/')
             ELSE CONCAT('['+colname+']',' ',NewTypeDef,' ',colnullable) end NewColDef
from(
SELECT  top 1000000000 SchName
            ,tblName
            ,colname
            ,colid
            ,coltype
            ,case when colnullable = 1 THEN cast('NULL' as varchar) else cast('NOT NULL' as varchar) END colnullable
            ,CASE WHEN  coltype IN('numeric','decimal') THEN CONCAT(coltype,'(',colprecision,',',colscale,')')
                  WHEN  coltype IN('money','smallmoney') THEN CONCAT('decimal','(',colprecision,',',colscale,')')
                  WHEN  coltype in('smalldatetime','datetime','datetime2','datetimeoffset') THEN CONCAT('datetime2','(',case when colscale >6 then 6 else colscale end,')')
                  WHEN  coltype IN('time') THEN CONCAT(coltype,'(',case when colscale > 6 then 6 else colscale end,')')
                  WHEN  coltype IN('binary','varbinary','image') THEN 'varbinary'
                  when (coltype IN('char','varchar','text','ntext') and colmaxlength = -1) THEN CONCAT(coltype,'(8000)')
                  when (coltype IN('char','varchar','text') and colmaxlength != -1) THEN CONCAT(coltype,'(',colmaxlength,')')
                  when (coltype IN('ntext') and colmaxlength != -1) THEN CONCAT(coltype,'(',colmaxlength/2,')')
                  when (coltype IN('sysname')) THEN CONCAT('varchar','(8000)')
                  when (coltype IN('nchar') and colmaxlength = -1) THEN CONCAT('char','(8000)')
                  when (coltype IN('nvarchar') and colmaxlength = -1) THEN CONCAT('varchar','(8000)')

                  when (coltype IN('nchar') and colmaxlength != -1) THEN CONCAT('char','(',colmaxlength/2,')')
                  when (coltype IN('nvarchar') and colmaxlength != -1) THEN CONCAT('varchar','(',colmaxlength/2,')')
                  
                  WHEN  coltype IN('tinyint') THEN 'smallint'

            ELSE coltype END NewTypeDef
            ,type_desc
            ,is_enforced
            ,definition
        from #tbl_fin
        order by colid
) a;

DECLARE @STR_AGG_Var AS NVARCHAR(MAX)
SET @STR_AGG_Var = CAST(', ' AS NVARCHAR(MAX))

IF (object_id('tempdb.dbo.#tbl_FinalScript','U') IS NOT NULL) DROP TABLE #tbl_FinalScript;
create table #tbl_FinalScript (SchName nvarchar(200), objName varchar(200), Script nvarchar(max), DropStatement VARCHAR(1000)) with(distribution=round_robin,heap);
INSERT INTO #tbl_FinalScript

select SchName,tblName, CAST(DDLScript AS NVARCHAR(MAX)) as Script, 'IF (object_id('''+ SchName + '.' + tblName + ''',''U'') IS NOT NULL) DROP TABLE ['+ SchName + '].[' + tblName +'];' as DropStatement
FROM (
select SchName,tblName,CAST(concat(CAST('CREATE TABLE [' AS NVARCHAR(MAX)),CAST(SchName AS NVARCHAR(MAX)),CAST('].[' AS NVARCHAR(MAX)),CAST(tblName AS NVARCHAR(MAX)),
            CAST('](' AS NVARCHAR(MAX)) ,CAST(STRING_AGG (CONVERT(NVARCHAR(max),NewColDef),', ') AS NVARCHAR(MAX))
              ,CAST(')' AS NVARCHAR(MAX))) AS NVARCHAR(MAX)) DDLScript
from #tbl_Defs t
group by SchName,tblName
UNION ALL
SELECT * from (
select SchName
            ,tblName
            ,CASE WHEN type_desc = 'UNIQUE_CONSTRAINT' 
                       THEN CONCAT('ALTER TABLE ',SchName,'.',tblName,' ADD CONSTRAINT ConstrUnique',tblName,' UNIQUE NONCLUSTERED(',colname,') NOT ENFORCED')
                  WHEN type_desc = 'PRIMARY_KEY_CONSTRAINT' 
                       THEN CONCAT('ALTER TABLE ',SchName,'.',tblName,' ADD CONSTRAINT ConstrPK',tblName,' PRIMARY KEY NONCLUSTERED(',colname,') NOT ENFORCED')
                  WHEN type_desc = 'DEFAULT_CONSTRAINT' 
                       THEN CONCAT('ALTER TABLE ',SchName,'.',tblName,' ADD DEFAULT ',replace(replace(definition,'))',')'),'((','('),' FOR ',colname)
             end NewConstraintDef
from(
SELECT  top 1000000000 SchName
            ,tblName
            ,'['+colname+']' as colname
            ,colid
            ,coltype
            ,case when colnullable = 1 THEN cast('NULL' as varchar) else cast('NOT NULL' as varchar) END colnullable
            ,CASE WHEN  coltype IN('numeric','decimal') THEN CONCAT(coltype,'(',colprecision,',',colscale,')')
                  WHEN  coltype IN('money','smallmoney') THEN CONCAT('decimal','(',colprecision,',',colscale,')')
                  WHEN  coltype in('smalldatetime','datetime','datetime2','datetimeoffset') THEN CONCAT('datetime2','(',case when colscale >6 then 6 else colscale end,')')
                  WHEN  coltype IN('time') THEN CONCAT(coltype,'(',case when colscale > 6 then 6 else colscale end,')')
                  WHEN  coltype IN('binary','varbinary','image') THEN 'varbinary'
                  when (coltype IN('char','varchar','text','ntext') and colmaxlength = -1) THEN CONCAT(coltype,'(8000)')
                  when (coltype IN('char','varchar','text') and colmaxlength != -1) THEN CONCAT(coltype,'(',colmaxlength,')')
                  when (coltype IN('ntext') and colmaxlength != -1) THEN CONCAT(coltype,'(',colmaxlength/2,')')
                  when (coltype IN('sysname')) THEN CONCAT('varchar','(8000)')
                  when (coltype IN('nchar') and colmaxlength = -1) THEN CONCAT('char','(8000)')
                  when (coltype IN('nvarchar') and colmaxlength = -1) THEN CONCAT('varchar','(8000)')

                  when (coltype IN('nchar') and colmaxlength != -1) THEN CONCAT('char','(',colmaxlength/2,')')
                  when (coltype IN('nvarchar') and colmaxlength != -1) THEN CONCAT('varchar','(',colmaxlength/2,')')
                  
                  WHEN  coltype IN('tinyint') THEN 'smallint'
            ELSE coltype END NewTypeDef
            ,type_desc
            ,is_enforced
            ,definition
        from #tbl_fin
        order by colid
) a
) b
where NewConstraintDef is not null
) c;

select * from #tbl_FinalScript where schName NOT IN ('INFORMATION_SCHEMA','sys','sysdiag','migration');

END
-- --Next Steps:
--     DONE - Build the create TABLE statements for farbic
--     DONE - create the CETAS statements per table to export data
--     - Build script to create the schemas in Fabric
    --     - Build script to extract views, procedures and functions
--     - Generate COPY INTO statements to load to Fabric
--     - create a process to deploy the tables in fabric
--     - Create shortcut from OneLake to Gen2 DataLake
--     - create a process to load files to OL and Load tables?

