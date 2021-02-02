CREATE TABLE [dbo].[PaymentProcessDate] (
    [PaymentProcessDateUniq] CHAR (10)        CONSTRAINT [DF__PaymentPr__Payme__2E20A04C] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [FromDate]               SMALLDATETIME    NOT NULL,
    [ToDate]                 SMALLDATETIME    NOT NULL,
    [DeptName]               CHAR (25)        NOT NULL,
    [PeriodType]             CHAR (15)        NOT NULL,
    [ProcessedDate]          SMALLDATETIME    CONSTRAINT [DF__PaymentPr__Proce__2F14C485] DEFAULT (getdate()) NOT NULL,
    [ProcessedBy]            UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK__PaymentP__AE6145EFD6689CCC] PRIMARY KEY CLUSTERED ([PaymentProcessDateUniq] ASC)
);

