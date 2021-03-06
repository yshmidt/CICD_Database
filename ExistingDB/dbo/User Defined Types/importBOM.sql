﻿CREATE TYPE [dbo].[importBOM] AS TABLE (
    [importId]     UNIQUEIDENTIFIER NULL,
    [rowId]        UNIQUEIDENTIFIER NULL,
    [uniq_key]     CHAR (10)        NULL,
    [UseCustPFX]   BIT              DEFAULT ((0)) NOT NULL,
    [class]        VARCHAR (10)     NULL,
    [validation]   VARCHAR (10)     NULL,
    [assyDesc]     VARCHAR (45)     NULL,
    [assyNum]      VARCHAR (23)     NULL,
    [assyRev]      VARCHAR (8)      NULL,
    [bomNote]      VARCHAR (MAX)    NULL,
    [crev]         VARCHAR (MAX)    NULL,
    [custno]       VARCHAR (MAX)    NULL,
    [custPartNo]   VARCHAR (MAX)    NULL,
    [descript]     VARCHAR (MAX)    NULL,
    [int_uniq]     CHAR (10)        NULL,
    [invNote]      VARCHAR (MAX)    NULL,
    [itemno]       VARCHAR (MAX)    NULL,
    [location]     VARCHAR (MAX)    NULL,
    [make_buy]     VARCHAR (MAX)    NULL,
    [matlType]     VARCHAR (MAX)    NULL,
    [mpn]          VARCHAR (MAX)    NULL,
    [mtc]          VARCHAR (MAX)    NULL,
    [partClass]    VARCHAR (MAX)    NULL,
    [partMfg]      VARCHAR (MAX)    NULL,
    [partno]       VARCHAR (MAX)    NULL,
    [partSource]   VARCHAR (MAX)    NULL,
    [partType]     VARCHAR (MAX)    NULL,
    [preference]   VARCHAR (MAX)    NULL,
    [qty]          VARCHAR (MAX)    NULL,
    [refdesg]      VARCHAR (MAX)    NULL,
    [rev]          VARCHAR (MAX)    NULL,
    [serial]       VARCHAR (MAX)    NULL,
    [standardCost] VARCHAR (MAX)    NULL,
    [u_of_m]       VARCHAR (MAX)    NULL,
    [used]         VARCHAR (MAX)    NULL,
    [warehouse]    VARCHAR (MAX)    NULL,
    [workCenter]   VARCHAR (MAX)    NULL);

