CREATE TABLE [dbo].[RFQPriceBreaks] (
    [QtyId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [RFQId]        BIGINT          NULL,
    [Selected]     BIT             NULL,
    [Qty]          NUMERIC (8)     NULL,
    [LeadTime]     INT             NULL,
    [LeadTimeUnit] NVARCHAR (10)   NULL,
    [MaterialCost] NUMERIC (18, 3) NULL,
    [LaborCost]    NUMERIC (18, 3) NULL,
    [OtherCost]    NUMERIC (18, 3) NULL,
    [Markup]       NUMERIC (18, 3) NULL,
    [UnitPrice]    NUMERIC (18, 3) NULL,
    [NRE]          NUMERIC (18, 3) NULL,
    CONSTRAINT [PK_RFQPriceBreaks] PRIMARY KEY CLUSTERED ([QtyId] ASC)
);

