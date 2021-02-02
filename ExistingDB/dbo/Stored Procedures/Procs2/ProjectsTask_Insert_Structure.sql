-- =============================================
-- Author:		Raviraj P
-- Create date: 08/16/2018
-- Description:	Create projects/tasks structure into  select note
-- EXEC ProjectsTask_Insert_Structure @fkCreatedUserID='49f80792-e15e-4b62-b720-21b360e3108a', @RecordId='5c158930-4993-9beb-f64c-a2a4e321be26'
-- =============================================

CREATE PROC ProjectsTask_Insert_Structure
@fkCreatedUserID uniqueidentifier,
@RecordId varchar(100)
AS
	IF(@fkCreatedUserID IS NOT NULL AND @RecordId IS NOT NULL)
	BEGIN
		DECLARE @TotalRecords INT
		DECLARE @Count INT = 1
		DECLARE @Structure TABLE (Id INT IDENTITY(1,1) PRIMARY KEY, NoteId UNIQUEIDENTIFIER, Description VARCHAR(max))
		--Define list for projects/Tasks
		DECLARE @list VARCHAR(max) = 'Requirement Analysis,UI Development,DB Changes,API Private,API Public,Business Logic,UI Data Binding,Validations,Unit Testing,Smoke Testing,Functionality Testing,UI Resolution Testing,Performance Testing,BUG Fixing,Retesting and Regression Testing,Demo Changes/Enhancements'

		--Insert into temp table
		INSERT INTO @Structure (Noteid, Description) SELECT NEWID(), id FROM [dbo].[fn_simpleVarcharlistToTable] (@list, ',')

		--Insert into wmNotes table
		INSERT INTO wmNotes(NoteID, Description, fkCreatedUserID, NoteType, RecordId, RecordType,NoteCategory, AssignTo) 
		SELECT NoteId, LTRIM(RTRIM(Description)), @fkCreatedUserID, 'Note', @RecordId, 'wmNotes',1, @fkCreatedUserID FROM @Structure

		--Insert into WmNotesSetup table
		INSERT INTO WmNotesSetup(FkNoteID, UserId, Priority) SELECT NoteId,@fkCreatedUserID,Id FROM @Structure
		
		--Insert into WmNotesSetup table as participants
		SELECT  @TotalRecords  = COUNT(Id) FROM @Structure
		WHILE (@Count <= @totalRecords)
		BEGIN
			INSERT INTO WmNoteUser(WmNoteUserId, UserId, NoteId, IsGroup) SELECT NEWID(),'57DDED38-5BD5-4EC8-860B-4BB7AB4B97E4', NoteId, 0 FROM @Structure WHERE Id = @Count
			INSERT INTO WmNoteUser(WmNoteUserId, UserId, NoteId, IsGroup) SELECT NEWID(),'57BBE81C-0837-4859-A897-A7A46580062E', NoteId, 0 FROM @Structure WHERE Id = @Count
			INSERT INTO WmNoteUser(WmNoteUserId, UserId, NoteId, IsGroup) SELECT NEWID(),'2EE8060A-56A2-40FC-9F74-4D7567785F9A', NoteId, 0 FROM @Structure WHERE Id = @Count
			INSERT INTO WmNoteUser(WmNoteUserId, UserId, NoteId, IsGroup) SELECT NEWID(),'DC77B909-9B1C-4D71-9373-5EF085DED1EA', NoteId, 0 FROM @Structure WHERE Id = @Count
			INSERT INTO WmNoteUser(WmNoteUserId, UserId, NoteId, IsGroup) SELECT NEWID(),@fkCreatedUserID, NoteId, 0 FROM @Structure WHERE Id = @Count
			SELECT @Count = @Count + 1
		END	
	END



