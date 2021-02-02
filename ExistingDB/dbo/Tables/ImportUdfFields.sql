CREATE TABLE [dbo].[ImportUdfFields] (
    [DetailId]   UNIQUEIDENTIFIER CONSTRAINT [DF_ImportUdfFields_DetailId] DEFAULT (newid()) ROWGUIDCOL NOT NULL,
    [FkImportId] UNIQUEIDENTIFIER NULL,
    [RowId]      UNIQUEIDENTIFIER NULL,
    [FieldName]  VARCHAR (MAX)    NULL,
    [Original]   NVARCHAR (MAX)   NULL,
    [Adjusted]   NVARCHAR (MAX)   NULL,
    [Status]     VARCHAR (50)     NULL,
    [Message]    NVARCHAR (MAX)   NOT NULL,
    [DataType]   VARCHAR (10)     NULL,
    CONSTRAINT [PK_ImportUdfFields] PRIMARY KEY CLUSTERED ([DetailId] ASC)
);

