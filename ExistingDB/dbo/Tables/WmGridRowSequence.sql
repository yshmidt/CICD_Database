CREATE TABLE [dbo].[WmGridRowSequence] (
    [SequenceId]   INT           IDENTITY (1, 1) NOT NULL,
    [SectionName]  VARCHAR (100) NOT NULL,
    [SequenceType] VARCHAR (20)  NOT NULL,
    [RowSequence]  VARCHAR (MAX) NOT NULL,
    CONSTRAINT [PK_WmGridRowSequence] PRIMARY KEY CLUSTERED ([SequenceId] ASC)
);

