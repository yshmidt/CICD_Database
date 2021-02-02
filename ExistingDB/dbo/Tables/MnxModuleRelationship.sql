CREATE TABLE [dbo].[MnxModuleRelationship] (
    [RelationshipId] INT IDENTITY (1, 1) NOT NULL,
    [ParentId]       INT NULL,
    [ChildId]        INT NULL,
    [ModuleOrder]    INT NULL,
    CONSTRAINT [PK_MnxModuleRelationship] PRIMARY KEY CLUSTERED ([RelationshipId] ASC)
);

