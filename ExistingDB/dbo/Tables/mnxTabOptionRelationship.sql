CREATE TABLE [dbo].[mnxTabOptionRelationship] (
    [Pk_RelationshipId]  INT IDENTITY (1, 1) NOT NULL,
    [Fk_ParentTabOption] INT NOT NULL,
    [Fk_ChildTabOption]  INT NOT NULL,
    CONSTRAINT [FK_mnxTabOptionRelationship_mnxTabOption] FOREIGN KEY ([Fk_ChildTabOption]) REFERENCES [dbo].[mnxTabOption] ([OptionId]),
    CONSTRAINT [FK_mnxTabOptionRelationship_mnxTabOption1] FOREIGN KEY ([Fk_ParentTabOption]) REFERENCES [dbo].[mnxTabOption] ([OptionId])
);

