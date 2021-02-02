CREATE TABLE [dbo].[importBOMRefDesg] (
    [refdesId]   UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMRefDesg_refdesId] DEFAULT (newsequentialid()) NOT NULL,
    [fkImportId] UNIQUEIDENTIFIER NOT NULL,
    [fkRowId]    UNIQUEIDENTIFIER NOT NULL,
    [refdesg]    VARCHAR (MAX)    CONSTRAINT [DF_importBOMRefDesg_refdesg] DEFAULT ('') NOT NULL,
    [refOrd]     INT              NOT NULL,
    [status]     VARCHAR (10)     CONSTRAINT [DF_importBOMRefDesg_status] DEFAULT ('i00white') NOT NULL,
    [message]    VARCHAR (MAX)    CONSTRAINT [DF_importBOMRefDesg_message] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_importBOMRefDesg] PRIMARY KEY CLUSTERED ([refdesId] ASC),
    CONSTRAINT [FK_importBOMRefDesg_importBOMHeader] FOREIGN KEY ([fkImportId]) REFERENCES [dbo].[importBOMHeader] ([importId]) ON DELETE CASCADE
);

