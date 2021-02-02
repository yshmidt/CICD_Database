CREATE TABLE [dbo].[wmDocumentTags] (
    [DocTagId]      BIGINT           IDENTITY (1, 1) NOT NULL,
    [DocumentId]    BIGINT           NOT NULL,
    [FkRecordTagId] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_wmDocumentTags] PRIMARY KEY CLUSTERED ([DocTagId] ASC),
    CONSTRAINT [FK_wmDocumentTags_RecordTags] FOREIGN KEY ([FkRecordTagId]) REFERENCES [dbo].[RecordTags] ([RecordTagID]),
    CONSTRAINT [FK_wmDocumentTags_wmUserGuideDocuments] FOREIGN KEY ([DocumentId]) REFERENCES [dbo].[wmUserGuideDocuments] ([DocumentId])
);

