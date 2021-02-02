
CREATE PROC dbo.sp_TestFindReferences (@fullObjectName VARCHAR(200))
AS
BEGIN
/*	procedures were found on this web site http://www.sqltreeo.com/wp/scripting-dependecies-of-user-defined-table-types/   */
	
    SET NOCOUNT ON

    IF (TYPE_ID (@fullObjectName) IS NULL)
    BEGIN
        RAISERROR ('User-defined table type ''%s'' does not exists. Include full object name with schema.', 16,1, @fullObjectName)
        RETURN
    END;

    WITH sources
    AS
    (
        SELECT ROW_NUMBER() OVER (ORDER BY OBJECT_NAME(m.object_id)) RowId, definition
        FROM sys.sql_expression_dependencies d
        JOIN sys.sql_modules m ON m.object_id = d.referencing_id
        JOIN sys.objects o ON o.object_id = m.object_id
        WHERE referenced_id = TYPE_ID(@fullObjectName)
    )

    SELECT 

        'DROP ' +
            CASE OBJECTPROPERTY(referencing_id, 'IsProcedure')
            WHEN 1 THEN 'PROC '
            ELSE
                CASE
                    WHEN OBJECTPROPERTY(referencing_id, 'IsScalarFunction') = 1 OR OBJECTPROPERTY(referencing_id, 'IsTableFunction') = 1 OR OBJECTPROPERTY(referencing_id, 'IsInlineFunction') = 1 THEN 'FUNCTION '
                    ELSE ''
                END
            END
        + SCHEMA_NAME(o.schema_id) + '.' +
        + OBJECT_NAME(m.object_id)    

    FROM sys.sql_expression_dependencies d
    JOIN sys.sql_modules m ON m.object_id = d.referencing_id
    JOIN sys.objects o ON o.object_id = m.object_id
    WHERE referenced_id = TYPE_ID(@fullObjectName)
    UNION  ALL
    SELECT  'GO'
    UNION  ALL
    SELECT
        CASE
            WHEN number = RowId    THEN DEFINITION
            ELSE 'GO'
        END
     FROM sources s
    JOIN (SELECT DISTINCT number FROM master.dbo.spt_values) n ON n.number BETWEEN RowId AND RowId+1

END
