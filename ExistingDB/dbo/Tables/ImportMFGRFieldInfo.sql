CREATE TABLE [dbo].[ImportMFGRFieldInfo] (
    [DetailId]     UNIQUEIDENTIFIER CONSTRAINT [DF_ImportMFGRFieldInfo_DetailId] DEFAULT (newid()) NOT NULL,
    [FkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [PartMfgr]     NVARCHAR (8)     NOT NULL,
    [MfgrDescript] NVARCHAR (45)    NULL,
    [Message]      NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK_ImportMFGRFieldInfo] PRIMARY KEY CLUSTERED ([DetailId] ASC)
);

