-- =============================================
-- Author:		Sachin B
-- Create date: 11/15/2016
-- Description:	this procedure will be called from the Part module and will get all the warehouse details from which we issued any quantity to workOrder
-- 11/21/2016 Sachin b update the Query get all information with invt_isu table as per discussion with yelena
-- 06/22/2017 Sachin b update the Query reserved Column information and remove outer apply
-- 07/31/2017 Sachin b Remove Unused parameter @IsReserve and add @kaseqnum number
-- 08/08/2017 Rajendra K Added FromWarehouse & ToWareHouse used for KitTransfer
-- 09/01/2017 Sachin b Add Warehouse and Location column
-- 10/10/2017 Sachin B Add Parameter ToWkey,UniqMfgrHd
-- 11/03/2017 Sachin B Apply Code review
-- [dbo].[GetIssuedPartMfgrDetailsByUniqKeyAndWoNo] '_01F15T04X','0000000544','E3CW4U7F2I'
-- =============================================

CREATE PROCEDURE [dbo].[GetIssuedPartMfgrDetailsByUniqKeyAndWoNo] 
	-- Add the parameters for the stored procedure here
	@gUniq_key CHAR(10)=' ',
	@wono CHAR(10),
	@kaseqnum CHAR(10)
	 
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
     -- 09/01/2017 Sachin b Add Warehouse and Location column  
	 SELECT mfMaster.Partmfgr,mfMaster.mfgr_pt_no AS MfgrPartNo, Warehouse, Location, 
			RTRIM(Warehouse)+' / '+RTRIM(mf.Location) AS FromWarehouse,RTRIM(Warehouse)+' / '+RTRIM(mf.Location) AS ToWarehouse
	        -- 08/08/2017 Rajendra K Added FromWarehouse & ToWareHouse used for KitTransfer
			,w.Whno, mf.W_key, Wh_gl_nbr,isu.UniqMfgrHd,mfMaster.qtyPerPkg, QTY_OH - Reserved AS 'QtyOh', Reserved, UniqSupno, mf.UniqWh,
		    SUM(QTYISU) AS 'QtyUsed',0 AS 'ReverseQty',cast(0 AS BIT) AS IsReserve,i.U_OF_MEAS AS Unit
			-- 10/10/2017 Sachin B Add Parameter ToWkey,UniqMfgrHd
			,mf.w_key AS ToWkey,i.UNIQ_KEY
		--ISNULL(Reserved.ReserveQty,0.0) AS 'ReserveQty'
		FROM invt_isu isu
		INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY 
		INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY AND isu.UNIQMFGRHD = mpn.uniqmfgrhd
		INNER JOIN MfgrMaster mfMaster ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
		INNER JOIN INVTMFGR mf ON isu.uniq_key = mf.uniq_key AND isu.UNIQMFGRHD = mf.UNIQMFGRHD AND mf.W_KEY =isu.W_KEY
		INNER JOIN WAREHOUS w ON mf.UNIQWH = w.UNIQWH
		-- 06/22/2017 Sachin b update the Query ReserveQty Column information and remove outer apply
		--OUTER APPLY (select SUM(QTYALLOC)  AS ReserveQty from INVT_RES where INVT_RES.UNIQ_KEY=i.UNIQ_KEY and INVT_RES.WONO = isu.WONO  
		--Group by INVT_RES.W_KEY ,INVT_RES.LOTCODE,INVT_RES.EXPDATE,INVT_RES.REFERENCE,INVT_RES.PONUM
		--Having  SUM(QTYALLOC)>0
		--) Reserved
		-- 07/31/2017 Sachin b Remove Unused parameter @IsReserve and add @kaseqnum number
		WHERE isu.ISSUEDTO like '%(WO:'+@wono+'%' AND isu.wono =@wono AND isu.uniq_key = @gUniq_key AND isu.kaseqnum =@kaseqnum
		GROUP BY mfMaster.Partmfgr,mfMaster.mfgr_pt_no,Warehouse,Location,w.Whno, mf.W_key, Wh_gl_nbr, isu.UniqMfgrHd,mfMaster.qtyPerPkg,QTY_OH
		, Reserved, UniqSupno, mf.UniqWh,i.U_OF_MEAS,i.UNIQ_KEY
		HAVING SUM(QTYISU) >0
 
END