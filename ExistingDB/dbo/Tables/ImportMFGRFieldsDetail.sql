CREATE TABLE [dbo].[ImportMFGRFieldsDetail] (
    [DetailId]   UNIQUEIDENTIFIER CONSTRAINT [DF_ImportMFGRFieldsDetail_DetailId] DEFAULT (newid()) NOT NULL,
    [FkImportId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]      UNIQUEIDENTIFIER NOT NULL,
    [FieldName]  NVARCHAR (MAX)   NOT NULL,
    [Original]   NVARCHAR (MAX)   NULL,
    [Adjusted]   NVARCHAR (MAX)   NULL,
    [Status]     NVARCHAR (50)    NULL,
    [Message]    NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK_ImportMFGRFieldsDetail] PRIMARY KEY CLUSTERED ([DetailId] ASC)
);

