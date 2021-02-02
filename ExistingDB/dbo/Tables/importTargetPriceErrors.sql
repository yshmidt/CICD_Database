CREATE TABLE [dbo].[importTargetPriceErrors] (
    [ErrorID]      INT           NOT NULL,
    [ErrorMessage] VARCHAR (MAX) NOT NULL,
    [stopUpload]   BIT           CONSTRAINT [DF__importTar__stopU__6E048489] DEFAULT ((1)) NOT NULL,
    [errorDate]    SMALLDATETIME CONSTRAINT [DF__importTar__error__6EF8A8C2] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK__importTa__358565CAE92DCA76] PRIMARY KEY CLUSTERED ([ErrorID] ASC)
);

