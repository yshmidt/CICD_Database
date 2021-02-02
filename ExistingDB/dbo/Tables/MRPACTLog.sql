CREATE TABLE [dbo].[MRPACTLog] (
    [MRPActUniqKey] NVARCHAR (10)    NOT NULL,
    [Uniq_key]      VARCHAR (10)     NULL,
    [Action]        CHAR (15)        NULL,
    [Ref]           CHAR (25)        NULL,
    [WONO]          CHAR (10)        NULL,
    [Balance]       NUMERIC (9)      NULL,
    [ReqQty]        NUMERIC (9)      NULL,
    [DueDate]       SMALLDATETIME    NULL,
    [ReqDate]       SMALLDATETIME    NULL,
    [Days]          NUMERIC (4)      NULL,
    [ActDate]       SMALLDATETIME    NULL,
    [ActUserId]     UNIQUEIDENTIFIER NULL,
    [DttAkeact]     SMALLDATETIME    NULL,
    [ActionStatus]  VARCHAR (15)     NULL,
    [MFGRS]         NVARCHAR (MAX)   NULL,
    [EmailStatus]   BIT              NULL,
    CONSTRAINT [PK_MRPACTLog] PRIMARY KEY CLUSTERED ([MRPActUniqKey] ASC)
);

