CREATE TABLE [dbo].[MnxAdminTags] (
    [AdminTagID]  UNIQUEIDENTIFIER CONSTRAINT [DF_MnxAdminFlags_AdminFlagId] DEFAULT (newsequentialid()) NOT NULL,
    [Description] VARCHAR (50)     NOT NULL,
    CONSTRAINT [PK_MnxAdminTags] PRIMARY KEY CLUSTERED ([AdminTagID] ASC)
);

