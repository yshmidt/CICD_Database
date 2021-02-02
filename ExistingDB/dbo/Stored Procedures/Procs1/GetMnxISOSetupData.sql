-- =============================================
-- Author:Sachin B
-- Create date: <05/20/2019>
-- Description:	Get the MnxISOSetup Table Data
-- [GetMnxISOSetupData]
-- =============================================
CREATE PROC [GetMnxISOSetupData]

AS
BEGIN
    SET NOCOUNT ON;
	SELECT ISOServerId,[dbo].[fn_GetDecryptedValue] (ISOServerAPI) AS ISOServerAPI,CreatedDate FROM MnxISOSetup
END