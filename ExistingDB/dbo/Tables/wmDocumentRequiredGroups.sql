CREATE TABLE [dbo].[wmDocumentRequiredGroups] (
    [DocRequiredGroupId] BIGINT           IDENTITY (1, 1) NOT NULL,
    [GroupId]            UNIQUEIDENTIFIER NOT NULL,
    [DocumentId]         BIGINT           NOT NULL,
    [IsApprover]         BIT              CONSTRAINT [DF_wmManexDocumentRequiredGroups_IsApprover] DEFAULT ((0)) NOT NULL,
    [IsEditor]           BIT              CONSTRAINT [DF_wmManexDocumentRequiredGroups_IsEditor] DEFAULT ((0)) NOT NULL,
    [IsViewer]           BIT              CONSTRAINT [DF_wmManexDocumentRequiredGroups_IsViewer] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_wmManexDocumentRequiredGroups] PRIMARY KEY CLUSTERED ([DocRequiredGroupId] ASC),
    CONSTRAINT [FK_wmDocumentRequiredGroups_aspmnx_Groups] FOREIGN KEY ([GroupId]) REFERENCES [dbo].[aspmnx_Groups] ([groupId]),
    CONSTRAINT [FK_wmManexDocumentRequiredGroups_wmUserGuideDocuments] FOREIGN KEY ([DocumentId]) REFERENCES [dbo].[wmUserGuideDocuments] ([DocumentId])
);

