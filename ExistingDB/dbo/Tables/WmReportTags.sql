CREATE TABLE [dbo].[WmReportTags] (
    [rptid]      CHAR (10) CONSTRAINT [DF_WmReportTags_rptid] DEFAULT ('') NOT NULL,
    [fkSTagId]   CHAR (10) CONSTRAINT [DF_WmReportTags_fkSTagId] DEFAULT ('') NOT NULL,
    [sequence]   INT       CONSTRAINT [DF_WmReportTags_sequence] DEFAULT ((0)) NOT NULL,
    [wmRepTagId] INT       IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_WmReportTags] PRIMARY KEY NONCLUSTERED ([wmRepTagId] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_WmReportTags]
    ON [dbo].[WmReportTags]([rptid] ASC, [fkSTagId] ASC);


GO
CREATE NONCLUSTERED INDEX [wmrepid]
    ON [dbo].[WmReportTags]([rptid] ASC);


GO
CREATE NONCLUSTERED INDEX [wmtagid]
    ON [dbo].[WmReportTags]([fkSTagId] ASC);

