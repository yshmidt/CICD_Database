CREATE TABLE [dbo].[MnxDashboard] (
    [Id]                INT           IDENTITY (1, 1) NOT NULL,
    [Name]              VARCHAR (100) CONSTRAINT [DF_MnxDashboard_Name] DEFAULT ('') NOT NULL,
    [Description]       VARCHAR (MAX) CONSTRAINT [DF_MnxDashboard_Description] DEFAULT ('') NOT NULL,
    [IsMaster]          BIT           CONSTRAINT [DF_MnxDashboard_IsMaster] DEFAULT ((1)) NOT NULL,
    [MasterDashboardId] INT           NULL,
    CONSTRAINT [PK_MnxDashboard] PRIMARY KEY CLUSTERED ([Id] ASC)
);

