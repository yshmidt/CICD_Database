-- =============================================
-- Author:		Mahesh B
-- Create date: 11/2/2018
-- Description:	Updated the Account Number 
-- Nitesh B 8/20/2019 : Update values of Status,Validation,Message
-- =============================================
CREATE PROCEDURE [dbo].[UpdateInvtAccNumber] 
	-- Add the parameters for the stored procedure here
	@importId UNIQUEIDENTIFIER,     
	@accountNo nvarchar(MAX)    
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @Fieldid NVARCHAR(Max);

SELECT @Fieldid = FieldDefId FROM ImportFieldDefinitions WHERE FieldName = 'AccountNo' AND  Moduleid IN (SELECT ModuleId FROM MnxModule WHERE FilePath = 'InventoryUpload' AND ModuleDesc='MnxM_Upload')  
-- Nitesh B 8/20/2019 : Update values of Status,Validation,Message
UPDATE ImportInvtFields set Original=@accountNo,Adjusted=@accountNo,[Status]='i00white',[Validation]='',[Message]=''  WHERE FkFieldDefId=@Fieldid AND FkImportId= @importId  

END