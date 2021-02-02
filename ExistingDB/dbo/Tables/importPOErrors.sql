CREATE TABLE [dbo].[importPOErrors] (
    [ErrorID]      INT           IDENTITY (1, 1) NOT NULL,
    [ErrorMessage] VARCHAR (MAX) NOT NULL,
    [stopUpload]   BIT           CONSTRAINT [DF_importPOErrors_stopUpload] DEFAULT ((1)) NOT NULL,
    [errorDate]    SMALLDATETIME CONSTRAINT [DF_importPOErrors_errorDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_importPOErrors] PRIMARY KEY CLUSTERED ([ErrorID] ASC)
);

