-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/28/2011
-- Description:	Drill down Invt Transfer transactions
-- Modified :	
-- 10/8/2014 YS replace invtmfhd table with 2 new tables
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownInvtTrns]
	-- Add the parameters for the stored procedure here
	@Invtxfer_N char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
 -- 12/13/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0   
   --10/8/2014 YS replace invtmfhd table with 2 new tables
	SELECT distinct Invttrns.DATE as Trans_Dt, Inventor.PART_NO,Inventor.Revision,
		Inventor.PART_SOURC,Inventor.DESCRIPT, Invttrns.REASON ,
		InvtTrns.QtyXfer ,Invttrns.UNIQ_KEY,Invttrns.FROMWKEY,InvtTrns.Towkey,InvtTrns.STDCOST, 
		ROUND(Qtyxfer * Invttrns.StdCost,2) AS nTransAmount, 
		Invttrns.InvtXfer_N,m.Partmfgr,m.MFGR_PT_NO,l.UNIQMFGRHD ,
		FW.Warehouse as From_Warehouse, TW.Warehouse as To_Warehouse
		FROM InvtTrns INNER JOIN INVENTOR ON Invttrns.UNIQ_KEY =Inventor.UNIQ_KEY 
		INNER JOIN INVTMFGR AS FI on FI.W_KEY=invttrns.fromWKEY
		INNER JOIN INVTMFGR AS TI on TI.W_KEY=invttrns.TOWKEY
		--inner join invtmfhd on FI.uniqmfgrhd=invtmfhd.UNIQMFGRHD 
		inner join InvtMPNLink L  on FI.uniqmfgrhd=l.UNIQMFGRHD 
		inner join MfgrMaster M on l.mfgrMasterId=m.MfgrMasterId
		inner join WAREHOUS AS FW on FI.UNIQWH=FW.UNIQWH 
		inner join WAREHOUS AS TW on TI.UNIQWH=TW.UNIQWH 
	WHERE INVTTRNS.Invtxfer_N =@Invtxfer_N
ELSE
  --10/8/2014 YS replace invtmfhd table with 2 new tables
	SELECT distinct Invttrns.DATE as Trans_Dt, Inventor.PART_NO,Inventor.Revision,
		Inventor.PART_SOURC,Inventor.DESCRIPT, Invttrns.REASON ,
		InvtTrns.QtyXfer ,Invttrns.UNIQ_KEY,Invttrns.FROMWKEY,InvtTrns.Towkey,InvtTrns.STDCOST, 
		ROUND(Qtyxfer * Invttrns.StdCost,2) AS nTransAmount, FF.Symbol AS Functional_Currency,
		Invttrns.InvtXfer_N,m.Partmfgr,m.MFGR_PT_NO,l.UNIQMFGRHD ,
		FW.Warehouse as From_Warehouse, TW.Warehouse as To_Warehouse,
		InvtTrns.STDCOSTPR, ROUND(Qtyxfer * Invttrns.StdCostPR,2) AS nTransAmountPR, PF.Symbol AS Presentation_Currency
		FROM InvtTrns 
			INNER JOIN Fcused PF ON InvtTrns.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON InvtTrns.FuncFcused_uniq = FF.Fcused_uniq	
		INNER JOIN INVENTOR ON Invttrns.UNIQ_KEY =Inventor.UNIQ_KEY 
		INNER JOIN INVTMFGR AS FI on FI.W_KEY=invttrns.fromWKEY
		INNER JOIN INVTMFGR AS TI on TI.W_KEY=invttrns.TOWKEY
		--inner join invtmfhd on FI.uniqmfgrhd=invtmfhd.UNIQMFGRHD 
		inner join InvtMPNLink L  on FI.uniqmfgrhd=l.UNIQMFGRHD 
		inner join MfgrMaster M on l.mfgrMasterId=m.MfgrMasterId
		inner join WAREHOUS AS FW on FI.UNIQWH=FW.UNIQWH 
		inner join WAREHOUS AS TW on TI.UNIQWH=TW.UNIQWH 
	WHERE INVTTRNS.Invtxfer_N =@Invtxfer_N
end	