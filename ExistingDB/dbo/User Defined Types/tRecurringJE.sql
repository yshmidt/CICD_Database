CREATE TYPE [dbo].[tRecurringJE] AS TABLE (
    [UniqeId]   VARCHAR (10)  NULL,
    [Glrhdrkey] CHAR (10)     NULL,
    [Recref]    CHAR (50)     NULL,
    [NextDate]  SMALLDATETIME NULL,
    [Period]    NUMERIC (18)  NULL,
    [FY]        CHAR (100)    NULL,
    [SaveInit]  CHAR (10)     NULL,
    [Recdescr]  CHAR (100)    NULL,
    [Frequency] CHAR (20)     NULL,
    [IsChecked] BIT           NULL,
    [Reason]    VARCHAR (MAX) NULL);

