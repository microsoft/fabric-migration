declare @tbl as VARCHAR(100)='dbo.magicTable';




IF (object_id('tempdb.dbo.#tbl','U') IS NOT NULL) DROP TABLE #tbl

create table #tbl with(distribution=round_robin,heap) as

select tbl.object_id,sc.name SchName, tbl.name tblName , c.column_id colid, c.name colname, t.name as coltype, c.max_length colmaxlength, c.precision colprecision,

    c.scale colscale, c.is_nullable colnullable, c.collation_name

from sys.columns c

    join sys.tables tbl on tbl.object_id=c.object_id

    join sys.pdw_column_distribution_properties d on c.object_id = d.object_id and c.column_id = d.column_id

    join sys.types t on t.user_type_id = c.user_type_id

    inner join sys.schemas sc on  tbl.schema_id=sc.schema_id

    left join sys.default_constraints dc on c.default_object_id =dc.object_id and c.object_id =dc.parent_object_id

-- where c.object_id = object_id(@tbl)

;

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

--   where kc.parent_object_id=object_id(@tbl,'U')

  union all

SELECT kc.[parent_object_id] object_id

      ,kc.[parent_column_id] column_id

      ,kc.[name] kcName

      ,kc.[type_desc]

      ,null is_enforced

      ,c.name colName

      ,c.is_nullable

      ,kc.[definition]

  FROM [sys].[default_constraints] kc

  inner join sys.columns c on c.column_id=kc.parent_column_id and c.object_id=kc.parent_object_id

    -- where kc.parent_object_id=object_id(@tbl,'U')

;

-- select * from dbo.#tbl order by tblName,colid

-- select * from dbo.#tbl_constr order by tblName,colid

--  select * from dbo.#tbl_fin order by tblName,colid




IF (object_id('tempdb.dbo.#tbl_fin','U') IS NOT NULL) DROP TABLE #tbl_fin

create table #tbl_fin with(distribution=round_robin,heap) as

select t.*, tc.type_desc, tc.is_enforced, tc.definition from dbo.#tbl t

left join dbo.#tbl_constr tc on t.object_id=tc.object_id and t.colid=tc.column_id ;





IF (object_id('tempdb.dbo.#tbl_Defs','U') IS NOT NULL) DROP TABLE #tbl_Defs

create table #tbl_Defs with(distribution=round_robin,heap) as

SELECT SchName,tblName,colid,colName, case WHEN coltype in('money', 'smallmoney') then 'decimal'

       WHEN coltype in('datetime','smalldatetime') then 'datetime(2)'

       WHEN coltype in('nvarchar','nchar') then 'varchar'

  ELSE strType1

end as FabType,colnullable,type_desc,is_enforced,definition

from(

    select SchName,tblName,colid,colName,coltype, case when strType!='x' then concat(coltype,'(',strType,')') ELSE coltype end as strType1,colNullable,type_desc,is_enforced,definition

    from (

        SELECT

            SchName

            ,tblName

            ,colname

            , coltype

            , colid

            -- , colprecision

            -- , colscale

            , case when colnullable = 1 THEN cast('NULL' as varchar) else cast('NOT NULL' as varchar) END colnullable

            , CASE  when (coltype = 'binary' or coltype = 'varbinary') and colmaxlength = -1 then cast('max' as varchar)

                    when (coltype = 'char' or coltype = 'varchar' or coltype = 'nchar' or coltype = 'nvarchar') and colmaxlength = -1 then cast('max' as varchar)

                    when (coltype = 'char' or coltype = 'varchar') and colmaxlength != -1 then cast(colmaxlength as varchar)

                    when (coltype = 'nchar' or coltype = 'nvarchar') and colmaxlength != -1 then cast(colmaxlength/2 as varchar)

                    when (coltype = 'float') then 'x'

                    when (coltype = 'datetime2' or coltype = 'datetimeoffset' or coltype = 'time') then cast(colscale as varchar)

                    when (coltype = 'decimal' or coltype = 'numeric') then concat(colprecision,',',colscale)

                    else 'x'

                end as strType

                ,type_desc,is_enforced,definition

        from #tbl_fin

    )a

)b




--GO

-- select * from #tbl_Defs t where t.tblName='MagicTable' order by colid





select concat('CREATE TABLE ',SchName,'.',tblName,'('

              ,STRING_AGG (CONVERT(NVARCHAR(max),concat(colName,' ',FabType,' ',colnullable)),', ')

              ,')')

from #tbl_Defs t

where t.tblName='MagicTable'

group by SchName,tblName