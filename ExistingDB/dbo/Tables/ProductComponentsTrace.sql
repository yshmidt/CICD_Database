CREATE TABLE [dbo].[ProductComponentsTrace] (
    [productCompUk]   UNIQUEIDENTIFIER CONSTRAINT [DF_ProductComponentsTrace_productCompUk] DEFAULT (newid()) NOT NULL,
    [productSerialNo] VARCHAR (30)     CONSTRAINT [DF_ProductComponentsTrace_productSerialNo] DEFAULT ('') NOT NULL,
    [wono]            CHAR (10)        CONSTRAINT [DF_ProductComponentsTrace_wono] DEFAULT ('') NOT NULL,
    [uniqmfgrhd]      CHAR (10)        CONSTRAINT [DF_ProductComponentsTrace_uniqmfgrhd] DEFAULT ('') NOT NULL,
    [ipkeyunique]     CHAR (10)        CONSTRAINT [DF_ProductComponentsTrace_ipkey] DEFAULT ('') NOT NULL,
    [qtyConsumed]     NUMERIC (12, 2)  CONSTRAINT [DF_ProductComponentsTrace_qtyConsumed] DEFAULT ((0)) NOT NULL,
    [assignedDate]    SMALLDATETIME    CONSTRAINT [DF_ProductComponentsTrace_assignedDate] DEFAULT (getdate()) NULL,
    [user_id]         UNIQUEIDENTIFIER NULL,
    [dept_id]         CHAR (4)         CONSTRAINT [DF_ProductComponentsTrace_dept_id] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ProductComponentsTrace] PRIMARY KEY CLUSTERED ([productCompUk] ASC)
);


GO
CREATE NONCLUSTERED INDEX [wono]
    ON [dbo].[ProductComponentsTrace]([wono] ASC);


GO
CREATE NONCLUSTERED INDEX [dept_id]
    ON [dbo].[ProductComponentsTrace]([dept_id] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[ProductComponentsTrace]([ipkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ProductComponentsTrace]
    ON [dbo].[ProductComponentsTrace]([productSerialNo] ASC);

