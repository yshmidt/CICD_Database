CREATE TABLE [dbo].[inspectionHeader] (
    [inspHeaderId]     CHAR (10)        NOT NULL,
    [receiverDetId]    CHAR (10)        CONSTRAINT [DF_inspectionHeader_linkToReceiving] DEFAULT ('') NOT NULL,
    [inspectedQty]     NUMERIC (12, 2)  CONSTRAINT [DF_inspectionHeader_inspectedQty] DEFAULT ((0.00)) NOT NULL,
    [FailedQty]        NUMERIC (12, 2)  CONSTRAINT [DF_inspectionHeader_FailedQty] DEFAULT ((0.00)) NOT NULL,
    [RejectedAt]       NVARCHAR (50)    CONSTRAINT [DF_inspectionHeader_RejectedAt] DEFAULT ('') NOT NULL,
    [ReturnQty]        NUMERIC (12, 2)  CONSTRAINT [DF_inspectionHeader_ReturnQty] DEFAULT ((0.00)) NOT NULL,
    [FRSTARTCHK]       BIT              CONSTRAINT [DF_inspectionHeader_FRSTARTCHK] DEFAULT ((0)) NOT NULL,
    [INSPCHK]          BIT              CONSTRAINT [DF_inspectionHeader_INSPCHK] DEFAULT ((0)) NOT NULL,
    [CERTCHK]          BIT              CONSTRAINT [DF_inspectionHeader_CERTCHK] DEFAULT ((0)) NOT NULL,
    [FRSTARTDISP]      NVARCHAR (15)    CONSTRAINT [DF_inspectionHeader_FRSTARTDISP] DEFAULT ('') NOT NULL,
    [FRSTARTNOTE]      NVARCHAR (MAX)   CONSTRAINT [DF_inspectionHeader_FRSTARTNOTE] DEFAULT ('') NOT NULL,
    [inspectionStatus] NVARCHAR (20)    CONSTRAINT [DF_inspectionHeader_inspectionStatus] DEFAULT ('') NOT NULL,
    [inspectorId]      UNIQUEIDENTIFIER NULL,
    [inspectionDate]   SMALLDATETIME    CONSTRAINT [DF_inspectionHeader_inspectionDate] DEFAULT (getdate()) NULL,
    [BuyerAction]      NVARCHAR (50)    CONSTRAINT [DF_inspectionHeader_BuyerAction] DEFAULT ('') NOT NULL,
    [BuyerActDate]     SMALLDATETIME    NULL,
    [BuyerActID]       UNIQUEIDENTIFIER NULL,
    [Buyer_Accept]     DECIMAL (12, 2)  CONSTRAINT [DF__inspectio__Buyer__692B8C2A] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_inspectionHeader] PRIMARY KEY CLUSTERED ([inspHeaderId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_InspHdr_Link]
    ON [dbo].[inspectionHeader]([receiverDetId] ASC);

