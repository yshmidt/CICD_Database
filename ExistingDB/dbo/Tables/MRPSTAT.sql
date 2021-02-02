CREATE TABLE [dbo].[MRPSTAT] (
    [nProgress]  INT      CONSTRAINT [DF_MRPSTAT_nProgress] DEFAULT ((0)) NOT NULL,
    [dtTime0]    DATETIME NULL,
    [nSeconds0]  INT      CONSTRAINT [DF_Table_1_nSeconds] DEFAULT ((0)) NOT NULL,
    [dtTime1]    DATETIME NULL,
    [nSeconds1]  INT      CONSTRAINT [DF_MRPSTAT_nSeconds1] DEFAULT ((0)) NOT NULL,
    [cFlag]      CHAR (3) CONSTRAINT [DF_MRPSTAT_cFlag] DEFAULT ('') NOT NULL,
    [MrpStatKey] INT      IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_MRPSTAT] PRIMARY KEY CLUSTERED ([MrpStatKey] ASC)
);

