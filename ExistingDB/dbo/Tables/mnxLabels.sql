CREATE TABLE [dbo].[mnxLabels] (
    [LabelSize]     NVARCHAR (50) CONSTRAINT [DF_mnxLabels_LabelSize] DEFAULT ('') NOT NULL,
    [LabelType]     NVARCHAR (50) CONSTRAINT [DF_mnxLabels_LabelType] DEFAULT ('') NOT NULL,
    [numberRows]    INT           CONSTRAINT [DF_mnxLabels_numberRows] DEFAULT ((1)) NOT NULL,
    [numberColumns] INT           CONSTRAINT [DF_mnxLabels_numberColumns] DEFAULT ((1)) NOT NULL,
    [lblId]         INT           IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_mnxLabels] PRIMARY KEY CLUSTERED ([lblId] ASC)
);

