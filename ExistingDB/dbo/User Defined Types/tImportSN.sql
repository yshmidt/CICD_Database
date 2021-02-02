CREATE TYPE [dbo].[tImportSN] AS TABLE (
    [Wono]      CHAR (10)     NOT NULL,
    [Serialno]  CHAR (30)     NOT NULL,
    [Part_no]   CHAR (25)     NOT NULL,
    [Revision]  CHAR (8)      NOT NULL,
    [LotCode]   CHAR (15)     NOT NULL,
    [ExpDate]   SMALLDATETIME NULL,
    [Reference] CHAR (12)     NOT NULL,
    [Ponum]     CHAR (15)     NULL);

