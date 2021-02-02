-- Batch submitted through debugger: 160.7.241.22@SQLEXPRESS,1500.MANEX.sql|670|0|C:\Development\Manex2Sql\SqlStoredProcFunction\ApexSqlScript\ManexNewSecurityTablesAndSP\160.7.241.22@SQLEXPRESS,1500.MANEX.sql
CREATE PROCEDURE dbo.aspnet_Personalization_GetApplicationId (
    @ApplicationName NVARCHAR(256),
    @ApplicationId UNIQUEIDENTIFIER OUT)
AS
BEGIN
    SELECT @ApplicationId = ApplicationId FROM dbo.aspnet_Applications WHERE LOWER(@ApplicationName) = LoweredApplicationName
END
