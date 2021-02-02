CREATE TABLE [dbo].[MnxUserGuide] (
    [UserGuideId] INT           IDENTITY (1, 1) NOT NULL,
    [Contents]    VARCHAR (MAX) NULL,
    [ModuleId]    INT           NOT NULL,
    [ParentId]    INT           CONSTRAINT [DF__MnxUserGu__Paren__03D4956E] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_MnxUserGuide] PRIMARY KEY CLUSTERED ([UserGuideId] ASC),
    CONSTRAINT [FK_MnxUserGuide_MnxModule] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[MnxModule] ([ModuleId])
);

