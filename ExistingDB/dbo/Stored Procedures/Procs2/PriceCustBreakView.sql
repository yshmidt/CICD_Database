-- =============================================
-- Author:		Vicky Lu
-- Create date: 12/02/2019
-- Description:	Get PriceCustBreak records for uniq_key, Custno, used in SO module (desktop)
-- Modified: 
-- =============================================
CREATE PROCEDURE [dbo].[PriceCustBreakView] @lcUniq_key AS char(10) = '',@lcCustno char(10) = ''
AS
SELECT Uniq_key, Custno, pcb.UniqPrCustId, pcb.UniqPrHead, pcb.UniqPrCustBrkId, FromQty, ToQty, pcb.Amount
	FROM priceheader PH 
	INNER JOIN PriceCustomer pc ON pc.UniqPrHead = ph.UniqPrHead			
	INNER JOIN PriceCustbreak pcb ON pcb.UniqPrHead = ph.UniqPrHead AND pc.UniqPrCustId = pcb.UniqPrCustId      
	WHERE Uniq_key = @lcUniq_key AND pc.Custno = @lcCustno
	ORDER BY FromQty