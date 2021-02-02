CREATE TABLE [dbo].[wmNoteReminders] (
    [NoteReminderID] UNIQUEIDENTIFIER CONSTRAINT [DF_WMNoteReminders_ID] DEFAULT (newid()) NOT NULL,
    [fkUserID]       UNIQUEIDENTIFIER NOT NULL,
    [ReminderDate]   DATETIME         NOT NULL,
    [fkNoteRecordID] UNIQUEIDENTIFIER NOT NULL,
    [IsDeleted]      BIT              CONSTRAINT [DF_WMNoteReminders_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [FK_MnxNoteReminders_aspnet_Users] FOREIGN KEY ([fkUserID]) REFERENCES [dbo].[aspnet_Users] ([UserId]),
    CONSTRAINT [FK_MnxNoteReminders_NoteToRecord] FOREIGN KEY ([fkNoteRecordID]) REFERENCES [dbo].[wmNoteToRecord] ([NoteRecordID])
);

