CREATE TABLE [dbo].[MnxAddMeta] (
    [fieldId]      INT           IDENTITY (1, 1) NOT NULL,
    [tableName]    VARCHAR (50)  NOT NULL,
    [fieldName]    VARCHAR (100) NOT NULL,
    [sequence]     INT           CONSTRAINT [DF_MnxAddMeta_sequence] DEFAULT ((0)) NOT NULL,
    [display]      BIT           CONSTRAINT [DF_MnxAddMeta_display] DEFAULT ((1)) NOT NULL,
    [defaultValue] VARCHAR (200) CONSTRAINT [DF_MnxAddMeta_defaultValue] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_MnxAddMeta] PRIMARY KEY CLUSTERED ([fieldId] ASC)
);

