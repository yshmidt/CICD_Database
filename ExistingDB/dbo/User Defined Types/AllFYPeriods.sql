CREATE TYPE [dbo].[AllFYPeriods] AS TABLE (
    [FiscalYr]       CHAR (4)         NULL,
    [fk_fy_uniq]     CHAR (10)        NULL,
    [Period]         NUMERIC (2)      NULL,
    [StartDate]      SMALLDATETIME    NULL,
    [EndDate]        SMALLDATETIME    NULL,
    [fyDtlUniq]      UNIQUEIDENTIFIER NULL,
    [RN]             INT              NULL,
    [sequenceNumber] INT              NULL);

