CREATE TABLE [dbo].[QbSettings] (
    [QbSettingId]      INT           IDENTITY (1, 1) NOT NULL,
    [RefreshQbLog]     INT           NULL,
    [IsQbSyncEnable]   BIT           NOT NULL,
    [PLMainDate]       SMALLDATETIME NULL,
    [CmMainDate]       SMALLDATETIME NULL,
    [ApMasterDate]     SMALLDATETIME NULL,
    [DMemosDate]       SMALLDATETIME NULL,
    [CompanyFilePath]  VARCHAR (100) NULL,
    [TransactionDate]  SMALLDATETIME NULL,
    [SyncStartTime]    TIME (7)      NULL,
    [SyncIntervalUnit] TIME (7)      NULL,
    CONSTRAINT [PK_QbSettings] PRIMARY KEY CLUSTERED ([QbSettingId] ASC)
);

