CREATE TABLE [dbo].[MnxModuleMenus] (
    [menuId]      UNIQUEIDENTIFIER CONSTRAINT [DF__MnxModule__menuI__4DD6156B] DEFAULT (newid()) NOT NULL,
    [fkmoduleId]  INT              NOT NULL,
    [resourceKey] VARCHAR (50)     NOT NULL,
    [action]      VARCHAR (255)    NOT NULL,
    [listOrder]   INT              NOT NULL,
    [isTutorial]  BIT              CONSTRAINT [DF_MnxModuleMenus_isTutorial] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MnxModuleMenus] PRIMARY KEY CLUSTERED ([menuId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [moduleid]
    ON [dbo].[MnxModuleMenus]([fkmoduleId] ASC);

