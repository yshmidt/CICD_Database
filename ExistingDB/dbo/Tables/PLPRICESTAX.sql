CREATE TABLE [dbo].[PLPRICESTAX] (
    [UNIQPLPRICESTAX] CHAR (10)      CONSTRAINT [DF__PLPRICEST__UNIQP__65D88785] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [PACKLISTNO]      CHAR (10)      CONSTRAINT [DF__PLPRICEST__PACKL__66CCABBE] DEFAULT ('') NOT NULL,
    [INV_LINK]        CHAR (10)      CONSTRAINT [DF__PLPRICEST__INV_L__67C0CFF7] DEFAULT ('') NOT NULL,
    [PLUNIQLNK]       CHAR (10)      CONSTRAINT [DF__PLPRICEST__PLUNI__68B4F430] DEFAULT ('') NOT NULL,
    [TAX_ID]          CHAR (8)       CONSTRAINT [DF__PLPRICEST__TAX_I__69A91869] DEFAULT ('') NOT NULL,
    [TAX_RATE]        NUMERIC (8, 4) CONSTRAINT [DF__PLPRICEST__TAX_R__6A9D3CA2] DEFAULT ((0)) NOT NULL,
    [TAXTYPE]         CHAR (1)       CONSTRAINT [DF__PLPRICEST__TAXTY__6B9160DB] DEFAULT ('') NOT NULL,
    [PTPROD]          BIT            CONSTRAINT [DF__PLPRICEST__PTPRO__556D1592] DEFAULT ((0)) NOT NULL,
    [PTFRT]           BIT            CONSTRAINT [DF__PLPRICEST__PTFRT__566139CB] DEFAULT ((0)) NOT NULL,
    [STPROD]          BIT            CONSTRAINT [DF__PLPRICEST__STPRO__57555E04] DEFAULT ((0)) NOT NULL,
    [STFRT]           BIT            CONSTRAINT [DF__PLPRICEST__STFRT__5849823D] DEFAULT ((0)) NOT NULL,
    [STTX]            BIT            CONSTRAINT [DF__PLPRICESTA__STTX__593DA676] DEFAULT ((0)) NOT NULL,
    [SetupTaxType]    CHAR (15)      CONSTRAINT [DF__PLPRICEST__Setup__61CB2CDB] DEFAULT ('') NOT NULL,
    [TaxApplicableTo] CHAR (10)      CONSTRAINT [DF__PLPRICEST__TaxAp__62BF5114] DEFAULT ('') NOT NULL,
    [IsFreightTotals] BIT            CONSTRAINT [DF__PLPRICEST__IsFre__63B3754D] DEFAULT ((0)) NOT NULL,
    [IsProductTotal]  BIT            CONSTRAINT [DF__PLPRICEST__IsPro__64A79986] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__PLPRICES__26A7C8F863F03F13] PRIMARY KEY CLUSTERED ([UNIQPLPRICESTAX] ASC)
);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: <03/14/17>
-- Description:	<trigger for plpricestax to update invoice total>
-- =============================================
CREATE TRIGGER [dbo].[PlpricesTax_Insert_Update_Delete]
   ON  [dbo].[PLPRICESTAX]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	BEGIN TRANSACTION
	DECLARE @lcPacklistno char(10);
	SELECT @lcPacklistno = Packlistno FROM Inserted
	IF @@ROWCOUNT = 0
		BEGIN
		SELECT @lcPacklistno = Packlistno FROM Deleted
		IF @@ROWCOUNT <> 0
			EXEC sp_Invoice_Total @lcPacklistno;
		END
	ELSE
		BEGIN	
			EXEC sp_Invoice_Total @lcPacklistno;
		END
	
	COMMIT
END
