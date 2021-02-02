               
CREATE PROCEDURE [dbo].[MnxNoteGet](     
--7/10/2014 Santosh Lokhande: Check TaggedUserId should be null                  
--7/28/2014 Santosh Lokhande: Get external user bit  
--9/26/2014 Santosh Lokhande: Filter Notes by RecordType='Note'
-- 06/13/18 YS rmoved columns that generated an error due to the structure change      
@NoteId uniqueidentifier                    
)                    
AS                    
BEGIN                    
                    
SELECT n.[NoteID]                    
      ,n.[Description]                    
      ,n.[fkCreatedUserID]                    
      ,n.[CreatedDate]                    
      ,n.[fkLastModifiedUserID]                    
      ,n.[LastModifiedDate]                    
      ,n.[DeletedDate]                    
      ,n.[fkDeletedUserID]                    
      ,n.[IsDeleted]                    
      ,n.[ReminderDate]                    
     -- 06/13/18 YS rmoved columns that generated an error due to the structure change  
	  --,n.[IsSystemNote]                    
      ,userProfile.Initials as CreatedUserName                    
      ,nr.[RecordID]                    
      ,nr.[RecordType]                    
     -- 06/13/18 YS rmoved columns that generated an error due to the structure change  
	  --,n.[IsFlagged]               
      -- 06/13/18 YS rmoved columns that generated an error due to the structure change  
	  --,n.[ShowToExternalUser]    --7/28/2014 Santosh Lokhande: Get external user bit     
 FROM wmNotes n                    
inner join dbo.[aspnet_Profile] userProfile on userProfile.UserId = n.fkCreatedUserId                    
inner join [wmNoteToRecord] nr on nr.fkNoteId = n.NoteId                    
WHERE n.NoteId = @NoteId AND  n.IsDeleted = 0       
            
--7/10/2014 Santosh Lokhande: Check TaggedUserId should be null      
--9/26/2014 Santosh Lokhande: Filter Notes by RecordType='Note'                 
  SELECT [RecordTags].[RecordTagID]                  
      ,[RecordTags].[fkRecordID]                  
      ,[MnxAdminTags].[Description]                  
      ,[RecordTags].[fkCreatedUserID]                  
      ,[RecordTags].[CreatedDate]                  
 FROM [dbo].[RecordTags]                  
 inner join wmNotes n on n.NoteId = [RecordTags].fkRecordId                  
 inner join [wmNoteToRecord] nr on nr.fkNoteId = n.NoteId                  
 inner join MnxAdminTags on [RecordTags].fkAdminTagID = MnxAdminTags.AdminTagID                  
 WHERE n.NoteId = @NoteId AND n.IsDeleted = 0 AND [RecordTags].TaggedUserId IS NULL  AND RecordTags.RecordType = 'Note'                
 ORDER by [CreatedDate] DESC                  
                   
END