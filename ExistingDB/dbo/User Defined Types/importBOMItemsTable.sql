﻿CREATE TYPE [dbo].[importBOMItemsTable] AS TABLE (
    [rowId]        UNIQUEIDENTIFIER NOT NULL,
    [itemno]       VARCHAR (10)     NOT NULL,
    [used]         VARCHAR (10)     NOT NULL,
    [partSource]   VARCHAR (50)     NOT NULL,
    [make_buy]     VARCHAR (50)     NULL,
    [qty]          VARCHAR (50)     NOT NULL,
    [custPartNo]   VARCHAR (50)     NOT NULL,
    [crev]         VARCHAR (50)     NOT NULL,
    [descript]     VARCHAR (100)    NOT NULL,
    [u_of_m]       VARCHAR (50)     NOT NULL,
    [partClass]    VARCHAR (50)     NOT NULL,
    [partType]     VARCHAR (50)     NOT NULL,
    [warehouse]    VARCHAR (50)     NOT NULL,
    [partno]       VARCHAR (50)     NOT NULL,
    [rev]          VARCHAR (50)     NOT NULL,
    [deptId]       VARCHAR (50)     NOT NULL,
    [standardCost] VARCHAR (50)     NOT NULL,
    [refdesg]      VARCHAR (MAX)    NULL,
    PRIMARY KEY CLUSTERED ([rowId] ASC));
