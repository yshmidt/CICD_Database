CREATE TABLE [dbo].[mnxMSLLevel] (
    [MSL]            NVARCHAR (3)  CONSTRAINT [DF_mnxMSLLevel_MSL] DEFAULT ('') NOT NULL,
    [LEVEL]          NVARCHAR (10) CONSTRAINT [DF_mnxMSLLevel_LEVEL] DEFAULT ('') NOT NULL,
    [FloorTime]      NVARCHAR (30) CONSTRAINT [DF_mnxMSLLevel_FloorTime] DEFAULT ('') NOT NULL,
    [CondDegree]     NVARCHAR (50) CONSTRAINT [DF_mnxMSLLevel_CondDegree] DEFAULT ('') NOT NULL,
    [Hours]          INT           CONSTRAINT [DF_mnxMSLLevel_Hours] DEFAULT ((0)) NULL,
    [MSLlevelUnique] INT           IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_mnxMSLLevel] PRIMARY KEY CLUSTERED ([MSLlevelUnique] ASC)
);

