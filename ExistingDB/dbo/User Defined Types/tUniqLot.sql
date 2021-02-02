CREATE TYPE [dbo].[tUniqLot] AS TABLE (
    [UNIQ_LOT]      CHAR (10)       NOT NULL,
    [W_key]         CHAR (10)       DEFAULT ('') NOT NULL,
    [LOTCODE]       CHAR (25)       DEFAULT ('') NOT NULL,
    [PONUM]         CHAR (15)       DEFAULT ('') NOT NULL,
    [EXPDATE]       SMALLDATETIME   NULL,
    [EXPDATEString] CHAR (100)      NULL,
    [Reference]     CHAR (12)       DEFAULT ('') NOT NULL,
    [LOTQTY]        NUMERIC (12, 2) DEFAULT ((0.00)) NOT NULL,
    PRIMARY KEY CLUSTERED ([UNIQ_LOT] ASC));

