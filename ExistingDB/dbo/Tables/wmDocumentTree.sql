CREATE TABLE [dbo].[wmDocumentTree] (
    [DocBranchId]     BIGINT IDENTITY (1, 1) NOT NULL,
    [ParentId]        BIGINT NOT NULL,
    [ChildDocumentId] BIGINT NOT NULL,
    [Sibling]         BIT    CONSTRAINT [DF_wmManexDocumentTree_Sibling] DEFAULT ((0)) NOT NULL,
    [Include]         BIT    CONSTRAINT [DF_wmManexDocumentTree_Include] DEFAULT ((0)) NOT NULL,
    [Sequence]        INT    CONSTRAINT [DF_wmManexDocumentTree_Sequence] DEFAULT ((0)) NOT NULL,
    [IsAttachment]    BIT    CONSTRAINT [DF_wmDocumentTree_IsAttachment] DEFAULT ((0)) NOT NULL,
    [IsRelatedDoc]    BIT    CONSTRAINT [DF_wmDocumentTree_IsRelatedDoc] DEFAULT ((0)) NOT NULL,
    [IsExternalLink]  BIT    CONSTRAINT [DF__wmDocumen__IsExt__4B854F53] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_wmManexDocumentTree] PRIMARY KEY CLUSTERED ([DocBranchId] ASC)
);

