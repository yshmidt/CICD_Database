CREATE TABLE [dbo].[MnxGroups] (
    [rptGroupId]    VARCHAR (50)  NOT NULL,
    [rptGroupTitle] VARCHAR (100) CONSTRAINT [DF_rptGroups_rptGroupName] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_rptGroups] PRIMARY KEY CLUSTERED ([rptGroupId] ASC)
);

