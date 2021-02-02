-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/28/2011
-- Description:	Drill down Invt Rec transactions
-- Modified: 
-- 10/08/14 YS replace invtmfhd table with 2 new tables
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- 02/07/17 VL: Minor for nTransAmountPR
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownInvtRec]
	-- Add the parameters for the stored procedure here
	@InvtRec_No char(10)=' '
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
   --10/08/14 YS replace invtmfhd table with 2 new tables
	SELECT distinct Invt_rec.DAte as Trans_Dt, Inventor.PART_NO,Inventor.Revision,
		Inventor.PART_SOURC,Inventor.DESCRIPT, Invt_rec.Commrec,
		QtyRec ,Invt_rec.UNIQ_KEY,Invt_rec.W_KEY,Invt_rec.StdCost,
		ROUND(QtyRec * Invt_rec.StdCost,2) AS nTransAmount, 
		Invt_rec.InvtRec_No,m.Partmfgr,m.MFGR_PT_NO,l.UNIQMFGRHD ,
		Warehous.Warehouse  
		FROM Invt_Rec INNER JOIN INVENTOR ON Invt_rec.UNIQ_KEY =Inventor.UNIQ_KEY 
		INNER JOIN INVTMFGR on InvtMfgr.W_KEY=invt_rec.W_KEY
		--inner join invtmfhd on invtmfgr.uniqmfgrhd=invtmfhd.UNIQMFGRHD 
		inner join InvtMPNLink L on invtmfgr.uniqmfgrhd=l.UNIQMFGRHD 
		inner join MfgrMaster M on m.MfgrMasterId=l.mfgrMasterId
		inner join WAREHOUS on invtmfgr.UNIQWH=warehous.UNIQWH 
	WHERE INVTRec_NO =@InvtRec_No 
ELSE
    -- Insert statements for procedure here
   --10/08/14 YS replace invtmfhd table with 2 new tables
	SELECT distinct Invt_rec.DAte as Trans_Dt, Inventor.PART_NO,Inventor.Revision,
		Inventor.PART_SOURC,Inventor.DESCRIPT, Invt_rec.Commrec,
		QtyRec ,Invt_rec.UNIQ_KEY,Invt_rec.W_KEY,Invt_rec.StdCost,
		ROUND(QtyRec * Invt_rec.StdCost,2) AS nTransAmount, FF.Symbol AS Functional_Currency,
		Invt_rec.InvtRec_No,m.Partmfgr,m.MFGR_PT_NO,l.UNIQMFGRHD ,
		Warehous.Warehouse,
		Invt_rec.StdCostPR,ROUND(QtyRec * Invt_rec.StdCostPR,2) AS nTransAmountPR,PF.Symbol AS Presentation_Currency  
		FROM Invt_Rec
			INNER JOIN Fcused PF ON Invt_Rec.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Invt_Rec.FuncFcused_uniq = FF.Fcused_uniq	
		INNER JOIN INVENTOR ON Invt_rec.UNIQ_KEY =Inventor.UNIQ_KEY 
		INNER JOIN INVTMFGR on InvtMfgr.W_KEY=invt_rec.W_KEY
		--inner join invtmfhd on invtmfgr.uniqmfgrhd=invtmfhd.UNIQMFGRHD 
		inner join InvtMPNLink L on invtmfgr.uniqmfgrhd=l.UNIQMFGRHD 
		inner join MfgrMaster M on m.MfgrMasterId=l.mfgrMasterId
		inner join WAREHOUS on invtmfgr.UNIQWH=warehous.UNIQWH 
	WHERE INVTRec_NO =@InvtRec_No 
end	