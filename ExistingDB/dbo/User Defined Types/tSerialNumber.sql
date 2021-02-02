CREATE TYPE [dbo].[tSerialNumber] AS TABLE (
    [SerialUniq]  CHAR (10) NULL,
    [SerialNo]    CHAR (10) NULL,
    [Uniq_key]    CHAR (10) DEFAULT ('') NOT NULL,
    [UniqMfgrHd]  CHAR (10) NULL,
    [IpKeyUnique] CHAR (10) NULL,
    [IsChecked]   BIT       DEFAULT ((0)) NULL);

