CREATE TYPE [dbo].[tAutoDeduct] AS TABLE (
    [Yesno]      BIT             DEFAULT ((0)) NULL,
    [Descript]   CHAR (40)       DEFAULT ('') NULL,
    [CheckDate]  SMALLDATETIME   NULL,
    [CheckAmt]   NUMERIC (10, 2) DEFAULT ((0.00)) NULL,
    [UniqBkAdMn] CHAR (10)       DEFAULT ('') NULL,
    [bk_uniq]    CHAR (10)       DEFAULT ('') NULL,
    [apchk_uniq] CHAR (10)       DEFAULT ('') NULL);

