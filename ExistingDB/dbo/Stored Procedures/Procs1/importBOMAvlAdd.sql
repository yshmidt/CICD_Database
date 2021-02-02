-- =============================================  
-- Author:  David Sharp  
-- Create date: 5/2/2012  
-- Description: add import AVL detail  
-- 05/15/2019 Vijay G Add new one parameter for preference column as @preference varchar(20)='1'
-- =============================================  
CREATE PROCEDURE [dbo].[importBOMAvlAdd]  
 -- Add the parameters for the stored procedure here  
 @importId uniqueidentifier,  
 @rowId uniqueidentifier,  
 @avlRowId uniqueidentifier = null,  
 @mfg varchar(10)='',  
 @mpn varchar(50)='',  
 @matlType varchar(10)='',  
 @bom bit=1,  
 @load bit=1,  
 @uniqmfgrhd varchar(20)='' ,
 -- 05/15/2019 Vijay G Add new one parameter for preference column as @preference varchar(20)='1'
 @preference varchar(20)='1'
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    -- Get highest current itemno for the importId and prepare for auto increment if needed.  
    IF @avlRowId IS NULL SET @avlRowId=NEWID()   
    IF @uniqmfgrhd<>'' AND NOT @uniqmfgrhd IS NULL SET @load=null  
      
    --SET @bom=1  
    --SET @load=1  
      
 INSERT INTO importBOMAVL(fkImportId,fkRowId,fkFieldDefId,avlRowId,adjusted,bom,[load],uniqmfgrhd)  
  SELECT @importId,@rowId,fieldDefId,@avlRowId,CASE WHEN @mfg = '' THEN [default] ELSE RTRIM(@mfg) END,@bom,@load,@uniqmfgrhd  
   FROM importBOMFieldDefinitions WHERE fieldName = 'partMfg'  
  UNION ALL  
  SELECT @importId,@rowId,fieldDefId,@avlRowId,@mpn,@bom,@load,@uniqmfgrhd   
   FROM importBOMFieldDefinitions WHERE fieldName = 'mpn'  
  UNION ALL  
  SELECT @importId,@rowId,fieldDefId,@avlRowId,CASE WHEN @matlType = '' THEN [default] ELSE RTRIM(@matlType) END,@bom,@load,@uniqmfgrhd   
   FROM importBOMFieldDefinitions WHERE fieldName = 'matlType' 
-- 05/15/2019 Vijay G Add new one parameter for preference column as @preference varchar(20)='1'    
   UNION ALL  
  SELECT @importId,@rowId,fieldDefId,@avlRowId,CASE WHEN @preference = '' THEN [default] ELSE RTRIM(@preference) END,@bom,@load,@uniqmfgrhd   
   FROM importBOMFieldDefinitions WHERE fieldName = 'preference'  
   

 EXEC [dbo].importBOMVldtnAVLCheckValues @importId  
END 