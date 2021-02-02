CREATE TABLE [dbo].[MSLLogs] (
    [Wono]         CHAR (10)   CONSTRAINT [DF_mslLog_Wono] DEFAULT ('') NOT NULL,
    [kaseqnum]     CHAR (10)   CONSTRAINT [DF_mslLog_kaseqnum] DEFAULT ('') NOT NULL,
    [ipkeyunique]  CHAR (10)   CONSTRAINT [DF_mslLog_ipkeyunique] DEFAULT ('') NOT NULL,
    [MSL]          VARCHAR (3) CONSTRAINT [DF_mslLog_MSL] DEFAULT ('') NOT NULL,
    [StartTime]    DATETIME    NULL,
    [StopTime]     DATETIME    NULL,
    [MSLlogUnique] CHAR (10)   CONSTRAINT [DF_mslLog_MSLlogUnique] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    CONSTRAINT [PK_Table_MSLLog] PRIMARY KEY CLUSTERED ([MSLlogUnique] ASC)
);

