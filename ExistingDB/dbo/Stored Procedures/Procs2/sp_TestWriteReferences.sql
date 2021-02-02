
-- Invokes ap_FindReferences procedure and writes scripted result to .sql file 
CREATE PROC [dbo].[sp_TestWriteReferences]
@typeToFind VARCHAR(200),@database VARCHAR(200),@outputFile varchar(500)
AS
BEGIN
/*	procedures were found on this web site http://www.sqltreeo.com/wp/scripting-dependecies-of-user-defined-table-types/   */
    DECLARE @sqlCmd VARCHAR(500)
   IF (TYPE_ID (@typeToFind) IS NULL)
    BEGIN
        RAISERROR ('User-defined table type ''%s'' does not exists. Include full object name with schema.', 16,1, @typeToFind)
        RETURN
    END;
    IF @database IS NULL
    BEGIN
      RAISERROR ('No database name was provided.', 16,1, @database)
        RETURN
    END
     IF @outputFile IS NULL
    BEGIN
      RAISERROR ('No output file was provided.', 16,1, @outputFile)
        RETURN
    END
   -- DECLARE @outputFile VARCHAR(500) = 'C:\Development\Manex2Sql\SqlStoredProcFunction\SqlScriptsFromYelena\AutoScript.sql'

    SET @sqlCmd = 'sqlcmd.exe -d '+@database+' -q "EXEC ap_FindReferences '''+ @typeToFind +'''" -o '+ @outputFile +' -h-1 -y0'

    EXEC xp_cmdshell @sqlCmd

END
