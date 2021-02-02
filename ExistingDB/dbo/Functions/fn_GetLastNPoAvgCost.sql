-- =============================================
-- Author:		Vicky Lu	
-- Create date: <04/03/2012>
-- Description:	<Return N last PO average cost>
-- Modification:
-- 02/07/17 VL CSI reported an issue that cost roll didn't convert the PUR UOM to Stock UOM when calculating last N PO, here will use fn_convertprice() to update qty
-- 02/21/17 VL found the cost was converted to stock cost, so should multiple with stock order qty:S_ord_qty, but found in some old record the s_ord_qty didn't convert right, so use ord_qty and convert from pum to uom
-- 07/16/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE FUNCTION [dbo].[fn_GetLastNPoAvgCost]
(
	-- Add the parameters for the function here
	@lcUniq_key char(10) = '', 
	@lnNumberOfPOsIncluded int = 5
)
RETURNS numeric(13,5)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @lnReturn numeric(13,5)
	SET @lnReturn = 0.00000
	
	DECLARE @lastNPos TABLE (VerDate SmallDateTime, Supname char(50), Ponum char(15), PartMfgr char(8), Costeach numeric(13,5),
							Ord_qty numeric(10,2), Podate SmallDateTime, Mfgr_pt_no char(30), Uniq_key char(10),Uniqlnno char(10));

	INSERT INTO @lastNPos
		SELECT TOP(@lnNumberOfPOsIncluded) VerDate ,Supname ,Pomain.Ponum ,PartMfgr,
		Costeach ,Ord_qty ,Podate ,Mfgr_pt_no,Uniq_key,Poitems.UniqLnNo
			FROM pomain,poitems,supinfo
			where Poitems.Ponum=Pomain.Ponum
			AND Pomain.UniqSupno=Supinfo.UniqSUpno
			AND Poitems.lCancel=0
			AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED') 
			AND Poitems.uniq_key=@lcUniq_key order by verdate DESC,pomain.ponum DESC;
			
	WITH mWhtAvg AS
	(
	-- 02/07/17 VL CSI reported an issue that cost roll didn't convert the PUR UOM to Stock UOM when calculating last N PO, here will use fn_convertprice() to update qty
	--SELECT CAST(SUM(Poitems.Ord_qty*Poitems.CostEach) AS numeric(13,5)) AS TotalCost, SUM(S_Ord_qty) AS TotalSQty
	-- 02/21/17 VL found the cost was converted to stock cost, so should multiple with stock order qty:S_ord_qty, but found in some old record the s_ord_qty didn't convert right, so use ord_qty and convert from pum to uom
	--SELECT CAST(SUM(Poitems.Ord_qty*CAST(dbo.fn_convertprice('Pur',Poitems.CostEach,Poitems.Pur_Uofm, Poitems.U_of_meas) as numeric(13,5)) ) AS numeric(13,5)) AS TotalCost, SUM(S_Ord_qty) AS TotalSQty
	SELECT CAST(SUM(dbo.fn_ConverQtyUOM(Poitems.Pur_Uofm, Poitems.U_of_meas,Poitems.Ord_qty)*CAST(dbo.fn_convertprice('Pur',Poitems.CostEach,Poitems.Pur_Uofm, Poitems.U_of_meas) as numeric(13,5)) ) AS numeric(13,5)) AS TotalCost, 
			SUM(dbo.fn_ConverQtyUOM(Poitems.Pur_Uofm, Poitems.U_of_meas,Poitems.Ord_qty)) AS TotalSQty
		FROM Poitems WHERE UniqLnNo IN (SELECT UniqLnno from @lastNPos)
	)
	SELECT @lnReturn=ISNULL(ROUND(TotalCost/TotalSQty,5),0.00) FROM mWhtAvg

	-- Return the result of the function
	RETURN ISNULL(@lnReturn,0.00000)

END




