-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified :  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 09/23/16 DRP:  needed to change the Part_no char(25) to be Part_No Char(45) in order to display the full description for Misc items add to the order.  
-- I also needed to change the  <<ISNULL(Inventor.PART_NO, LEFT(Sodetail.Sodet_Desc,45)) AS Part_no>>   to be   <<, case when sodetail.uniq_key = '' then sodetail.sodet_desc else inventor.part_no end as Part_no  >> otherwise it was cutting the description short.	
-- 05/01/17 DRP: we used be able to reserve for SO line in SO module, so qtyfrominv saved what's been reserved for the SO item.   But we removed the ability in  SQL version, so now user can not reserve in SO module anymore.  So we don't use this field now
-- But I am going to leave it on the procedure results for now since we still have customers converting from VFP to SQL and will question if the numbers are different.  We can consider removing from this procedure later. 
--07/19/17 DRP:  needed to add the /*CUSTOMER LIST*/ in order to make sure only records the users are approved to see are displayed.
-- 08/27/20 VL added Custpartno, Custrev, part_class, part_type, Descript, CAPA#2981
-- =============================================
CREATE PROCEDURE [dbo].[QkViewSOShipSchdView] 

/*05/15/2014 DRP:  changed the date parameter names to work with WebManex*/
--@ldStartDate smalldatetime=NULL
--,@ldEndDate smalldatetime=NULL
@lcDateStart as smalldatetime= null
,@lcDateEnd as smalldatetime = null
,@llWithFGI bit = 1
,@userId uniqueidentifier=null 

AS
BEGIN

/*CUSTOMER LIST*/		--07/19/17 DRP:  added	
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer

SET NOCOUNT ON;

-- 08/27/20 VL added Custpartno, Custrev, part_class, part_type, Descript, CAPA#2981
DECLARE @ZSoShipSchd TABLE (Ship_dts smalldatetime, Sono char(10), CustName char(35), Part_no char(45), Revision char(8), 
	Partmfgr char(8), Mfgr_pt_no char(30), Qty numeric(9,2), QtyFromInv numeric(12,2), FGIQty numeric(12,2), Uniq_key char(10), W_key char(10),
	Custpartno char(45), Custrev char(8), Part_class char(8), Part_type char(8), Descript char(45))

-- 08/27/20 VL added Custpartno, Custrev, part_class, part_type, Descript, CAPA#2981
INSERT @ZSoShipSchd (Ship_dts, Sono, CustName, Part_no, Revision, Partmfgr, Mfgr_pt_no, Qty, QtyFromInv, Uniq_key, W_key,Custpartno, Custrev, part_class, part_type, Descript)
	SELECT Ship_dts, Sodetail.Sono, CustName
	,case when sodetail.uniq_key = '' then sodetail.sodet_desc else inventor.part_no end as Part_no	--09/23/16 DRP: replaced ISNULL(Inventor.PART_NO, LEFT(Sodetail.Sodet_Desc,45)) AS Part_no
	,ISNULL(Inventor.REVISION, SPACE(8)) AS Revision, SPACE(8) AS Partmfgr, SPACE(30) AS Mfgr_ptA_no, Qty, QtyFromInv, 
	Sodetail.Uniq_key, Sodetail.w_key
	-- 08/27/20 VL added Custpartno, Custrev, part_class, part_type, Descript, CAPA#2981
	,IC.Custpartno, IC.Custrev, Inventor.part_class, Inventor.part_type, Inventor.Descript

	-- 08/27/20 VL re-write the criteria
	--FROM Due_dts, Somain, Customer, Sodetail LEFT OUTER JOIN Inventor 
	--	ON Sodetail.Uniq_key = Inventor.Uniq_key 
	--WHERE Due_dts.Sono = Sodetail.Sono 
	--AND Due_dts.Uniqueln = Sodetail.Uniqueln 
	--AND (Sodetail.Status = 'Standard'
	--OR Sodetail.Status = 'Priority-1'
	--OR Sodetail.Status = 'Priority-2') 
	--AND Due_dts.Qty > 0 
	--AND 1 = CASE WHEN (@lcDateStart IS NULL) THEN CASE WHEN (Due_dts.Ship_dts <= DATEADD(day, 5, GETDATE())) THEN 1 ELSE 0 END
	--	ELSE CASE WHEN (Due_dts.Ship_dts >= @lcDateStart AND Due_dts.Ship_dts <= @lcDateEnd) THEN 1 ELSE 0 END END
	--AND Somain.Sono = Sodetail.Sono 
	--AND Somain.Custno = Customer.Custno 
	--and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--07/19/17 DRP:  added
	--ORDER BY 1,2
	
	FROM Somain INNER JOIN Sodetail ON Somain.Sono = Sodetail.Sono
	INNER JOIN Customer ON Somain.Custno = Customer.Custno 
	INNER JOIN DUE_DTS ON Sodetail.Uniqueln = DUE_DTS.Uniqueln
	LEFT OUTER JOIN Inventor ON Sodetail.Uniq_key = Inventor.Uniq_key
	LEFT OUTER JOIN Inventor IC ON Inventor.Uniq_key = IC.INT_UNIQ AND IC.Custno = Somain.Custno
	WHERE (Sodetail.Status = 'Standard'
	OR Sodetail.Status = 'Priority-1'
	OR Sodetail.Status = 'Priority-2') 
	AND Due_dts.Qty > 0 
	AND 1 = CASE WHEN (@lcDateStart IS NULL) THEN CASE WHEN (Due_dts.Ship_dts <= DATEADD(day, 5, GETDATE())) THEN 1 ELSE 0 END
		ELSE CASE WHEN (Due_dts.Ship_dts >= @lcDateStart AND Due_dts.Ship_dts <= @lcDateEnd) THEN 1 ELSE 0 END END
	AND exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--07/19/17 DRP:  added
	ORDER BY 1,2
