﻿CREATE TYPE [dbo].[tKamain] AS TABLE (
    [Dept_id]    VARCHAR (10) NULL,
    [Uniq_key]   VARCHAR (10) NULL,
    [BomParent]  VARCHAR (10) NULL,
    [Qty]        NUMERIC (13) NULL,
    [ShortQty]   NUMERIC (13) NULL,
    [Used_inKit] VARCHAR (10) NULL,
    [Part_Sourc] VARCHAR (20) NULL,
    [Part_no]    VARCHAR (35) NULL,
    [Revision]   VARCHAR (20) NULL,
    [Descript]   VARCHAR (55) NULL,
    [Part_class] VARCHAR (30) NULL,
    [Part_type]  VARCHAR (20) NULL,
    [U_of_meas]  VARCHAR (20) NULL,
    [Scrap]      NUMERIC (20) NULL,
    [SetupScrap] VARCHAR (20) NULL,
    [CustPartNo] VARCHAR (20) NULL,
    [SerialYes]  BIT          NULL,
    [Qty_Each]   NUMERIC (13) NULL,
    [UniqueId]   VARCHAR (20) NULL);

