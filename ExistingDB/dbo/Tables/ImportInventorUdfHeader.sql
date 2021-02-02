CREATE TABLE [dbo].[ImportInventorUdfHeader] (
    [ImportId]   UNIQUEIDENTIFIER CONSTRAINT [DF__ImportInv__Impor__78647970] DEFAULT (newid()) NOT NULL,
    [UserId]     UNIQUEIDENTIFIER NOT NULL,
    [ImportDt]   SMALLDATETIME    CONSTRAINT [DF__ImportInv__Impor__79589DA9] DEFAULT (getdate()) NULL,
    [FileName]   NVARCHAR (100)   NOT NULL,
    [CompleteBy] UNIQUEIDENTIFIER NULL,
    [CompleteDt] SMALLDATETIME    CONSTRAINT [DF__ImportInv__Compl__7A4CC1E2] DEFAULT ('') NULL,
    [Status]     VARCHAR (50)     CONSTRAINT [DF__ImportInv__Statu__7B40E61B] DEFAULT ('started') NOT NULL,
    [Validated]  BIT              CONSTRAINT [DF__ImportInv__Valid__7C350A54] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__ImportIn__869767EA226C76F5] PRIMARY KEY CLUSTERED ([ImportId] ASC)
);

