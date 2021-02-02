
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <03/01/2010>
-- Description:	<Calculation of the avg cost of the last N Purchase Orders (N- is the variable number = @lnNumberOfPOsIncluded)  >
-- Modified: 05/20/14 YS added itemno
--- 05/21/14 YS check for divided by 0
-- 04/21/17 VL changed to work for functional currency to get PR value
--- 07/11/18 YS supname increased from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[GetLastNPoAvgCostPR] 
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10) = '', 
	@lnNumberOfPOsIncluded int = 5,
	@lnReturn numeric(13,5)=0.00000 OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
    -- Insert statements for procedure here
	--- 07/11/18 YS supname increased from 30 to 50
	declare @lastNPos TABLE (VerDate SmallDateTime,Supname char(50),Ponum char(15),ItemNo char(3),
	PartMfgr char(8),CosteachPR numeric(13,5),Ord_qty numeric(10,2),Podate SmallDateTime,Mfgr_pt_no char(30),
	Uniq_key char(10),Uniqlnno char(10));

	INSERT INTO @lastNPos EXEC GetLastNPo @lcUniq_key,@lnNumberOfPOsIncluded;
	WITH mWhtAvg AS
	(
	SELECT CAST(SUM(Poitems.Ord_qty*Poitems.CostEachPR) as numeric(13,5)) as TotalCostPR,SUM(S_Ord_qty) as TotalSQty
		FROM Poitems WHERE UniqLnNo IN (SELECT UniqLnno from @lastNPos)
	)
	--- 05/21/14 YS check for /by 0
	SELECT @lnReturn=
	CASE WHEN TotalSQty IS NULL OR TotalSQty=0.00 THEN 0.00
	ELSE ISNULL(ROUND(TotalCostPR/TotalSQty,5),0.00) END FROM mWhtAvg

--	WITH mWhtAvg AS
--	(
--	SELECT CAST(SUM(Poitems.Ord_qty*Poitems.CostEach) as numeric(13,5)) as TotalCost,SUM(S_Ord_qty) as TotalSQty
--		FROM Poitems WHERE UniqLnNo IN (SELECT UniqLnno from dbo.GetLastNPo(@lcUniq_key,@lnNumberOfPOsIncluded))
--	)
--	SELECT @lnReturn=ROUND(TotalCost/TotalSQty,5) FROM mWhtAvg


END