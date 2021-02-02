CREATE TABLE [dbo].[importRoutingHeader] (
    [ImportId]      UNIQUEIDENTIFIER NOT NULL,
    [workSheetName] NVARCHAR (500)   NOT NULL,
    [uploadDate]    SMALLDATETIME    NOT NULL,
    [uploadBy]      UNIQUEIDENTIFIER NOT NULL,
    [completeDate]  SMALLDATETIME    CONSTRAINT [DF__importRou__compl__67D90BEC] DEFAULT (NULL) NULL,
    [completedBy]   UNIQUEIDENTIFIER CONSTRAINT [DF__importRou__compl__68CD3025] DEFAULT (NULL) NULL,
    CONSTRAINT [PK__importRo__869767EA5346531D] PRIMARY KEY CLUSTERED ([ImportId] ASC)
);

