CREATE TABLE [dbo].[mnxcashFlowActivities] (
    [cashActName]        NVARCHAR (50) NULL,
    [IsAdjustment]       BIT           CONSTRAINT [DF_mnxcashFlowActivities_IsAdjustment] DEFAULT ((0)) NOT NULL,
    [isUse]              BIT           CONSTRAINT [DF_mnxcashFlowActivities_isUse] DEFAULT ((0)) NOT NULL,
    [seqNumber]          INT           CONSTRAINT [DF_mnxcashFlowActivities_seqNumber] DEFAULT ((0)) NOT NULL,
    [parentActivityName] NVARCHAR (50) CONSTRAINT [DF_mnxcashFlowActivities_parentActivityName] DEFAULT ('') NOT NULL,
    [cashFlowActCode]    INT           IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_mnxcashFlowActivities] PRIMARY KEY CLUSTERED ([cashFlowActCode] ASC)
);

