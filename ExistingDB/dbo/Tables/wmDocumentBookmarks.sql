CREATE TABLE [dbo].[wmDocumentBookmarks] (
    [BookmarkId] BIGINT           IDENTITY (1, 1) NOT NULL,
    [UserId]     UNIQUEIDENTIFIER NOT NULL,
    [DocumentId] BIGINT           NOT NULL,
    CONSTRAINT [PK_wmUserGuideBookmarks] PRIMARY KEY CLUSTERED ([BookmarkId] ASC),
    CONSTRAINT [FK_wmUserGuideBookmarks_wmUserGuideDocuments] FOREIGN KEY ([DocumentId]) REFERENCES [dbo].[wmUserGuideDocuments] ([DocumentId])
);

