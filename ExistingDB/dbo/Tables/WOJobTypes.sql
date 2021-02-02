CREATE TABLE [dbo].[WOJobTypes] (
    [JobTypeId]          INT           IDENTITY (1, 1) NOT NULL,
    [JobTypeName]        NVARCHAR (30) NOT NULL,
    [JobTypeValue]       NVARCHAR (30) NULL,
    [JobTypeIsRemovable] BIT           NOT NULL,
    [JobTypeCheckOrder]  INT           NOT NULL,
    CONSTRAINT [PK_WOJobTypes] PRIMARY KEY CLUSTERED ([JobTypeId] ASC)
);

