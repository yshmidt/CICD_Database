CREATE TABLE [dbo].[importBOMErrors] (
    [erroId]      UNIQUEIDENTIFIER CONSTRAINT [DF_importBOMErrors_erroId] DEFAULT (newid()) NOT NULL,
    [importId]    UNIQUEIDENTIFIER NOT NULL,
    [errNumber]   INT              NOT NULL,
    [errSeverity] INT              NOT NULL,
    [errProc]     VARCHAR (MAX)    NOT NULL,
    [errLine]     INT              NOT NULL,
    [errMsg]      VARCHAR (MAX)    NOT NULL,
    [errDate]     SMALLDATETIME    CONSTRAINT [DF_importBOMErrors_errDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_importBOMErrors] PRIMARY KEY CLUSTERED ([erroId] ASC),
    CONSTRAINT [FK_importBOMErrors_importBOMHeader] FOREIGN KEY ([importId]) REFERENCES [dbo].[importBOMHeader] ([importId]) ON DELETE CASCADE
);

