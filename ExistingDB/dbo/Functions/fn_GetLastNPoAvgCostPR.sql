-- =============================================
-- Author:		Vicky Lu	
-- Create date: <05/03/17>
-- Description:	<Return N last PO average costPR, copied the code from fn_GetLastNPoAvgCost>
-- Modification:
-- 07/16/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE FUNCTION [dbo].[fn_GetLastNPoAvgCostPR]
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
	
	DECLARE @lastNPos TABLE (VerDate SmallDateTime, Supname char(50), Ponum char(15), PartMfgr char(8), CosteachPR numeric(13,5),
							Ord_qty numeric(10,2), Podate SmallDateTime, Mfgr_pt_no char(30), Uniq_key char(10),Uniqlnno char(10));

	INSERT INTO @lastNPos
		SELECT TOP(@lnNumberOfPOsIncluded) VerDate ,Supname ,Pomain.Ponum ,PartMfgr,
		CosteachPR ,Ord_qty ,Podate ,Mfgr_pt_no,Uniq_key,Poitems.UniqLnNo
			FROM pomain,poitems,supinfo
			where Poitems.Ponum=Pomain.Ponum
			AND Pomain.UniqSupno=Supinfo.UniqSUpno
			AND Poitems.lCancel=0
			AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED') 
			AND Poitems.uniq_key=@lcUniq_key order by verdate DESC,pomain.ponum DESC;
			
	WITH mWhtAvg AS
	(
	SELECT CAST(SUM(dbo.fn_ConverQtyUOM(Poitems.Pur_Uofm, Poitems.U_of_meas,Poitems.Ord_qty)*CAST(dbo.fn_convertprice('Pur',Poitems.CostEachPR,Poitems.Pur_Uofm, Poitems.U_of_meas) as numeric(13,5)) ) AS numeric(13,5)) AS TotalCostPR, 
			SUM(dbo.fn_ConverQtyUOM(Poitems.Pur_Uofm, Poitems.U_of_meas,Poitems.Ord_qty)) AS TotalSQty
		FROM Poitems WHERE UniqLnNo IN (SELECT UniqLnno from @lastNPos)
	)
	SELECT @lnReturn=ISNULL(ROUND(TotalCostPR/TotalSQty,5),0.00) FROM mWhtAvg

	-- Return the result of the function
	RETURN ISNULL(@lnReturn,0.00000)

END



