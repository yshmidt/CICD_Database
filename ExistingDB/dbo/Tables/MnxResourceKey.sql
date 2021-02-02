CREATE TABLE [dbo].[MnxResourceKey] (
    [ResourceKeyId]   INT           IDENTITY (1, 1) NOT NULL,
    [ResourceKeyName] VARCHAR (900) NOT NULL,
    [ManExValue]      VARCHAR (MAX) NULL,
    CONSTRAINT [PK_MnxResourceKeys] PRIMARY KEY CLUSTERED ([ResourceKeyId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UK_ResourceKeyName]
    ON [dbo].[MnxResourceKey]([ResourceKeyName] ASC);

