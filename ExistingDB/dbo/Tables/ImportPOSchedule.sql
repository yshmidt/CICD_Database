CREATE TABLE [dbo].[ImportPOSchedule] (
    [POScheduleId]  UNIQUEIDENTIFIER CONSTRAINT [DF__ImportPOS__POSch__5B533976] DEFAULT (newsequentialid()) NOT NULL,
    [fkPOImportId]  UNIQUEIDENTIFIER NOT NULL,
    [fkRowId]       UNIQUEIDENTIFIER NOT NULL,
    [fkFieldDefId]  UNIQUEIDENTIFIER NOT NULL,
    [ScheduleRowId] UNIQUEIDENTIFIER NOT NULL,
    [UniqDetNo]     VARCHAR (10)     NULL,
    [Original]      NVARCHAR (MAX)   NOT NULL,
    [Adjusted]      NVARCHAR (MAX)   NOT NULL,
    [Status]        VARCHAR (10)     CONSTRAINT [DF__ImportPOS__Statu__5C475DAF] DEFAULT ('') NOT NULL,
    [Validation]    VARCHAR (10)     CONSTRAINT [DF__ImportPOS__Valid__5D3B81E8] DEFAULT ('') NOT NULL,
    [Message]       NVARCHAR (MAX)   CONSTRAINT [DF__ImportPOS__Messa__5E2FA621] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK__ImportPO__8F6A87638037873A] PRIMARY KEY CLUSTERED ([POScheduleId] ASC),
    CONSTRAINT [FK__ImportPOS__fkFie__6017EE93] FOREIGN KEY ([fkFieldDefId]) REFERENCES [dbo].[ImportFieldDefinitions] ([FieldDefId]),
    CONSTRAINT [FK__ImportPOS__fkPOI__5F23CA5A] FOREIGN KEY ([fkPOImportId]) REFERENCES [dbo].[ImportPOMain] ([POImportId])
);

