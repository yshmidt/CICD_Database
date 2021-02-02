CREATE TABLE [dbo].[MnxReportTags] (
    [rptId]    CHAR (10) NOT NULL,
    [fksTagId] CHAR (10) NOT NULL,
    [sequence] INT       CONSTRAINT [DF_rptTags_sequence] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_reportTags] PRIMARY KEY CLUSTERED ([rptId] ASC, [fksTagId] ASC),
    CONSTRAINT [FK_MnxReportTags_MnxSystemTags] FOREIGN KEY ([rptId], [fksTagId]) REFERENCES [dbo].[MnxReportTags] ([rptId], [fksTagId])
);

