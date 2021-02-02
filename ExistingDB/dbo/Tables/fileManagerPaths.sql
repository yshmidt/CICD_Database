CREATE TABLE [dbo].[fileManagerPaths] (
    [pathKey]  CHAR (10)     NOT NULL,
    [pathName] VARCHAR (100) NOT NULL,
    [fullPath] VARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_FileManagerPaths] PRIMARY KEY CLUSTERED ([pathKey] ASC)
);

