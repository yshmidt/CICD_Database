CREATE TABLE [dbo].[SerialComponentToAssembly] (
    [serialuniq]       CHAR (10)       CONSTRAINT [DF_SerialComponentToAssembly_serialuniq] DEFAULT ('') NOT NULL,
    [serialno]         VARCHAR (30)    CONSTRAINT [DF_SerialComponentToAssembly_serialno] DEFAULT ('') NOT NULL,
    [CompToAssemblyUk] CHAR (10)       CONSTRAINT [DF_SerialComponentToAssembly_CompToAssemblyUk] DEFAULT ('') NOT NULL,
    [uniq_key]         CHAR (10)       CONSTRAINT [DF_SerialComponentToAssembly_uniq_key] DEFAULT ('') NOT NULL,
    [Wono]             CHAR (10)       NOT NULL,
    [PartIpkeyUnique]  CHAR (10)       NULL,
    [PartSerialUnique] CHAR (10)       NULL,
    [PartSerialNo]     CHAR (30)       NULL,
    [QTYISU]           NUMERIC (12, 2) NOT NULL,
    [LOTCODE]          NVARCHAR (25)   NOT NULL,
    [EXPDATE]          SMALLDATETIME   NULL,
    [REFERENCE]        CHAR (12)       NOT NULL,
    [PONUM]            CHAR (15)       NOT NULL,
    [DeptKey]          CHAR (10)       CONSTRAINT [DF__SerialCom__DeptK__7882DE53] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_SerialComponentToAssembly] PRIMARY KEY CLUSTERED ([CompToAssemblyUk] ASC)
);


GO
CREATE NONCLUSTERED INDEX [compuniqkey]
    ON [dbo].[SerialComponentToAssembly]([uniq_key] ASC);


GO
CREATE NONCLUSTERED INDEX [serialno]
    ON [dbo].[SerialComponentToAssembly]([serialno] ASC);


GO
CREATE NONCLUSTERED INDEX [serialuniq]
    ON [dbo].[SerialComponentToAssembly]([serialuniq] ASC);

