CREATE TYPE [dbo].[tMrpHorizontal] AS TABLE (
    [Uniq_key]   CHAR (10)       NULL,
    [nSeqNumber] INT             NULL,
    [TYPE]       VARCHAR (5)     NULL,
    [FieldName]  VARCHAR (10)    NULL,
    [reqqty]     NUMERIC (15, 2) NULL);

