CREATE TYPE [dbo].[tSupplier] AS TABLE (
    [uniqsupno] CHAR (10) NOT NULL,
    [supname]   CHAR (50) NULL,
    PRIMARY KEY CLUSTERED ([uniqsupno] ASC));

