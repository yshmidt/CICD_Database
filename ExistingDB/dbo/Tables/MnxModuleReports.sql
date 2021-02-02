CREATE TABLE [dbo].[MnxModuleReports] (
    [Id]         INT          IDENTITY (1, 1) NOT NULL,
    [ModuleId]   INT          NOT NULL,
    [FksTagId]   CHAR (10)    NOT NULL,
    [FkReportID] VARCHAR (10) CONSTRAINT [DF__MnxModule__FkRep__5B9D5239] DEFAULT ('') NOT NULL,
    [InModule]   BIT          CONSTRAINT [DF__MnxModule__InMod__769C2C8F] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_MnxModuleReports] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_MnxModuleReports_MnxModule] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[MnxModule] ([ModuleId]) ON DELETE CASCADE
);

