CREATE TYPE [dbo].[tComponentsIssue2Kit] AS TABLE (
    [PkCompIssueHeader] CHAR (10)       NOT NULL,
    [Uniq_key]          CHAR (10)       DEFAULT ('') NOT NULL,
    [W_key]             CHAR (10)       DEFAULT ('') NOT NULL,
    [QtyIssued]         NUMERIC (12, 2) DEFAULT ((0.00)) NOT NULL,
    [KaSeqnum]          CHAR (10)       DEFAULT ('') NOT NULL,
    [UNIQ_LOT]          CHAR (10)       DEFAULT ('') NOT NULL,
    PRIMARY KEY CLUSTERED ([PkCompIssueHeader] ASC));

