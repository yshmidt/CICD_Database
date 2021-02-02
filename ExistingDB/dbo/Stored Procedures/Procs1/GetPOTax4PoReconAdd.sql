-- =============================================
-- Author:		Vicky Lu
-- Create date: <11/01/16>
-- Description:	Get PO tax for PO reconciliation add
-- Modified:	
-- =============================================
CREATE PROCEDURE [dbo].[GetPOTax4PoReconAdd] @pcPoNum char(15) = ' ', @pcReceiverNo char(10) = ' '
AS

BEGIN

;WITH zGetAllUniqlnno AS (
	-- Get criteria from [PoReconFindDetailView] and [PoReconNonInvView] used in frmPorecon to get all PO items going to be added
	SELECT Poitems.Uniqlnno 
		FROM PoRecDtl, PoItems, PoRecLoc
		WHERE PoRecDtl.UniqLnNo = PoItems.UniqLnNo 
			AND PoRecLoc.FK_UniqRecDtl = PoRecDtl.UniqRecDtl 
			AND PoRecDtl.ReceiverNo = @pcReceiverNo 
			AND PoItems.PoNum =  @pcPoNum 
			AND PoRecLoc.Sinv_Uniq =' '
			AND PoRecLoc.AccptQty > 0 
)
SELECT DISTINCT PoitemsTax.Uniqlnno, PoitemsTax.Tax_id, PoitemsTax.Tax_rate, Taxdesc
	FROM PoitemsTax INNER JOIN Taxtabl 
	ON PoitemsTax.Tax_id = Taxtabl.Tax_id  
	INNER JOIN zGetAllUniqlnno 
	ON PoitemsTax.Uniqlnno = zGetAllUniqlnno.Uniqlnno
	

END     