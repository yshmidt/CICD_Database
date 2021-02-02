CREATE TABLE [dbo].[DeptLgtHistory] (
    [DeptLgtHistoryUniq] CHAR (10)        CONSTRAINT [DF__DeptLgtHi__DeptL__23A311D9] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [UniqLogin]          CHAR (10)        NOT NULL,
    [TMLOGTPUK]          CHAR (10)        NULL,
    [LogTypeTime]        INT              NULL,
    [DateIn]             DATETIME         NULL,
    [DateOut]            DATETIME         NULL,
    [TotalTime]          INT              CONSTRAINT [DF__DeptLgtHi__Total__24973612] DEFAULT ((0)) NULL,
    [IsDeleted]          BIT              NULL,
    [ModifiedBy]         UNIQUEIDENTIFIER NULL,
    [ModifiedDate]       DATETIME         CONSTRAINT [DF__DeptLgtHi__Modif__258B5A4B] DEFAULT (getdate()) NULL
);

