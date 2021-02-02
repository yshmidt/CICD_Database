CREATE TABLE [dbo].[UDFValues] (
    [UniqueID]        UNIQUEIDENTIFIER CONSTRAINT [DF_UDFValues_UniqueID] DEFAULT (newid()) NOT NULL,
    [fk_fieldListId]  UNIQUEIDENTIFIER NOT NULL,
    [FK_ModuleListId] UNIQUEIDENTIFIER NOT NULL,
    [fk_RecordId]     CHAR (10)        CONSTRAINT [DF_UDFValues_RecordId] DEFAULT ('') NOT NULL,
    [FieldNValue]     NUMERIC (18, 5)  CONSTRAINT [DF_UDFValues_FieldNValue] DEFAULT ((0.00)) NOT NULL,
    [FieldCValue]     NVARCHAR (MAX)   CONSTRAINT [DF_UDFValues_FieldCValue] DEFAULT ('') NOT NULL,
    [FieldLValue]     BIT              CONSTRAINT [DF_UDFValues_FieldLValue] DEFAULT ((0)) NOT NULL,
    [FieldDvalue]     SMALLDATETIME    NULL,
    [RowId]           UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_UDFValues] PRIMARY KEY CLUSTERED ([UniqueID] ASC)
);

