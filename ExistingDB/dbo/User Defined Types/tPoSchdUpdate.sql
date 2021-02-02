CREATE TYPE [dbo].[tPoSchdUpdate] AS TABLE (
    [ponum]     CHAR (15)     DEFAULT ('') NOT NULL,
    [supname]   CHAR (50)     DEFAULT ('') NOT NULL,
    [itemno]    CHAR (3)      DEFAULT ('') NOT NULL,
    [part_no]   CHAR (25)     DEFAULT ('') NOT NULL,
    [revision]  CHAR (4)      DEFAULT ('') NOT NULL,
    [uniqdetno] CHAR (10)     DEFAULT ('') NOT NULL,
    [schd_date] SMALLDATETIME NULL,
    PRIMARY KEY CLUSTERED ([uniqdetno] ASC));

