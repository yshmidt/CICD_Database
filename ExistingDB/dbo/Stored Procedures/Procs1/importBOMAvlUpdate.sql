-- =============================================  
-- Author:  David Sharp  
-- Create date: 5/2/2012  
-- Description: update AVL info  
-- 05/15/2019 Vijay G Add one more parameter as  @preference for order preference of manufacturer
-- =============================================  
CREATE PROCEDURE [dbo].[importBOMAvlUpdate]   
 -- Add the parameters for the stored procedure here  
 @importId uniqueidentifier,   
 @rowId uniqueidentifier,  
 @avlRowId uniqueidentifier,  
 @mfg varchar(50),  
 @mpn varchar(50),  
 @matlType varchar(50),  
 @bom bit,  
 @load bit,  
 @uniqmfgrhd varchar(20),
 -- 05/15/2019 Vijay G Add one more parameter as  @preference for order preference of manufacturer
 @preference varchar(5)
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    -- Check to see if the avlRowId exists  
    DECLARE @user varchar(10)= '03user',@green varchar(10)='i01green'  
    DECLARE @rcount int = 0  
    SELECT @rcount=COUNT(avlrowId) FROM importBOMAvl WHERE avlRowId = @avlRowId AND fkImportId=@importId  
      
    --5/9/2012 David - Removed uniqmfgrhd since it isn't updated in the front.   
    --IF @uniqmfgrhd<>'' SET @load=null  
      
    IF @rcount = 0  
    BEGIN  
	 -- 05/15/2019 Vijay G Add one more parameter as  @preference for order preference of manufacturer
  EXEC [importBOMAvlAdd]@importId,@rowId,@avlRowId,@mfg,@mpn,@matlType,@bom,@load,@uniqmfgrhd,@preference 
    END  
    ELSE  
    BEGIN   
  --If the value changed from the original, mark it green  
  UPDATE i  
   SET i.adjusted = @mfg,i.status=@green,i.validation=@user,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i 
   INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='partMfg' AND i.original<>@mfg  
  UPDATE i  
   SET i.adjusted = @mpn,i.status=@green,i.validation=@user,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i 
   INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='mpn' AND i.original<>@mpn  
  UPDATE i  
   SET i.adjusted = @matlType,i.status=@green,i.validation=@user,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i 
   INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='matlType' AND i.original<>@matlType  
     
	 -- 05/15/2019 Vijay G Add one more parameter as  @preference for order preference of manufacturer
  UPDATE i  
   SET i.adjusted = @preference,i.status=@green,i.validation=@user,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i 
   INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='preference' AND i.original<>@preference  
  --If the value is reverted back to the original, leave the class and validation alone.   
  UPDATE i  
   SET i.adjusted = @mfg,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i
    INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='partMfg' AND i.original=@mfg  
  UPDATE i  
   SET i.adjusted = @mpn,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i
    INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='mpn' AND i.original=@mpn  
  UPDATE i  
   SET i.adjusted = @matlType,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i
    INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='matlType' AND i.original=@matlType  

   -- 05/15/2019 Vijay G Add one more parameter as  @preference for order preference of manufacturer
   UPDATE i  
   SET i.adjusted = @preference,i.bom=@bom,i.[load]=@load  
   FROM importBOMAvl i
    INNER JOIN importBOMFieldDefinitions fd ON i.fkFieldDefId=fd.fieldDefId  
   WHERE fkImportId=@importId AND avlRowId=@avlRowId AND fd.fieldName='preference' AND i.original=@preference  
 END  
   
 EXEC [importBOMVldtnAVLCheckValues] @importId  
END