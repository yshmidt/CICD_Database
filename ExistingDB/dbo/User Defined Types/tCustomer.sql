CREATE TYPE [dbo].[tCustomer] AS TABLE (
    [custno]   CHAR (10) DEFAULT ('') NOT NULL,
    [custname] CHAR (50) DEFAULT ('') NOT NULL,
    PRIMARY KEY CLUSTERED ([custno] ASC));

