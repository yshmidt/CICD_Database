CREATE TYPE [dbo].[tSerialsIssue2Kit] AS TABLE (
    [PkSerialIssued]    CHAR (10) NOT NULL,
    [FkCompIssueHeader] CHAR (10) NOT NULL,
    [SerialUniq]        CHAR (10) NOT NULL,
    [IpKeyUnique]       CHAR (10) NOT NULL,
    PRIMARY KEY CLUSTERED ([PkSerialIssued] ASC));

