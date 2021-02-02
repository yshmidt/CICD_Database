-- =============================================  
-- Author:  Vicky Lu  
-- Create date: 2011/11/27  
-- Description: Delete BOM for one uniq_key  
-- 10/22/2018  Vijay G : Delete Existing Notes with respect to bom details
-- =============================================  
CREATE PROCEDURE [dbo].[sp_DeleteBom4Uniq_key] @lcUniq_key AS char(10) = ''  
AS  
BEGIN  
-- SET NOCOUNT ON added to prevent extra result sets from  
-- interfering with SELECT statements.  
SET NOCOUNT ON;  
BEGIN TRY  
 BEGIN TRANSACTION  

  -- 10/22/2018  Vijay G : Delete Existing Notes with respect to bom details
  IF EXISTS(SELECT * FROM wmNotes WHERE RecordType='importBOMItemNote' AND RecordId IN (SELECT UNIQBOMNO FROM BOM_DET WHERE UNIQ_KEY = @lcUniq_key))
  BEGIN
	 DELETE FROM wmNoteRelationship 
	 WHERE FkNoteId IN (SELECT NoteID FROM wmNotes WHERE RecordType='importBOMItemNote' AND RecordId IN (SELECT UNIQBOMNO FROM BOM_DET WHERE UNIQ_KEY = @lcUniq_key))

	 DELETE FROM wmNotes 
	 WHERE NoteID IN (SELECT NoteID FROM wmNotes WHERE RecordType='importBOMItemNote' AND RecordId IN (SELECT UNIQBOMNO FROM BOM_DET WHERE UNIQ_KEY = @lcUniq_key))
  END

  DELETE FROM BOM_REF WHERE UNIQBOMNO IN (SELECT UNIQBOMNO FROM BOM_DET WHERE BOMPARENT = @lcUniq_key)  
  DELETE FROM BOM_ALT WHERE BOMPARENT = @lcUniq_key  
  DELETE FROM BOM_DET WHERE BOMPARENT = @lcUniq_key  
  DELETE FROM AntiAvl WHERE BOMPARENT = @lcUniq_key  
 COMMIT TRANSACTION  
END TRY  
BEGIN CATCH  
 ROLLBACK TRAN  
END CATCH   
   
END  