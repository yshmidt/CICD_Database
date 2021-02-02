CREATE TABLE [dbo].[wmFileTagRelationship] (
    [fmTaggedId]    BIGINT           IDENTITY (1, 1) NOT NULL,
    [fkFileId]      BIGINT           NOT NULL,
    [fkRecordTagId] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_wmFileTagRelationship] PRIMARY KEY CLUSTERED ([fmTaggedId] ASC)
);

