CREATE TABLE [dbo].[importSerialNoErrors] (
    [errorid]      INT            IDENTITY (1, 1) NOT NULL,
    [ErrorMessage] NVARCHAR (MAX) CONSTRAINT [DF__importSer__Error__7B5E7FA7] DEFAULT ('') NOT NULL,
    [errorDate]    SMALLDATETIME  NULL,
    CONSTRAINT [PK_importSerialNoErrors] PRIMARY KEY CLUSTERED ([errorid] ASC)
);

