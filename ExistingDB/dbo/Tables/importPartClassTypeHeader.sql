CREATE TABLE [dbo].[importPartClassTypeHeader] (
    [ImportId]      UNIQUEIDENTIFIER NOT NULL,
    [workSheetName] NVARCHAR (500)   NOT NULL,
    [uploadDate]    SMALLDATETIME    NOT NULL,
    [uploadBy]      UNIQUEIDENTIFIER NOT NULL,
    [completeDate]  SMALLDATETIME    CONSTRAINT [DF__importPar__compl__60C1FA09] DEFAULT (NULL) NULL,
    [completedBy]   UNIQUEIDENTIFIER CONSTRAINT [DF__importPar__compl__61B61E42] DEFAULT (NULL) NULL,
    CONSTRAINT [PK__importPa__869767EAACBB9E70] PRIMARY KEY CLUSTERED ([ImportId] ASC)
);

