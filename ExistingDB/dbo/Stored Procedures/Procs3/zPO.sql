-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/08/2012
-- Description:	get information for MRP replaces ZPO cursor
-- Modified: 10/06/14 YS added uniqlnno and uniqdetno columns
--			10/10/14 YS removed invtmfhd and replaced with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[zPO]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--10/06/14 YS added uniqlnno and uniqdetno columns
	--10/10/14 YS removed invtmfhd and replaced with 2 new tables
	SELECT PoMain.PoNum, PoItems.Uniq_Key, Schd_date AS ReqDate, Schd_date AS Due_date, Balance, PoItems.Partmfgr,
		PoItems.Mfgr_Pt_No, Pomain.Uniqsupno, CostEach, Schd_Qty, IsFirm, Poitschd.Requesttp,WoPrjnumber, 
		ISNULL(PjctMain.PrjUnique,CAST(' ' as char(10))) as PrjUnique, 
		Poitems.Uniqmfgrhd, m.MatlType,
		ISNULL(INVENTOR.PART_SOURC,SPACE(10)) AS Part_sourc,
		ISNULL(Inventor.Make_buy,CAST(0 as bit)) as Make_buy,
		ISNULL(Inventor.Phant_make,CAST(0 as bit)) as Phant_make ,
		ISNULL(Inventor.Mrp_code,CAST(0 as INT)) as MRP_code,
		ISNULL(Inventor.SCRAP,CAST(0.00 as numeric(6,2))) as Scrap,
		Poitems.PUR_UOFM,Poitems.U_OF_MEAS ,poitems.UNIQLNNO,Poitschd.UNIQDETNO   
	FROM PoMain INNER JOIN PoItems ON Pomain.Ponum=Poitems.Ponum
		LEFT OUTER JOIN INVENTOR ON Poitems.UNIQ_KEY =Inventor.UNIQ_KEY 
		INNER JOIN PoItSchd ON Poitems.Uniqlnno=PoitSchd.Uniqlnno
		INNER JOIN Warehous ON Poitschd.UniqWh=Warehous.UniqWh
		LEFT OUTER JOIN PjctMain ON Poitschd.WoPrjnumber+Poitschd.Requesttp=PjctMain.PrjNumber+'Prj Alloc'
		INNER JOIN InvtMPNLink L ON Poitems.Uniqmfgrhd=L.Uniqmfgrhd
		INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
		WHERE PoStatus <> 'CANCEL' 
		AND PoStatus <> 'CLOSED' 
		AND PoItSchd.Balance > 0 
		AND PoItems.Uniq_Key<>' '
		AND PoItems.lCancel=0  	
END