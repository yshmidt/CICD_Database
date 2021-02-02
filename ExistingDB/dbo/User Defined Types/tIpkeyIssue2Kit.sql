CREATE TYPE [dbo].[tIpkeyIssue2Kit] AS TABLE (
    [PkIpKeyIssued]     CHAR (10)       NOT NULL,
    [FkCompIssueHeader] CHAR (10)       NOT NULL,
    [ipKeyUnique]       CHAR (10)       NOT NULL,
    [ipKeyQtyIssued]    NUMERIC (12, 2) DEFAULT ((0.00)) NOT NULL,
    PRIMARY KEY CLUSTERED ([PkIpKeyIssued] ASC));

