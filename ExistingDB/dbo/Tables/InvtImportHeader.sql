CREATE TABLE [dbo].[InvtImportHeader] (
    [InvtImportId]   UNIQUEIDENTIFIER CONSTRAINT [DF_InvtImportHeader_detailId] DEFAULT (newsequentialid()) NOT NULL,
    [ImportUserId]   UNIQUEIDENTIFIER NULL,
    [ImportDate]     DATETIME         CONSTRAINT [DF_InvtImportHeader_ImportDate] DEFAULT (getdate()) NULL,
    [ImportComplete] BIT              CONSTRAINT [DF_InvtImportHeader_ImportComplete] DEFAULT ((0)) NOT NULL,
    [ImportType]     CHAR (1)         CONSTRAINT [DF__ImportBeg__impor__273D01] DEFAULT ('P') NOT NULL,
    [RecPklNo]       NVARCHAR (50)    NULL,
    [Carrier]        NVARCHAR (30)    NULL,
    [WayBill]        NVARCHAR (100)   NULL,
    [Reason]         NVARCHAR (120)   NULL,
    [IsValidate]     BIT              NULL,
    [CompanyName]    VARCHAR (50)     CONSTRAINT [DF__InvtImpor__Compa__3953272D] DEFAULT ('') NULL,
    [CompanyNo]      VARCHAR (10)     CONSTRAINT [DF__InvtImpor__Compa__3A474B66] DEFAULT ('') NULL,
    [ContractNo]     NVARCHAR (20)    CONSTRAINT [DF__InvtImpor__Contr__631456CF] DEFAULT ('') NULL,
    CONSTRAINT [PK_InvtImportHeader] PRIMARY KEY CLUSTERED ([InvtImportId] ASC)
);

