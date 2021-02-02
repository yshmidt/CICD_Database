CREATE TABLE [dbo].[ImportInvtFields] (
    [DetailId]     UNIQUEIDENTIFIER CONSTRAINT [DF_ImportInvtFields_detailId] DEFAULT (newsequentialid()) NOT NULL,
    [FkImportId]   UNIQUEIDENTIFIER NOT NULL,
    [RowId]        UNIQUEIDENTIFIER NOT NULL,
    [FkFieldDefId] UNIQUEIDENTIFIER NOT NULL,
    [Lock]         BIT              CONSTRAINT [DF_ImportInvtFields_lock] DEFAULT ((0)) NOT NULL,
    [Original]     NVARCHAR (MAX)   CONSTRAINT [DF_ImportInvtFields_original] DEFAULT ('') NOT NULL,
    [Adjusted]     NVARCHAR (MAX)   CONSTRAINT [DF_ImportInvtFields_adjusted] DEFAULT ('') NOT NULL,
    [Status]       VARCHAR (10)     CONSTRAINT [DF_ImportInvtFields_status] DEFAULT ('i02fade') NOT NULL,
    [Validation]   VARCHAR (10)     CONSTRAINT [DF_ImportInvtFields_validation] DEFAULT ('00none') NOT NULL,
    [Message]      VARCHAR (MAX)    CONSTRAINT [DF_ImportInvtFields_message] DEFAULT ('') NOT NULL,
    [IsUploaded]   BIT              CONSTRAINT [DF_ImportInvtFields_IsUploaded] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ImportInvtFields] PRIMARY KEY CLUSTERED ([DetailId] ASC),
    CONSTRAINT [FK_ImportInvtFields_ImportFieldDefinitions] FOREIGN KEY ([FkFieldDefId]) REFERENCES [dbo].[ImportFieldDefinitions] ([FieldDefId]),
    CONSTRAINT [FK_ImportInvtFields_InvtImportHeader] FOREIGN KEY ([FkImportId]) REFERENCES [dbo].[InvtImportHeader] ([InvtImportId])
);

