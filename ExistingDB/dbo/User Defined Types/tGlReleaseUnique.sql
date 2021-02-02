CREATE TYPE [dbo].[tGlReleaseUnique] AS TABLE (
    [glrelunique]  CHAR (10)        NOT NULL,
    [trans_dt]     SMALLDATETIME    NULL,
    [FY]           CHAR (4)         DEFAULT ('') NULL,
    [Period]       NUMERIC (2)      DEFAULT ((0)) NULL,
    [fk_fydtluniq] UNIQUEIDENTIFIER NULL);

