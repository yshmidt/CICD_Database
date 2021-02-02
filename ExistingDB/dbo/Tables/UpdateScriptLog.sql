CREATE TABLE [dbo].[UpdateScriptLog] (
    [ScriptActionID] INT           IDENTITY (1, 1) NOT NULL,
    [ScriptName]     NVARCHAR (50) NULL,
    [ScriptRunDate]  SMALLDATETIME CONSTRAINT [DF_UpdateScriptLog_ScripRunDate] DEFAULT (getdate()) NOT NULL,
    [ScriptType]     NCHAR (20)    NULL,
    CONSTRAINT [PK_UpdateScriptLog] PRIMARY KEY CLUSTERED ([ScriptActionID] ASC)
);

