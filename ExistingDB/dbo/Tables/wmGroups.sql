CREATE TABLE [dbo].[wmGroups] (
    [rptGroupId]    VARCHAR (50)  NOT NULL,
    [rptGroupTitle] VARCHAR (100) CONSTRAINT [DF_wmGroups_rptGroupTitle] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_wmGroups] PRIMARY KEY CLUSTERED ([rptGroupId] ASC)
);

