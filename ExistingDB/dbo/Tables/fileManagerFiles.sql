CREATE TABLE [dbo].[fileManagerFiles] (
    [fileId]          UNIQUEIDENTIFIER CONSTRAINT [DF_fileManagerFiles_fileId] DEFAULT (newsequentialid()) NOT NULL,
    [pathKey]         CHAR (10)        CONSTRAINT [DF_fileManagerFiles_pathKey] DEFAULT ('') NOT NULL,
    [fileName]        VARCHAR (200)    CONSTRAINT [DF_fileManagerFiles_fileName] DEFAULT ('') NOT NULL,
    [fileDescription] VARCHAR (MAX)    CONSTRAINT [DF_fileManagerFiles_fileDescription] DEFAULT ('') NOT NULL,
    [fileRevision]    VARCHAR (8)      CONSTRAINT [DF_fileManagerFiles_fileRevision] DEFAULT ('') NOT NULL,
    [uploadDate]      SMALLDATETIME    NOT NULL,
    [fileSize]        INT              CONSTRAINT [DF_fileManagerFiles_fileSize] DEFAULT ((0)) NOT NULL,
    [isActive]        BIT              CONSTRAINT [DF_Table_1_active] DEFAULT ((1)) NOT NULL,
    [isHidden]        BIT              CONSTRAINT [DF_Table_1_hidden] DEFAULT ((0)) NOT NULL,
    [isMissing]       BIT              CONSTRAINT [DF_fileManagerFiles_isMissing] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_fileManagerFiles] PRIMARY KEY CLUSTERED ([fileId] ASC)
);

