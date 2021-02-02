CREATE TYPE [dbo].[timportBOMAvl] AS TABLE (
    [importId]   UNIQUEIDENTIFIER NULL,
    [rowId]      UNIQUEIDENTIFIER NULL,
    [AvlRowId]   UNIQUEIDENTIFIER NULL,
    [class]      VARCHAR (10)     NULL,
    [validation] VARCHAR (10)     NULL,
    [UniqWh]     CHAR (10)        NULL,
    [Uniq_key]   CHAR (10)        NULL,
    [UniqMfgrhd] CHAR (10)        NULL,
    [Bom]        BIT              DEFAULT ((0)) NULL,
    [Load]       BIT              DEFAULT ((0)) NULL,
    [MatlType]   VARCHAR (MAX)    NULL,
    [location]   VARCHAR (MAX)    NULL,
    [Mfgr_pt_no] VARCHAR (MAX)    NULL,
    [PartMfgr]   VARCHAR (MAX)    NULL,
    [preference] VARCHAR (MAX)    NULL);

