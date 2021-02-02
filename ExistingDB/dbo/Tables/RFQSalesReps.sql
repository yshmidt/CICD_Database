CREATE TABLE [dbo].[RFQSalesReps] (
    [RepId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [RFQId]      BIGINT          NULL,
    [Rep]        NVARCHAR (50)   NULL,
    [Fixed]      NUMERIC (18, 3) NULL,
    [Percentage] NUMERIC (18, 3) NULL,
    CONSTRAINT [PK_RFQSalesReps] PRIMARY KEY CLUSTERED ([RepId] ASC)
);

