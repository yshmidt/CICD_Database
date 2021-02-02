-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: <10/25/10>
-- Description:	<Get Data to create a list of the items to be received for a specific PO>
-- -- 01/09/14 YS added new columns from inventor for Web barcode receiving 
-- 10/09/14 YS Happy Birthday Denis. Replace invtmfhd table with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[GetPo2Receiv4PO] 
	-- Add the parameters for the stored procedure here
	@lcPonum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- add lMFRemoved flag for the items that had their MPN removed
	-- 10/09/14 YS Happy Birthday Denis. Replace invtmfhd table with 2 new tables
	SELECT Supinfo.SupName, Poitems.Ponum,GetDate() AS dDockDate, Poitems.Uniqlnno,Poitems.Itemno,POITEMS.UNIQ_KEY, 
	ISNULL(Inventor.Part_class,Poitems.Part_class) AS Part_class, 
	ISNULL(Inventor.Part_type,Poitems.Part_type) AS Part_type, 
	ISNULL(Inventor.Part_no,Poitems.Part_no) AS Part_no, 
	ISNULL(Inventor.Revision,Poitems.Revision) AS Revision, 
	ISNULL(Inventor.Descript,Poitems.Descript) AS Descript, 
	Poitems.U_of_meas,Poitems.Pur_uofm,
	(Poitems.Ord_qty-Poitems.Acpt_qty) AS Balance, Poitems.Ord_qty, Poitems.Overage, 
	ISNULL(Inventor.insp_req,CAST(0 as bit)) AS insp_req,
	ISNULL((CASE WHEN Inventor.insp_req=1 THEN 'Yes' ELSE 'No ' END),'No ') AS insp_yes,
	ISNULL((CASE WHEN Inventor.cert_req=1 AND ((Inventor.cert_type='Both')  OR (Inventor.cert_type='Receive')) THEN 'Yes' ELSE 'No ' END),'No ') AS cert_yes,
	Poitems.partmfgr,Poitems.mfgr_pt_no,POITEMS.UNIQMFGRHD,
	-- 01/09/14 YS added new columns from inventor for Web barcode receiving 
	ISNULL(Inventor.ORDMULT,CAST(0 as numeric(7,0))) as ORDMULT,
	ISNULL(Inventor.MINORD ,CAST(0 as numeric(7,0))) as MINORD,
	ISNULL(l.is_deleted,CAST(0 as bit)) AS lMfRemoved
	FROM Pomain, Supinfo,Poitems LEFT OUTER JOIN Inventor 
	ON Poitems.Uniq_key = Inventor.Uniq_key
	--LEFT OUTER JOIN INVTMFHD on POITEMS.UNIQMFGRHD = INVTMFHD.UNIQMFGRHD 
	LEFT OUTER JOIN InvtMPNLink L on poitems.UNIQMFGRHD = L.uniqmfgrhd
	LEFT OUTER JOIN MfgrMaster M ON l.mfgrMasterId=m.MfgrMasterId
	WHERE Pomain.UniqSUpNo = Supinfo.UniqSupno 
		AND Poitems.Ponum = Pomain.Ponum 
		AND (Poitems.Ord_qty-Poitems.Acpt_qty) > 0 
		AND Poitems.Ponum = @lcPonum 
		AND Poitems.lCancel=0
		ORDER BY Poitems.Itemno 
		
		
END