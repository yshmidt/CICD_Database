-- Author:  Vijay G                               
-- Create date: 09/25/2019                           
-- DescriptiON: Used to update routing on create new assembly for ECO       
-- Modified Vijay G 12/27/2019 Delete record from temp table by old uniqBomNo 
-- Modified Vijay G 01/16/2020 Copy imagePath of old bom for copying attachment  
--==============================================================================    
--AddNoteForCopiedECComponent  'VXHT1N7L7L','XEN7CI33CF',1,'49f80792-e15e-4b62-b720-21b360e3108a'             
CREATE PROCEDURE [dbo].AddNoteForCopiedECComponent                      
(                      
 @oldAssUniqKey VARCHAR(10),                
 @newAssUniqKey VARCHAR(10),                
 @isCopyNote bit=0,                
 @userId UNIQUEIDENTIFIER                         
)                      
AS                                    
BEGIN                          
DECLARE @ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT                          
SET NOCOUNT ON;                                                   
BEGIN TRY                           
  DECLARE @Bom_DetNoteID UNIQUEIDENTIFIER = Null  ,@Bom_HdrNoteID UNIQUEIDENTIFIER = Null ,@olduniqbomno VARCHAR(10),@uniqbomno VARCHAR(10)                   
  DECLARE @newUniqBomNos Table(olduniqbomno VARCHAR(10),uniqbomno VARCHAR(10),oldItemno VARCHAR(10),itemno VARCHAR(10),oldUniqKey  VARCHAR(10),uniqKey  VARCHAR(10))                
                
SET @Bom_HdrNoteID = NEWID()                
IF(@isCopyNote=1)                
BEGIN           
BEGIN TRANSACTION                    
  IF EXISTS(Select * from wmNotes where RecordType='BOM_Header' AND RecordId=@oldAssUniqKey)                
  BEGIN       
           
     INSERT INTO wmNotes (NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID,CreatedDate)                
     SELECT TOP 1 @Bom_HdrNoteID,NoteCategory,@newAssUniqKey,RecordType,NoteType,fkCreatedUserID,CreatedDate                
     FROM wmNotes                 
     WHERE RecordType='BOM_Header' AND RecordId=@oldAssUniqKey    
	             
     -- Modified Vijay G 01/16/2020 Copy imagePath of old bom for copying attachment      
     INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId,CreatedDate,ImagePath)                
     SELECT @Bom_HdrNoteID,Note,CreatedUserId,wmrship.CreatedDate,ImagePath                 
     FROM WMNOTERELATIONSHIP wmrship                 
     JOIN wmNotes wm ON wmrship.FkNoteId=wm.NoteID                 
     WHERE RecordType='BOM_Header' AND RecordId=@oldAssUniqKey                
  END                    
                
 ---Insert Data in to the BOM Items notes for newly created assembly              
 INSERT INTO @newUniqBomNos(olduniqbomno ,oldUniqKey  ,oldItemno)             
 SELECT UNIQBOMNO,UNIQ_KEY,ITEM_NO             
 FROM BOM_DET             
 WHERE BOMPARENT=@oldAssUniqKey                 
                
 UPDATE @newUniqBomNos             
 SET uniqbomno=b.UNIQBOMNO,itemno= b.ITEM_NO,uniqKey=b.UNIQ_KEY                
 FROM BOM_DET b             
 JOIN @newUniqBomNos n ON b.ITEM_NO=n.oldItemno AND b.UNIQ_KEY=n.oldUniqKey                
 WHERE b.BOMPARENT=@newAssUniqKey        
                  
 WHILE (SELECT COUNT(*) From @newUniqBomNos) > 0                    
 BEGIN                  
  SELECT TOP 1 @olduniqbomno=n.olduniqbomno, @uniqbomno=n.uniqbomno             
  FROM @newUniqBomNos n             
                  
  IF EXISTS(SELECT * FROM wmNotes WHERE RecordType='BOM_DET' AND RecordId=@olduniqbomno)                
  BEGIN                
   SET @Bom_DetNoteID = newID()              
                 
   INSERT INTO wmNotes (NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID,CreatedDate)                
   SELECT TOP 1 @Bom_DetNoteID,NoteCategory,@uniqbomno,'BOM_DET','Note',fkCreatedUserID,CreatedDate                
   FROM wmNotes                 
   WHERE RecordType='BOM_DET' AND RecordId=@olduniqbomno                
             
   -- Modified Vijay G 01/16/2020 Copy imagePath of old bom for copying attachment       
   INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId,CreatedDate,ImagePath)                
   SELECT @Bom_DetNoteID,Note,CreatedUserId,wmrship.CreatedDate,ImagePath                
   FROM WMNOTERELATIONSHIP wmrship                 
   JOIN wmNotes wm ON wmrship.FkNoteId=wm.NoteID                 
   WHERE RecordType='BOM_DET' AND RecordId=@olduniqbomno                
  END         
  -- Modified Vijay G 12/27/2019 Delete record from temp table by old uniqBomNo         
  DELETE FROM @newUniqBomNos WHERE olduniqbomno = @olduniqbomno                   
 END                 
END             
            
IF NOT EXISTS(SELECT * FROM wmNotes WHERE RecordType='BOM_Header' AND RecordId=@newAssUniqKey)                
BEGIN                
   INSERT INTO wmNotes (NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)                
   VALUES( @Bom_HdrNoteID,2,@newAssUniqKey,'BOM_Header','Note',@userId)                
END             
             
INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                
VALUES (@Bom_HdrNoteID,'Assembly Created by ECO Module',@userId)                
            
COMMIT TRANSACTION           
END TRY                     
BEGIN CATCH                                       
  ROLLBACK TRANSACTION;                            
     SELECT @ErrorMessage = ERROR_MESSAGE(),                      
        @ErrorSeverity = ERROR_SEVERITY(),                      
        @ErrorState = ERROR_STATE();                      
  RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);                                          
END CATCH               
END