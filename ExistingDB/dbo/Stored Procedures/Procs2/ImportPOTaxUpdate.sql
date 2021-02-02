-- =============================================
-- Author:		Satish B
-- Create date: 6/25/2018
-- Description:	Update PO Upload tax detail
-- =============================================


CREATE PROCEDURE [dbo].[ImportPOTaxUpdate]
	-- Add the parameters for the stored procedure here
			@importId uniqueidentifier,@rowId uniqueidentifier,@taxId char(10),@moduleId varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
	-- Insert statements for procedure here
    DECLARE  @taxItemId uniqueidentifier
	
	DECLARE @white varchar(10)='i00white',@lock varchar(10)='i00lock',@green varchar(10)='i01green',@fade varchar(10)='i02fade',
			@none varchar(10)='00none',@sys varchar(10)='01system',@user varchar(10)='03user'
	
	SELECT @taxItemId =fieldDefId FROM ImportFieldDefinitions WHERE fieldName = 'TAXID' AND ModuleId=@moduleId
	
	--Update fields with new values
	UPDATE ImportPOTax SET adjusted = @taxId,[status]='',[validation]=@user,[message]='' 
		   WHERE fkFieldDefId = @taxItemId 
				AND FkRowId = @rowId 
				AND adjusted<>@taxId

	--Recheck Validations
	EXEC ImportPOVldtnCheckValues @importId
END