;
-- First update FGIQty for those don't have sodetail.w_key, will sum all qty_oh for that uniq_key
WITH ZQty_ohNoW_key AS
(
	SELECT SUM(Qty_oh - Reserved) AS FGIQty, Uniq_key 
		FROM Invtmfgr, Warehous 
		WHERE Invtmfgr.UNIQWH = Warehous.UniqWh
		AND Warehous.Warehouse <> 'WIP   '
		AND Warehous.Warehouse <> 'WO-WIP'
		AND Warehous.Warehouse <> 'MRB   '
		AND Uniq_key IN (SELECT Uniq_key FROM @ZSoShipSchd WHERE W_key = '') 
		AND Invtmfgr.Is_Deleted = 0
		GROUP BY Invtmfgr.Uniq_key 
)
UPDATE @ZSoShipSchd 
	SET FGIQty = ZQty_ohNoW_key.FGIQty+QtyFromInv
	FROM @ZSoShipSchd ZSoShipSchd, ZQty_ohNoW_key
	WHERE ZSoShipSchd.Uniq_key = ZQty_ohNoW_key.Uniq_key
	AND W_key = ''

-- Now update FGIQty for those do have sodetail.w_key entered, will only get qty_oh for that w_key	
 -- 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
;
WITH ZQty_ohwithW_key AS
(
SELECT SUM(Qty_oh - Reserved) AS FGIQty, Invtmfgr.w_key, M.Partmfgr, M.Mfgr_pt_no
     --10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	FROM Invtmfgr, Warehous, InvtMPNLink L, MfgrMaster M
    WHERE Invtmfgr.UNIQWH = Warehous.UniqWh
    AND L.UniqMfgrHd = Invtmfgr.UniqMfgrHd
	AND l.mfgrMasterId=M.MfgrMasterId
	AND Warehous.Warehouse <> 'WIP   '
	AND Warehous.Warehouse <> 'WO-WIP'
	AND Warehous.Warehouse <> 'MRB   '
    AND Invtmfgr.Is_Deleted = 0 
   	AND L.Is_Deleted = 0 and m.IS_DELETED=0
   	AND Invtmfgr.W_key IN (SELECT W_key FROM @ZSoShipSchd WHERE W_key <> '') 
   	GROUP BY Invtmfgr.w_key, m.Partmfgr, m.Mfgr_pt_no
)

UPDATE @ZSoShipSchd 
	SET FGIQty = ZQty_ohwithW_key.FGIQty+QtyFromInv,
		Partmfgr = ZQty_ohwithW_key.PARTMFGR,
		Mfgr_pt_no = ZQty_ohwithW_key.MFGR_PT_NO
	FROM @ZSoShipSchd ZSoShipSchd, ZQty_ohwithW_key
	WHERE ZSoShipSchd.W_key = ZQty_ohwithW_key.W_key
	AND ZSoShipSchd.W_key <> ''

IF @llWithFGI = 1
	SELECT * FROM @ZSoShipSchd WHERE FGIQty > 0
ELSE
	SELECT * FROM @ZSoShipSchd


END