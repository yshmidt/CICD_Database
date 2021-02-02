-- ==========================================================================================      
-- Author:  <Nilesh Sa>    
-- Create date: 4/12/2019
-- Description: Get note list against recordtype & recordid
-- EXEC [dbo].[GetNotesList] 'PLMAIN_INVFN','0000000363'   
-- ==========================================================================================      
CREATE PROCEDURE [dbo].[GetNotesList]   
  @recordType AS VARCHAR(MAX)='',
  @recordId AS VARCHAR(MAX)=''  
AS  
  SELECT wmNoteRelationship.Note FROM wmNotes 
  LEFT JOIN wmNoteRelationship ON wmNotes.NoteID = wmNoteRelationship.FkNoteId
  WHERE wmNotes.RecordType=@recordType and RecordId = @recordId
