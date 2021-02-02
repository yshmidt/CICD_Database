CREATE TABLE [dbo].[WmFileRelationShips] (
    [FilePreviewId] INT            IDENTITY (1, 1) NOT NULL,
    [RecordType]    NVARCHAR (100) NULL,
    [RecordId]      NVARCHAR (100) NULL,
    [fkFileId]      BIGINT         NOT NULL,
    CONSTRAINT [PK_WmFileRelationShips] PRIMARY KEY CLUSTERED ([FilePreviewId] ASC)
);

