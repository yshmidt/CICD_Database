CREATE TYPE [dbo].[BulkInvtUpdate] AS TABLE (
    [FieldDefId]   UNIQUEIDENTIFIER NOT NULL,
    [InvtImportId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [Value]        NVARCHAR (MAX)   NULL,
    [Status]       VARCHAR (50)     NULL,
    [Message]      NVARCHAR (MAX)   NULL);

