CREATE TABLE [dbo].[ImportInvtAdjustFields] (
    [DetailId]     UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [FkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [Original]     NVARCHAR (MAX)   NULL,
    [Adjusted]     NVARCHAR (MAX)   NULL,
    [Status]       NVARCHAR (50)    NULL,
    [Message]      NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportIn__135C316D0E526693] PRIMARY KEY CLUSTERED ([DetailId] ASC)
);

