CREATE TABLE [dbo].[ImportBulkInvtHeader] (
    [InvtImportId]        UNIQUEIDENTIFIER NOT NULL,
    [ImportUserId]        UNIQUEIDENTIFIER NULL,
    [ImportDate]          DATETIME         NULL,
    [ImportCompletedDate] DATETIME         NULL,
    [ImportCompleteBy]    UNIQUEIDENTIFIER NULL,
    [ImportComplete]      BIT              CONSTRAINT [DF__ImportBul__Impor__00D9C3E0] DEFAULT ((0)) NOT NULL,
    [IsValidate]          BIT              CONSTRAINT [DF__ImportBul__IsVal__01CDE819] DEFAULT ((0)) NOT NULL,
    [FilePath]            NVARCHAR (MAX)   CONSTRAINT [DF__ImportBul__FileP__02C20C52] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ImportBulkInvtHeader] PRIMARY KEY CLUSTERED ([InvtImportId] ASC)
);

