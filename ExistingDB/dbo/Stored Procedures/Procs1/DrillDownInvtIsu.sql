-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/28/2011
-- Description:	Drill down Invt Issue transactions
-- Modified : 10/15/13 YS change issuedto column to show that the transaction was reversed when negative quantities 
--			  10/08/14 YS replace invtmfhd table with 2 new tables	
--			  12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
--			  02/07/17 VL: minor fix for functional currency
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownInvtIsu]
	-- Add the parameters for the stored procedure here
	@InvtIsu_No char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 12/13/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
    -- Insert statements for procedure here
   --10/15/13 YS change to show that the transaction was reversed when negative quantities 
   --10/08/14 YS replace invtmfhd table with 2 new tables	
	SELECT distinct Invt_isu.DAte as Trans_Dt, Inventor.PART_NO,Inventor.Revision,
		Inventor.PART_SOURC,Inventor.DESCRIPT, 
		cast(case when Invt_isu.QtyIsu<0 then 'reverse ' +ISSUEDTO else ISSUEDTO end as varchar(30)) as ISSUEDTO,
		Invt_isu.WONO,
		QtyIsu ,Invt_isu.UNIQ_KEY,Invt_isu.W_KEY,Invt_isu.StdCost,
		ROUND(QtyIsu * Invt_isu.StdCost,2) AS nTransAmount, 
		Invt_isu.InvtIsu_No,
		--Invtmfhd.UNIQMFGRHD ,INVTMFHD.Partmfgr,INVTMFHD.MFGR_PT_NO,Invtmfhd.UNIQMFGRHD ,
		M.Partmfgr,M.MFGR_PT_NO,L.UNIQMFGRHD,
		Warehous.Warehouse  
		FROM Invt_Isu INNER JOIN INVENTOR ON Invt_isu.UNIQ_KEY =Inventor.UNIQ_KEY 
		INNER JOIN INVTMFGR on InvtMfgr.W_KEY=invt_isu.W_KEY
		--inner join invtmfhd on invtmfgr.uniqmfgrhd=invtmfhd.UNIQMFGRHD 
		INNER JOIN InvtMPNLink L on invtmfgr.UNIQMFGRHD=l.uniqmfgrhd
		inner join MfgrMaster M on l.mfgrMasterId=m.MfgrMasterId
		inner join WAREHOUS on invtmfgr.UNIQWH=warehous.UNIQWH 
	WHERE INVTISU_NO =@InvtIsu_No 
ELSE
  --10/15/13 YS change to show that the transaction was reversed when negative quantities 
   --10/08/14 YS replace invtmfhd table with 2 new tables	
   -- 12/13/16 VL: added functional and presentation currency fields
	SELECT distinct Invt_isu.DAte as Trans_Dt, Inventor.PART_NO,Inventor.Revision,
		Inventor.PART_SOURC,Inventor.DESCRIPT, 
		cast(case when Invt_isu.QtyIsu<0 then 'reverse ' +ISSUEDTO else ISSUEDTO end as varchar(30)) as ISSUEDTO,
		Invt_isu.WONO,
		QtyIsu ,Invt_isu.UNIQ_KEY,Invt_isu.W_KEY,Invt_isu.StdCost,
		ROUND(QtyIsu * Invt_isu.StdCost,2) AS nTransAmount, FF.Symbol AS Functional_Currency,
		Invt_isu.InvtIsu_No,
		--Invtmfhd.UNIQMFGRHD ,INVTMFHD.Partmfgr,INVTMFHD.MFGR_PT_NO,Invtmfhd.UNIQMFGRHD ,
		M.Partmfgr,M.MFGR_PT_NO,L.UNIQMFGRHD,
		Warehous.Warehouse,
		Invt_isu.STDCOSTPR,ROUND(QtyIsu * Invt_isu.STDCOSTPR,2) AS nTransAmountPR, PF.Symbol AS Presentation_Currency   
		FROM Invt_Isu 
			INNER JOIN Fcused PF ON Invt_Isu.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Invt_Isu.FuncFcused_uniq = FF.Fcused_uniq		
		INNER JOIN INVENTOR ON Invt_isu.UNIQ_KEY =Inventor.UNIQ_KEY 
		INNER JOIN INVTMFGR on InvtMfgr.W_KEY=invt_isu.W_KEY
		--inner join invtmfhd on invtmfgr.uniqmfgrhd=invtmfhd.UNIQMFGRHD 
		INNER JOIN InvtMPNLink L on invtmfgr.UNIQMFGRHD=l.uniqmfgrhd
		inner join MfgrMaster M on l.mfgrMasterId=m.MfgrMasterId
		inner join WAREHOUS on invtmfgr.UNIQWH=warehous.UNIQWH 
	WHERE INVTISU_NO =@InvtIsu_No 
		
end	