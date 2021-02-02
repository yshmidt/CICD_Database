CREATE TABLE [dbo].[ImportSOPriceFields] (
    [SOPriceId]       UNIQUEIDENTIFIER NOT NULL,
    [FKSODetailRowId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          NVARCHAR (50)    NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportSO__B1853AF2136A6827] PRIMARY KEY CLUSTERED ([SOPriceId] ASC)
);

