-- =============================================
-- Author:		Satish B
-- Create date: 6/21/2018
-- Description:	Update PO Upload header details
-- Modified Satish B:05/16/2018 Add one parameter @poDate
-- =============================================
 

CREATE PROCEDURE [dbo].[ImportPOHeaderUpdate]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
   ,@poNum varchar(15)
   ,@supName varchar(30)
   ,@buyer varchar(30)
   ,@priority varchar(10)
   ,@confTo varchar(20)
   ,@moduleId char(10) = ''
   ,@lFreightIncl bit=0
   ,@poNote varchar(max)=''
   ,@terms varchar(20)=''
   --Satish B:05/16/2018 Add one parameter @poDate
   ,@poDate date = null
  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @poNumId uniqueidentifier,@supNameId uniqueidentifier,@buyerId uniqueidentifier,@priorityId uniqueidentifier,@confToId uniqueidentifier
	,@lFreightInclId uniqueidentifier,@poNoteId uniqueidentifier,@termsId uniqueidentifier
	
	DECLARE @green varchar(10)='i01green',@sys varchar(10)='01system',@user varchar(10)='03user'
	
	--Get ID values for each field type	
	SELECT @poNumId		= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'PONUM'	AND ModuleId=@moduleId		
	SELECT @supNameId	= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'SUPNAME'	AND ModuleId=@moduleId		
	SELECT @buyerId		= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'BUYER'	AND ModuleId=@moduleId		
	SELECT @priorityId	= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'PRIORITY'	AND ModuleId=@moduleId		
	SELECT @confToId	= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'CONFTO'	AND ModuleId=@moduleId		
	SELECT @lFreightInclId	= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'LFREIGHTINCLUDE'	AND ModuleId=@moduleId	
	SELECT @poNoteId	= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'PONOTE'	AND ModuleId=@moduleId	
	SELECT @termsId	= fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'TERMS'	AND ModuleId=@moduleId
		
	--select fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'BUYER'	AND ModuleId=@moduleId

	--Update fields with new values
	--Update detail fields
	UPDATE ImportPODetails SET adjusted = @poNum,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @poNumId AND fkPOImportId = @importId AND adjusted<>@poNum
	UPDATE ImportPODetails SET adjusted = @supName,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @supNameId AND fkPOImportId= @importId AND adjusted<>@supName
	UPDATE ImportPODetails SET adjusted = @buyer,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @buyerId AND fkPOImportId = @importId AND adjusted<>@buyer
	UPDATE ImportPODetails SET adjusted = @priority,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @priorityId AND fkPOImportId = @importId AND adjusted<>@priority
	UPDATE ImportPODetails SET adjusted = @confTo,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @confToId AND fkPOImportId = @importId AND adjusted<>@confTo
	UPDATE ImportPODetails SET adjusted = cast(@lFreightIncl AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @lFreightInclId AND fkPOImportId = @importId AND adjusted<>cast(@lFreightIncl AS nvarchar(10))
	UPDATE ImportPODetails SET adjusted = @poNote,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @poNoteId AND fkPOImportId = @importId AND adjusted<>@poNote
	UPDATE ImportPODetails SET adjusted = @terms,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @termsId AND fkPOImportId = @importId AND adjusted<>@terms
	

		
	--Update header fields
	UPDATE ImportPOMain SET PONumber = @poNum WHERE POImportId = @importId AND PONumber<>@poNum
	UPDATE ImportPOMain SET Supplier = @supName WHERE POImportId = @importId AND Supplier<>@supName
	UPDATE ImportPOMain SET Buyer = @buyer	WHERE  POImportId = @importId AND Buyer<>@buyer
	UPDATE ImportPOMain SET Priority = @priority WHERE POImportId = @importId AND Priority<>@priority
	UPDATE ImportPOMain SET ConfTo = @confTo WHERE  POImportId = @importId AND ConfTo<>@confTo
	UPDATE ImportPOMain SET LfreightInclude = cast(@lFreightIncl AS nvarchar(10)) WHERE  POImportId = @importId AND ConfTo<>cast(@lFreightIncl AS nvarchar(10))
	UPDATE ImportPOMain SET PONote = @poNote WHERE  POImportId = @importId AND PONote<>@poNote
	UPDATE ImportPOMain SET Terms = @terms WHERE  POImportId = @importId AND Terms<>@terms
	UPDATE ImportPOMain SET PODate = @poDate WHERE  POImportId = @importId AND PODate<>@poDate



	--Recheck Validations
	EXEC ImportPOVldtnCheckValues @importId
END