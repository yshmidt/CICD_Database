CREATE TYPE [dbo].[tPOSchedule] AS TABLE (
    [ScheduleRowId] UNIQUEIDENTIFIER NULL,
    [ImportId]      UNIQUEIDENTIFIER NULL,
    [fkRowId]       UNIQUEIDENTIFIER NULL,
    [CssClass]      CHAR (10)        NULL,
    [Validation]    CHAR (10)        NULL,
    [UniqDetNo]     CHAR (10)        NULL,
    [GLNBR]         VARCHAR (100)    NULL,
    [LOCATION]      CHAR (256)       NULL,
    [ORIGCOMMITDT]  SMALLDATETIME    NULL,
    [WOPRJNUMBER]   CHAR (10)        NULL,
    [REQUESTTP]     CHAR (10)        NULL,
    [REQUESTOR]     CHAR (40)        NULL,
    [SCHDDATE]      SMALLDATETIME    NULL,
    [SCHDQTY]       CHAR (10)        NULL,
    [WAREHOUSE]     CHAR (10)        NULL);

