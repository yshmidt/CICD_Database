    
CREATE PROCEDURE [dbo].[MnxNotesGet](              
--7/10/2014 Santosh Lokhande: Check TaggedUserId should be null       
--7/28/2014 Santosh Lokhande: Check external user bit and show only related notes.    
--9/26/2014 Santosh Lokhande: Filter Notes by RecordType='Note'
-- 06/13/18 YS structure changes generated an error
@RecordId varchar(100),              
@RecordType varchar(50),              
@OrderByNumber int=1 ,      
@IsExternalUser bit =0  --7/28/2014 Santosh Lokhande: Added external user bit to check that user is internal or         external    
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
      --06/13/18 YS remove the code for now, probably have to remove the SP 
	  ---,n.[IsSystemNote]              
      ,p.Initials as CreatedUserName              
      ,nr.[RecordID]              
      ,nr.[RecordType]              
     -- ,n.[IsFlagged]              
      ,n.ReminderDate       
     -- ,n.ShowToExternalUser           
 FROM wmNotes n            
inner join [aspnet_Profile] p on p.UserId = n.fkCreatedUserId              
inner join [wmNoteToRecord] nr on nr.fkNoteId = n.NoteId              
--LEFT outer join dbo.wmNoteReminders on nr.NoteRecordId = wmNoteReminders.fkNoteRecordId AND wmNoteReminders.IsDeleted =0              
WHERE nr.RecordId = @RecordId AND nr.RecordType = @RecordType AND n.IsDeleted = 0  
--7/28/2014 Santosh Lokhande: Check external user bit and show only related notes.   
--06/13/18 YS remove the code for now, probably have to remove the SP 
--AND (@IsExternalUser = 0 OR n.ShowToExternalUser = 1)             
ORDER BY              
CASE WHEN @OrderByNumber = 1 THEN n.CreatedDate END desc ,              
CASE WHEN @OrderByNumber = 2 THEN p.Initials END,    
--06/13/18 YS remove the code for now, probably have to remove the SP           
--CASE WHEN @OrderByNumber = 3 THEN n.IsSystemNote END,              
--CASE WHEN @OrderByNumber = 4 THEN wmNoteReminders.ReminderDate END DESC,              
CASE WHEN @OrderByNumber = 5 THEN n.[Description] END 
--06/13/18 YS remove the code for now, probably have to remove the SP            
--CASE WHEN @OrderByNumber = 6 THEN n.[IsFlagged] END desc --Note flag              
        
--7/10/2014 Santosh Lokhande: Check TaggedUserId should be null            
--9/26/2014 Santosh Lokhande: Filter Notes by RecordType='Note'            
SELECT rt.[RecordTagID]            
      ,rt.[fkRecordID]            
      ,at.[Description]            
      ,rt.[fkCreatedUserID]            
      ,rt.[CreatedDate]            
 FROM [dbo].[RecordTags] rt            
 inner join wmNotes n on n.NoteId = rt.fkRecordId            
 inner join [wmNoteToRecord] nr on nr.fkNoteId = n.NoteId            
  inner join MnxAdminTags at on rt.fkAdminTagID = at.AdminTagID            
 WHERE nr.RecordId = @RecordId AND nr.RecordType = @RecordType AND n.IsDeleted = 0   AND rt.TaggedUserId IS NULL       
 --7/28/2014 Santosh Lokhande: Check external user bit and show only related notes tag. 
 --06/13/18 YS remove the code for now, probably have to remove the SP    
 --AND (@IsExternalUser = 0 OR n.ShowToExternalUser = 1) 
 AND rt.RecordType = 'Note'      
 ORDER by [CreatedDate] DESC            
            
END