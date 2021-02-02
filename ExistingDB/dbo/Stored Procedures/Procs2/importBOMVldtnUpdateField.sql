-- =============================================  
-- Author:  David Sharp  
-- Create date: 4/24/2012  
-- Description: updates importBOM values  
-- 01/30/2018 Sachin B Fix the Issue the Part Component Default Warehouse Selection Does Not Apply the Default Warehouse use on the Basis of Part_Class add Parameter fieldName
-- =============================================  
CREATE PROCEDURE [dbo].[importBOMVldtnUpdateField]   
 -- Add the parameters for the stored procedure here  
 @adjusted varchar(MAX),  
 @rcount int,   
 @fieldDefId uniqueidentifier,  
 @importId uniqueidentifier,  
 @messageValue varchar(max)='Value not found',  
 @warn int = 0,  
 @alias varchar(max) = ''  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 DECLARE @default varchar(MAX)  
 DECLARE @white varchar(20)='i00white',@lock varchar(20)='i00lock',@green varchar(20)='i01green',@blue varchar(20)='i03blue',@orange varchar(20)='i04orange',@red varchar(20)='i05red',  
   -- 01/30/2018 Sachin B Fix the Issue the Part Component Default Warehouse Selection Does Not Apply the Default Warehouse use on the Basis of Part_Class add Parameter fieldName
   @sys varchar(20)='01system',@usr varchar(20)='03user',@fieldName VARCHAR(50) 
 --DECLARE @val varchar(10) = '01system'  
 IF @adjusted = ''  
 BEGIN  
  -- do not apply updates to fields already set by the user  
  -- 01/30/2018 Sachin B Fix the Issue the Part Component Default Warehouse Selection Does Not Apply the Default Warehouse use on the Basis of Part_Class add Parameter fieldName
  SELECT @default = [default],@fieldName=[fieldName] FROM importBOMFieldDefinitions WHERE fieldDefId = @fieldDefId  
  IF @default <> '' and  @fieldName<>'warehouse' 
  UPDATE importBOMFields  
   SET [adjusted]=@default ,[status] = @blue,[validation] = @sys, [message] = 'Default Value'  
   WHERE fkImportId = @importId AND fkFieldDefId = @fieldDefId AND adjusted = @adjusted AND [status]<>@green AND [status]<>@lock  
 END  
 ELSE IF @rCount = 0  
  UPDATE importBOMFields  
   SET [status] = @red,[validation] = @sys, [message] = @messageValue  
   WHERE fkImportId = @importId AND fkFieldDefId = @fieldDefId AND adjusted = @adjusted  
 ELSE IF @warn = 1  
  -- do not apply updates to fields already set by the user or the system  
  UPDATE importBOMFields  
   SET [status] = @orange,[validation] = @sys, [message] = @messageValue  
   WHERE fkImportId = @importId AND fkFieldDefId = @fieldDefId AND adjusted = @adjusted AND [status]<>@green AND [status]<>@lock AND [status]<>@blue  
 ELSE IF @adjusted = '%'  
  -- this is a catchall allowing for skipping validation requirements for any given row, the validation sp sets @adjusted to '%' if it should not be validated  
  -- do not apply updates to fields already set by the user or the system  
  UPDATE importBOMFields  
   SET [status] = @white,[validation] = @sys, [message] = ''   
   WHERE fkImportId = @importId AND fkFieldDefId = @fieldDefId AND [status]<>@green AND [status]<>@blue AND [status]<>@lock  
 ELSE IF @alias <> ''  
  -- this is a catchall allowing for skipping validation requirements for any given row, the validation sp sets @adjusted to '%' if it should not be validated  
  -- do not apply updates to fields already set by the user or the system  
  UPDATE importBOMFields  
   SET [status] = @blue,[validation] = @sys, [message] = 'Alias Substitution', adjusted=@adjusted  
   WHERE fkImportId = @importId AND fkFieldDefId = @fieldDefId AND adjusted=@alias AND [status]<>@green AND [status]<>@blue AND [status]<>@lock  
 ELSE  
 BEGIN  
  -- do not apply updates to fields already set by the user or the system  
  UPDATE importBOMFields  
   SET [status] = @white,[validation] = @sys, [message] = ''   
   WHERE fkImportId = @importId AND fkFieldDefId = @fieldDefId AND adjusted = @adjusted AND original=adjusted AND[status]<>@green AND [status]<>@blue AND [status]<>@lock  
  UPDATE importBOMFields  
   SET [status] = @green,[validation] = @sys, [message] = ''   
   WHERE fkImportId = @importId AND fkFieldDefId = @fieldDefId AND original<>@adjusted AND adjusted=@adjusted AND [status]<>@blue AND [status]<>@lock  
 END  
      
END  