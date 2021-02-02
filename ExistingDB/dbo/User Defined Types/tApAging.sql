﻿CREATE TYPE [dbo].[tApAging] AS TABLE (
    [SupName]   CHAR (30)       NULL,
    [InvNo]     CHAR (50)       NULL,
    [InvDate]   SMALLDATETIME   NULL,
    [Due_Date]  SMALLDATETIME   NULL,
    [Trans_Dt]  SMALLDATETIME   NULL,
    [PoNum]     CHAR (15)       NULL,
    [InvAmount] NUMERIC (12, 2) NULL,
    [BalAmt]    NUMERIC (12, 2) NULL,
    [ApStatus]  CHAR (15)       NULL,
    [Current]   NUMERIC (12, 2) NULL,
    [Range1]    NUMERIC (12, 2) NULL,
    [Range2]    NUMERIC (12, 2) NULL,
    [Range3]    NUMERIC (12, 2) NULL,
    [Range4]    NUMERIC (12, 2) NULL,
    [Over]      NUMERIC (12, 2) NULL,
    [R1Start]   NUMERIC (3)     NULL,
    [R1end]     NUMERIC (3)     NULL,
    [R2Start]   NUMERIC (3)     NULL,
    [R2End]     NUMERIC (3)     NULL,
    [R3Start]   NUMERIC (3)     NULL,
    [R3End]     NUMERIC (3)     NULL,
    [R4Start]   NUMERIC (3)     NULL,
    [R4End]     NUMERIC (3)     NULL,
    [UniqSupno] CHAR (10)       NULL,
    [Phone]     CHAR (19)       NULL,
    [Terms]     CHAR (15)       NULL,
    [AsofDate]  SMALLDATETIME   NULL);
