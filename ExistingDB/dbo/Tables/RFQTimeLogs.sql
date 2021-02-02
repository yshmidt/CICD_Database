CREATE TABLE [dbo].[RFQTimeLogs] (
    [TimelogId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [RFQId]      BIGINT          NULL,
    [Department] NVARCHAR (50)   NULL,
    [Hours]      NUMERIC (18, 2) NULL,
    CONSTRAINT [PK_RFQTimeLogs] PRIMARY KEY CLUSTERED ([TimelogId] ASC)
);

