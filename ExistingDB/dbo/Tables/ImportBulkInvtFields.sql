CREATE TABLE [dbo].[ImportBulkInvtFields] (
    [DetailId]       UNIQUEIDENTIFIER CONSTRAINT [DF_ImportBulkInvtFields_DetailId] DEFAULT (newid()) ROWGUIDCOL NOT NULL,
    [FkInvtImportId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]          UNIQUEIDENTIFIER NOT NULL,
    [FkFieldDefId]   UNIQUEIDENTIFIER NOT NULL,
    [Original]       NVARCHAR (MAX)   NOT NULL,
    [Adjusted]       NVARCHAR (MAX)   NOT NULL,
    [Status]         VARCHAR (50)     NOT NULL,
    [Message]        NVARCHAR (MAX)   NOT NULL,
    [IsSysProperty]  BIT              CONSTRAINT [DF__ImportBul__IsSys__059E78FD] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ImportBulkInvtFields] PRIMARY KEY CLUSTERED ([DetailId] ASC),
    CONSTRAINT [FK_ImportBulkInvtFields_ImportBulkInvtHeader] FOREIGN KEY ([FkInvtImportId]) REFERENCES [dbo].[ImportBulkInvtHeader] ([InvtImportId])
);

