CREATE TABLE [dbo].[ImportInvtAdjustSerialFields] (
    [SerialDetailId] UNIQUEIDENTIFIER NOT NULL,
    [FkRowId]        UNIQUEIDENTIFIER NOT NULL,
    [SerialRowId]    UNIQUEIDENTIFIER NOT NULL,
    [FkFieldDefId]   UNIQUEIDENTIFIER NOT NULL,
    [Original]       NVARCHAR (MAX)   NULL,
    [Adjusted]       NVARCHAR (MAX)   NULL,
    [Status]         NVARCHAR (50)    NULL,
    [Message]        NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportIn__EDD466E878C7D0BE] PRIMARY KEY CLUSTERED ([SerialDetailId] ASC)
);

