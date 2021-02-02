-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/16/2012
-- Description:	Sales information for MRP. (used in mGetComponentDemands method)
-- 09/23/14 YS use new tables instead of invtmfhd
-- 12/2/19 YS removed ' ' between Partmfgr + RTRIM(Mfgr_Pt_No)
-- 06/03/20 YS place back the ' ' between partmfgr and mfgr_pt_no and add rtrim(partmfgr). Modified MRP desktop run
--11/12/20 ys MAKE SURE THAT PARTMFGR INCLUDES all 8 charcters, The code in the class is matcing by 8 characters in the Partmfgr + ' ' + mpn
-- =============================================
CREATE PROCEDURE [dbo].[MrpSalesView] 
	-- Add the parameters for the stored procedure here
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT SoDetail.SoNo, SoDetail.Uniqueln, SoMain.GlDivNo, SoDetail.Uniq_Key, 
		Ship_Dts AS ReqDate, Qty AS ReqQty, 
		CAST(CASE WHEN Somain.is_rma=1 THEN 'RMA' ELSE 'SO' END + SoDetail.SoNo as CHAR(24)) AS Ref, 
		'Release PO' AS Action, 
		CAST('GENR' as CHAR(8)) AS Mfgrs, Inventor.Part_Sourc, 
		-- 12/2/19 YS removed ' ' between Partmfgr + RTRIM(Mfgr_Pt_No)
		--CAST(CASE WHEN somain.IS_RMA = 1 THEN 'RMA' ELSE 'SO' END + m.Partmfgr+ ' ' + RTRIM(m.Mfgr_Pt_No) as CHAR(45)) AS PtMf_MfptNo,
		--CAST(CASE WHEN somain.IS_RMA = 1 THEN 'RMA' ELSE 'SO' END + rtrim(m.Partmfgr)+' '+ RTRIM(m.Mfgr_Pt_No) as CHAR(45)) AS PtMf_MfptNo,
		--11/12/20 ys MAKE SURE THAT PARTMFGR INCLUDES all 8 charcters, The code in the class is matcing by 8 characters in the Partmfgr + ' ' + mpn
		CAST(CASE WHEN somain.IS_RMA = 1 THEN 'RMA' ELSE 'SO' END + dbo.PADR(Partmfgr,8,' ')+' ' + RTRIM(Mfgr_Pt_No) as CHAR(45)) AS PtMf_MfptNo,
		DueDt_Uniq, UseSetScrp, SoDetail.Lfcstitem, Prjunique 
	FROM SoMain INNER JOIN SoDetail ON SoMain.SoNo = SoDetail.SoNo
	INNER JOIN Due_dts ON  SoDetail.Uniqueln = Due_dts.Uniqueln 
	INNER JOIN INVENTOR ON Inventor.Uniq_Key = SoDetail.Uniq_Key 
	INNER JOIN Invtmfgr ON Invtmfgr.W_Key = SoDetail.W_Key
	--INNER JOIN InvtmfHd ON InvtMfHd.UniqMfgrHd = Invtmfgr.UniqMfgrHd
	INNER JOIN InvtMpnLink L ON L.uniqmfgrhd=invtmfgr.UNIQMFGRHD
	INNER JOIN MfgrMaster M on L.mfgrMasterId=M.mfgrmasterid
	WHERE  SoMain.Ord_Type = 'Open' 
	AND (SoDetail.STATUS = 'Standard' OR CHARINDEX('Priority',SoDetail.STATUS)=1
	OR (SoDetail.STATUS IN ('Admin Hold','Mfgr Hold'))) 
	AND SoDetail.MrponHold =0
	AND SoDetail.Uniq_Key<>' '
	AND (Part_Sourc = 'BUY' OR (Part_Sourc = 'MAKE' AND Make_Buy=1))
	AND ((SoMain.SoApproval=1 AND is_rma=0) OR  Is_rma=1) 
	
	
END