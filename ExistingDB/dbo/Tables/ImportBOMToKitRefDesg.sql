CREATE TABLE [dbo].[ImportBOMToKitRefDesg] (
    [RefDesId]        UNIQUEIDENTIFIER NOT NULL,
    [FKAssemblyRowId] UNIQUEIDENTIFIER NOT NULL,
    [FKCompRowId]     UNIQUEIDENTIFIER NOT NULL,
    [RefDesRowId]     UNIQUEIDENTIFIER NOT NULL,
    [FKFieldDefId]    UNIQUEIDENTIFIER NOT NULL,
    [Original]        NVARCHAR (MAX)   NULL,
    [Adjusted]        NVARCHAR (MAX)   NULL,
    [Status]          NVARCHAR (50)    NULL,
    [Message]         NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__ImportBO__BAA3D0A9A10BC5AD] PRIMARY KEY CLUSTERED ([RefDesId] ASC)
);

