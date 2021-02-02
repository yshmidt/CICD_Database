CREATE TYPE [dbo].[tMrpAct] AS TABLE (
    [UniqMRPAct]       CHAR (10)        NULL,
    [Ref]              CHAR (25)        NULL,
    [UniqKey]          CHAR (10)        NULL,
    [Balance]          NUMERIC (9)      NULL,
    [ReqQty]           NUMERIC (9)      NULL,
    [Action]           CHAR (15)        NULL,
    [Days]             NUMERIC (4)      NULL,
    [ActionStatus]     VARCHAR (15)     NULL,
    [ActionFailureMsg] VARCHAR (MAX)    NULL,
    [ActUserId]        UNIQUEIDENTIFIER NULL,
    [DtToTak]          VARCHAR (75)     NULL);

