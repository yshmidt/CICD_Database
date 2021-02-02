CREATE TYPE [dbo].[tPoRecser] AS TABLE (
    [PoserUnique]   CHAR (10) NULL,
    [Loc_Uniq]      CHAR (10) NULL,
    [Lot_Uniq]      CHAR (10) NULL,
    [SerialNo]      CHAR (30) DEFAULT ('') NOT NULL,
    [ReceiverNo]    CHAR (10) NULL,
    [FK_SerialUniq] CHAR (10) NULL,
    [SourceDev]     CHAR (1)  NULL,
    [IpkeyUnique]   CHAR (10) NULL,
    [Start_Range]   CHAR (30) NULL,
    [End_Range]     CHAR (30) NULL);

