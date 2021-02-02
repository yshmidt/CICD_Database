CREATE TYPE [dbo].[tMrpUserFields] AS TABLE (
    [UniqMRPAct]   CHAR (10)       NULL,
    [UniqKey]      CHAR (10)       NULL,
    [UserReqQty]   NUMERIC (9)     NULL,
    [UserPrice]    NUMERIC (13, 5) NULL,
    [UserPartMfgr] VARCHAR (8)     NULL,
    [UserMfgrPtNo] VARCHAR (30)    NULL,
    [UniqSupNo]    CHAR (10)       NULL);

