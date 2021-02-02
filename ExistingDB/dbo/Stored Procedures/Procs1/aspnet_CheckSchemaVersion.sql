-- Batch submitted through debugger: 160.7.241.22@SQLEXPRESS,1500.MANEX.sql|1200|0|C:\Development\Manex2Sql\SqlStoredProcFunction\ApexSqlScript\ManexNewSecurityTablesAndSP\160.7.241.22@SQLEXPRESS,1500.MANEX.sql

CREATE PROCEDURE [dbo].aspnet_CheckSchemaVersion
    @Feature                   nvarchar(128),
    @CompatibleSchemaVersion   nvarchar(128)
AS
BEGIN
    IF (EXISTS( SELECT  *
                FROM    dbo.aspnet_SchemaVersions
                WHERE   Feature = LOWER( @Feature ) AND
                        CompatibleSchemaVersion = @CompatibleSchemaVersion ))
        RETURN 0

    RETURN 1
END
