CREATE TABLE [dbo].[aspmnx_Groups] (
    [groupId]    UNIQUEIDENTIFIER CONSTRAINT [DF_aspmnx_Groups_groupId] DEFAULT (newsequentialid()) NOT NULL,
    [groupName]  VARCHAR (250)    CONSTRAINT [DF_aspmnx_Groups_groupName] DEFAULT ('') NOT NULL,
    [createDate] SMALLDATETIME    CONSTRAINT [DF_aspmnx_Groups_createDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_aspmnx_Groups] PRIMARY KEY CLUSTERED ([groupId] ASC)
);

