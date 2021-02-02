CREATE TABLE [dbo].[wmNotes] (
    [NoteID]               UNIQUEIDENTIFIER CONSTRAINT [DF_wmNotes_NoteID] DEFAULT (newsequentialid()) NOT NULL,
    [Description]          VARCHAR (MAX)    CONSTRAINT [DF_WmNotes_Description] DEFAULT ('') NOT NULL,
    [fkCreatedUserID]      UNIQUEIDENTIFIER NOT NULL,
    [CreatedDate]          DATETIME         CONSTRAINT [DF_wmNotes_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [fkLastModifiedUserID] UNIQUEIDENTIFIER NULL,
    [LastModifiedDate]     SMALLDATETIME    NULL,
    [DeletedDate]          DATETIME         NULL,
    [fkDeletedUserID]      UNIQUEIDENTIFIER NULL,
    [IsDeleted]            BIT              CONSTRAINT [DF_wmNotes_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ReminderDate]         SMALLDATETIME    NULL,
    [DueDate]              SMALLDATETIME    NULL,
    [NoteType]             VARCHAR (100)    NULL,
    [RecordId]             VARCHAR (100)    NULL,
    [RecordType]           VARCHAR (100)    NULL,
    [NoteCategory]         INT              NULL,
    [FollowUpComments]     VARCHAR (MAX)    CONSTRAINT [DF__wmNotes__FollowU__11839647] DEFAULT (NULL) NULL,
    [FollowUpDate]         SMALLDATETIME    CONSTRAINT [DF__wmNotes__FollowU__1277BA80] DEFAULT (NULL) NULL,
    [IsActionClose]        BIT              CONSTRAINT [DF__wmNotes__IsActio__136BDEB9] DEFAULT ((0)) NULL,
    [CarNo]                INT              CONSTRAINT [DF_wmNotes_CarNo] DEFAULT ((0)) NULL,
    [CategoryId]           INT              CONSTRAINT [DF__wmNotes__Categor__17076573] DEFAULT (NULL) NULL,
    [AssignTo]             UNIQUEIDENTIFIER CONSTRAINT [DF__wmNotes__AssignT__17FB89AC] DEFAULT (NULL) NULL,
    [Priority]             INT              CONSTRAINT [DF__wmNotes__Priorit__3F1556CD] DEFAULT ((0)) NULL,
    [ParentNoteId]         UNIQUEIDENTIFIER CONSTRAINT [DF__wmNotes__ParentN__674343B8] DEFAULT (NULL) NULL,
    [ActionCloseBy]        UNIQUEIDENTIFIER CONSTRAINT [DF__wmNotes__ActionC__00CE0B91] DEFAULT (NULL) NULL,
    [FollowUpBy]           UNIQUEIDENTIFIER CONSTRAINT [DF__wmNotes__FollowU__01C22FCA] DEFAULT (NULL) NULL,
    [FollowUpCloseBy]      UNIQUEIDENTIFIER CONSTRAINT [DF__wmNotes__FollowU__02B65403] DEFAULT (NULL) NULL,
    [IsFollowUpComplete]   BIT              CONSTRAINT [DF__wmNotes__IsFollo__03AA783C] DEFAULT ((0)) NOT NULL,
    [ActionCloseDate]      DATETIME2 (0)    CONSTRAINT [DF__wmNotes__ActionC__049E9C75] DEFAULT (NULL) NULL,
    [IssueType]            VARCHAR (50)     CONSTRAINT [DF__wmNotes__CAPATyp__63B2A9F6] DEFAULT ('') NULL,
    [Importance]           VARCHAR (50)     CONSTRAINT [DF__wmNotes__Importa__64A6CE2F] DEFAULT ('Medium') NULL,
    [IsCustomerSupport]    BIT              CONSTRAINT [DF_wmNotes_IsCustomSupport] DEFAULT ((0)) NOT NULL,
    [Progress]             INT              CONSTRAINT [DF__wmNotes__Progres__65FAE51B] DEFAULT ((0)) NOT NULL,
    [TaskCompletedBy]      UNIQUEIDENTIFIER NULL,
    [TaskCompletedDate]    DATETIME         NULL,
    [IsNewTask]            BIT              CONSTRAINT [DF__wmNotes__IsNewTa__66EF0954] DEFAULT ((0)) NOT NULL,
    [TaskLevel]            INT              NULL,
    [SubCatID]             INT              CONSTRAINT [DF__wmNotes__SubCatI__47E13DA6] DEFAULT (NULL) NULL,
    [CompanyNo]            CHAR (10)        CONSTRAINT [DF__wmNotes__Company__48D561DF] DEFAULT ('') NULL,
    CONSTRAINT [PK_wmNotes] PRIMARY KEY CLUSTERED ([NoteID] ASC),
    CONSTRAINT [FK_Notes_aspnet_Users_Created] FOREIGN KEY ([fkCreatedUserID]) REFERENCES [dbo].[aspnet_Users] ([UserId]),
    CONSTRAINT [FK_Notes_aspnet_Users_Deleted] FOREIGN KEY ([fkDeletedUserID]) REFERENCES [dbo].[aspnet_Users] ([UserId]),
    CONSTRAINT [FK_Notes_aspnet_Users_Modified] FOREIGN KEY ([fkLastModifiedUserID]) REFERENCES [dbo].[aspnet_Users] ([UserId])
);


GO
-- =============================================
-- Author:		Raviraj P
-- Create date: 1/16/2017
-- Description:	Delete notification if note set as IsDeleted to true
-- 7/14/2017 Raviraj P : cast noteid as char 100
-- =============================================
CREATE TRIGGER [dbo].[WmNotes_Update]
   ON  [dbo].[wmNotes]
   AFTER UPDATE
AS 
BEGIN
   SET NOCOUNT ON;
   -- Update statements for trigger here
   BEGIN TRANSACTION
    DECLARE  @isDeleted bit;
   		BEGIN TRY
		   SELECT  @isDeleted = INSERTED.IsDeleted FROM INSERTED
		   IF @isDeleted = 1
				  DELETE FROM wmTriggerNotification WHERE EXISTS(SELECT 1 FROM INSERTED WHERE cast(INSERTED.NoteID  as char(100)) = wmTriggerNotification.RecordId)  -- 7/14/2017 Raviraj P : cast noteid as char 100
		 END TRY
		 BEGIN CATCH
				IF @@TRANCOUNT > 0
					ROLLBACK TRANSACTION ;
				    RETURN;
		 END CATCH
	COMMIT
END                                           
