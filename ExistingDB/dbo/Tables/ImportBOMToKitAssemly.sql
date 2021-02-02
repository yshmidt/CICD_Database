CREATE TABLE [dbo].[ImportBOMToKitAssemly] (
    [AssemblyId]    UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]    UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]  UNIQUEIDENTIFIER NOT NULL,
    [AssemblyRowId] UNIQUEIDENTIFIER NOT NULL,
    [Original]      NVARCHAR (MAX)   NULL,
    [Adjusted]      NVARCHAR (MAX)   NULL,
    [LoadStatus]    NVARCHAR (50)    NULL,
    [Status]        NVARCHAR (50)    NULL,
    [Message]       NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportBO__1C02BDABC67ED426] PRIMARY KEY CLUSTERED ([AssemblyId] ASC)
);

