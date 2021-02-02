-- =============================================      
-- Author:  David Sharp      
-- Create date: 4/18/2012      
-- Description: update records from mass update      
-- 12/17/13 DS added Alias creation      
-- 05/15/2019 Vijay G : Add cursor for update part type of part class    
-- 03/11/2020 Sachin B : Remove the unwanted execution of sp from cursor and added only usable code in the cursor  
-- 04/03/2020 Sachin B : Removed the unwanted execution of sp which we using for revalidating bom   
-- [importBOMFullMassUpdatesUpdate] '10406785-7b9e-4523-81f2-01125faabe1b'    
-- =============================================      
CREATE PROCEDURE [dbo].[importBOMFullMassUpdatesUpdate]       
 -- Add the parameters for the stored procedure here      
 @importId UNIQUEIDENTIFIER,@fieldName VARCHAR(20),@currentValue VARCHAR(MAX),@newValue VARCHAR(MAX),@validation VARCHAR(10) = '03user',      
 @alias BIT = 0,@partClass VARCHAR(MAX) =''    
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET NOCOUNT ON;      
       
 DECLARE @validationSP VARCHAR(MAX),@parttypeFid UNIQUEIDENTIFIER,@fieldDefId UNIQUEIDENTIFIER,@green VARCHAR(50)='i01green',@sys VARCHAR(50)='01system'        
       
 SELECT @fieldDefId = fieldDefId, @validationSP = validationSP FROM importBOMFieldDefinitions WHERE fieldName = @fieldName      
 SELECT @parttypeFid=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='partType'       
      
 --Update if the fix applies to the BOM table      
IF(@partClass<>'' AND @fieldName ='partType')    
 BEGIN    
   DECLARE  @iTable importBom    
   INSERT INTO @iTable          
   EXEC [dbo].[sp_getImportBOMItems] @importId     
    
   UPDATE importBOMFields SET adjusted = @newValue,[validation] = @validation      
   WHERE fkImportId = @importId AND adjusted = @currentValue AND fkFieldDefId = @fieldDefId      
   AND rowId IN (SELECT rowId FROM @iTable WHERE partClass =@partClass AND partType =@currentValue)    
      
   -- 05/15/2019 Vijay G : Add cursor for update part type of part class    
   DECLARE @rowId UNIQUEIDENTIFIER    
    
   DECLARE PartsCurosr CURSOR LOCAL FAST_FORWARD      
           
   FOR SELECT rowId FROM @iTable WHERE partClass =@partClass AND partType =@currentValue        
   OPEN PartsCurosr;                
   FETCH NEXT FROM PartsCurosr INTO @rowId                  
   WHILE @@FETCH_STATUS = 0          
   BEGIN    
   -- 03/11/2020 Sachin B : Remove the unwanted execution of sp from cursor and added only usable code in the cursor   
  UPDATE importBOMFields      
  SET [status] = @green,[validation] = @sys, [message] = ' '      
  WHERE fkFieldDefId=@parttypeFid and fkImportId=@importId      
  AND EXISTS     
  (      
     select 1 from @iTable n       
     INNER JOIN PARTTYPE ON PartType.Part_class=RTRIM(n.partclass) and PARTTYPE.Part_Type=RTRIM(n.parttype)       
     and n.rowId=importBOMFields.rowId and n.rowId = @rowId    
  )                  
  FETCH NEXT FROM PartsCurosr INTO @rowId          
  CONTINUE                          
   END        
   CLOSE PartsCurosr;          
   DEALLOCATE PartsCurosr;     
-- 04/03/2020 Sachin B : Removed the unwanted execution of sp which we using for revalidating bom   
   --EXEC importBOMVldtnCheckValues @importId,null         
 END    
ELSE    
    BEGIN    
   UPDATE importBOMFields SET adjusted = @newValue,[validation] = @validation      
   WHERE fkImportId = @importId AND adjusted = @currentValue AND fkFieldDefId = @fieldDefId      
 END    
          
  --Update if the fix applies to the AVL table      
  UPDATE importBOMAvl SET adjusted = @newValue,[validation] = @validation      
  WHERE fkImportId = @importId AND adjusted = @currentValue AND fkFieldDefId = @fieldDefId      
      
  IF @alias = 1      
  BEGIN      
  INSERT INTO importBOMAVLAliases (partMfg,alias)      
  VALUES(@newValue,@currentValue)        
  END      
    
       
 --Re-validate after the changes      
 --EXEC importBOMVldtnCheckValues @importId      
 --EXEC importBOMVldtnAVLCheckValues @importId      
      
END