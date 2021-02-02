CREATE TABLE [dbo].[importJEErrors] (
    [ErrorID]      INT           IDENTITY (1, 1) NOT NULL,
    [ErrorMessage] VARCHAR (MAX) NOT NULL,
    [stopUpload]   BIT           CONSTRAINT [DF_importJeErrors_stopUpload] DEFAULT ((1)) NOT NULL,
    [errorDate]    SMALLDATETIME CONSTRAINT [DF_importJeErrors_errorDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_importJEErrors] PRIMARY KEY CLUSTERED ([ErrorID] ASC)
);

