-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/31/2011
-- Description:	Get AP transactions for release (exclude prepay and DM)
-- Modification:
--	09/22/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added functional and presentation currency fields 
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownPurch]
	-- Add the parameters for the stored procedure here
	@UniqApHead char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 05/27/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
    -- Insert statements for procedure here
	SELECT Trans_dt, SupName , INVDATE,APTYPE,APDETAIL.ITEM_DESC, 
		PoNum , InvNo, InvAmount ,ApMaster.Tax,UNIQAPDETL,apmaster.Freight,ApDetail.is_tax,ApDetail.tax_pct,
		apmaster.UniqApHead ,ApDetail.Qty_each,ApDetail.Price_each,Apdetail.ITEM_TOTAL,
		InvAmountFC, ApMaster.TaxFC, apmaster.FreightFC, ApDetail.Price_eachFC, Apdetail.ITEM_TOTALFC
	FROM ApMaster INNER JOIN  SupInfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
	INNER JOIN ApDetail ON ApMaster.UniqApHead=ApDetail.UniqApHead
	where APMASTER.UNIQAPHEAD =@UniqApHead
ELSE
	-- 12/13/16 VL: added functional and presentation currency fields
    -- Insert statements for procedure here
	SELECT Trans_dt, SupName , INVDATE,APTYPE,APDETAIL.ITEM_DESC, 
		PoNum , InvNo, InvAmount ,ApMaster.Tax,UNIQAPDETL,apmaster.Freight,ApDetail.is_tax,ApDetail.tax_pct,
		apmaster.UniqApHead ,ApDetail.Qty_each,ApDetail.Price_each,Apdetail.ITEM_TOTAL, FF.Symbol AS Functional_Currency,
		InvAmountFC, ApMaster.TaxFC, apmaster.FreightFC, ApDetail.Price_eachFC, Apdetail.ITEM_TOTALFC, TF.Symbol AS Transaction_Currency,
		InvAmountPR, ApMaster.TaxPR, apmaster.FreightPR, ApDetail.Price_eachPR, Apdetail.ITEM_TOTALPR, PF.Symbol AS Presentation_Currency
	FROM Apmaster
		INNER JOIN Fcused TF ON Apmaster.Fcused_uniq = TF.Fcused_uniq
		INNER JOIN Fcused PF ON Apmaster.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON Apmaster.FuncFcused_uniq = FF.Fcused_uniq
	INNER JOIN  SupInfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
	INNER JOIN ApDetail ON ApMaster.UniqApHead=ApDetail.UniqApHead
	where APMASTER.UNIQAPHEAD =@UniqApHead
END