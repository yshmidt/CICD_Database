CREATE TABLE [dbo].[MnxWidget] (
    [Id]          INT           NOT NULL,
    [Abbr]        VARCHAR (5)   NOT NULL,
    [Description] VARCHAR (100) NOT NULL,
    [ModuleId]    INT           NOT NULL,
    [Path]        VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_MnxWidget] PRIMARY KEY CLUSTERED ([Id] ASC)
);

