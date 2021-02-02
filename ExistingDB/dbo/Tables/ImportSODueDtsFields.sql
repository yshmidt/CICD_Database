CREATE TABLE [dbo].[ImportSODueDtsFields] (
    [DueDtsId]        UNIQUEIDENTIFIER NOT NULL,
    [FKSODetailRowId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          NVARCHAR (50)    NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSO__BDB97F3EAD944FE9] PRIMARY KEY CLUSTERED ([DueDtsId] ASC)
);

