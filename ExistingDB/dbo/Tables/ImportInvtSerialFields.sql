CREATE TABLE [dbo].[ImportInvtSerialFields] (
    [SerialDetailId] UNIQUEIDENTIFIER CONSTRAINT [DF_ImportInvtSerialFields_SerialDetailId] DEFAULT (newsequentialid()) NOT NULL,
    [FkRowId]        UNIQUEIDENTIFIER NOT NULL,
    [RowId]          UNIQUEIDENTIFIER NOT NULL,
    [FkFieldDefId]   UNIQUEIDENTIFIER NOT NULL,
    [Lock]           BIT              CONSTRAINT [DF_ImportInvtSerialFields_lock] DEFAULT ((0)) NOT NULL,
    [Original]       NVARCHAR (MAX)   CONSTRAINT [DF_ImportInvtSerialFields_original] DEFAULT ('') NOT NULL,
    [Adjusted]       NVARCHAR (MAX)   CONSTRAINT [DF_ImportInvtSerialFields_adjusted] DEFAULT ('') NOT NULL,
    [Status]         VARCHAR (10)     CONSTRAINT [DF_ImportInvtSerialFields_status] DEFAULT ('i02fade') NOT NULL,
    [Validation]     VARCHAR (10)     CONSTRAINT [DF_ImportInvtSerialFields_validation] DEFAULT ('00none') NOT NULL,
    [Message]        VARCHAR (MAX)    CONSTRAINT [DF_ImportInvtSerialFields_message] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ImportInvtSerialFields] PRIMARY KEY CLUSTERED ([SerialDetailId] ASC),
    CONSTRAINT [FK_ImportInvtSerialFields_ImportFieldDefinitions] FOREIGN KEY ([FkFieldDefId]) REFERENCES [dbo].[ImportFieldDefinitions] ([FieldDefId])
);

