CREATE TABLE [dbo].[WmFileTree] (
    [RelationshipId] BIGINT IDENTITY (1, 1) NOT NULL,
    [ParentId]       BIGINT NOT NULL,
    [ChildId]        BIGINT NOT NULL,
    [Sequence]       INT    CONSTRAINT [DF_WmFileTree_Sequence] DEFAULT ((0)) NOT NULL,
    [IsAttachment]   BIT    CONSTRAINT [DF_WmFileTree_IsAttachment] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WmFileTree] PRIMARY KEY CLUSTERED ([RelationshipId] ASC)
);

