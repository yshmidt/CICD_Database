CREATE TABLE [dbo].[importSupplierMpnLinkerror] (
    [erroId]      UNIQUEIDENTIFIER CONSTRAINT [DF_importSupplierMpnLinkerror_erroId] DEFAULT (newid()) NOT NULL,
    [errNumber]   INT              NOT NULL,
    [errSeverity] INT              NOT NULL,
    [errProc]     VARCHAR (MAX)    NOT NULL,
    [errLine]     INT              NOT NULL,
    [errMsg]      VARCHAR (MAX)    NOT NULL,
    [errDate]     SMALLDATETIME    CONSTRAINT [DF_importSupplierMpnLinkerror_errDate] DEFAULT (getdate()) NULL,
    [importId]    UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_importSupplierMpnLinkerror] PRIMARY KEY NONCLUSTERED ([erroId] ASC)
);


GO
CREATE CLUSTERED INDEX [IX_importId]
    ON [dbo].[importSupplierMpnLinkerror]([importId] ASC);

