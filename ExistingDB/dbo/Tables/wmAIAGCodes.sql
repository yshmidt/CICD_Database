CREATE TABLE [dbo].[wmAIAGCodes] (
    [AIAGCode]        VARCHAR (10)  CONSTRAINT [DF_wmAIAGCodes_AIAGCode] DEFAULT ('') NOT NULL,
    [DataDescription] VARCHAR (100) CONSTRAINT [DF_wmAIAGCodes_DataDescription] DEFAULT ('') NOT NULL,
    [AIAGUnique]      INT           IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_wmAIAGCodes] PRIMARY KEY CLUSTERED ([AIAGUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_wmDataDescription]
    ON [dbo].[wmAIAGCodes]([DataDescription] ASC);

