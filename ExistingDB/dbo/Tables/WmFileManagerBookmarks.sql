CREATE TABLE [dbo].[WmFileManagerBookmarks] (
    [fmBookmarkId] BIGINT           IDENTITY (1, 1) NOT NULL,
    [userId]       UNIQUEIDENTIFIER NOT NULL,
    [FileId]       BIGINT           NOT NULL,
    CONSTRAINT [PK_WmFileManagerBookmarks] PRIMARY KEY CLUSTERED ([fmBookmarkId] ASC)
);

