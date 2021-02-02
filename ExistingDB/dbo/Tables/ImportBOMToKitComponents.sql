CREATE TABLE [dbo].[ImportBOMToKitComponents] (
    [CompenentId]     UNIQUEIDENTIFIER NOT NULL,
    [FKAssemblyRowId] UNIQUEIDENTIFIER NOT NULL,
    [CompRowId]       UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          NVARCHAR (50)    NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportBO__B1C3146E91DDD295] PRIMARY KEY CLUSTERED ([CompenentId] ASC)
);

