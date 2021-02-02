CREATE TYPE [dbo].[timportJE] AS TABLE (
    [JE_NO]       NUMERIC (6)     NOT NULL,
    [TRANSDATE]   SMALLDATETIME   NULL,
    [App_dt]      SMALLDATETIME   NULL,
    [SAVEINIT]    CHAR (8)        NULL,
    [REASON]      VARCHAR (MAX)   NOT NULL,
    [STATUS]      CHAR (12)       NOT NULL,
    [JETYPE]      CHAR (10)       NOT NULL,
    [GL_NBR]      CHAR (13)       NOT NULL,
    [DEBIT]       NUMERIC (14, 2) NOT NULL,
    [CREDIT]      NUMERIC (14, 2) NOT NULL,
    [DEBITFC]     NUMERIC (14, 2) NOT NULL,
    [CREDITFC]    NUMERIC (14, 2) NOT NULL,
    [DEBITPR]     NUMERIC (14, 2) NOT NULL,
    [CREDITPR]    NUMERIC (14, 2) NOT NULL,
    [FCUSED_UNIQ] CHAR (10)       NULL,
    [FCHIST_KEY]  CHAR (10)       NULL,
    [SYMBOL]      CHAR (3)        NOT NULL);

