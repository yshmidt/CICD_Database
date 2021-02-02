-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <10/25/10>
-- Description:	<PODOCKView for the PoDock module>
-- =============================================
CREATE PROCEDURE [dbo].[PoDockView] 
	-- Add the parameters for the stored procedure here
	@lcReceiverno char(10)=' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Supinfo.supname, Podock.ponum, Podock.porecpkno,
			Podock.receiverno, Podock.dDockDate ,Podock.uniqlnno,
			Podock.recvby, Podock.qty_rec, Podock.compdate, Podock.compby,
			Podock.dock_uniq, Poitems.itemno,POITEMS.UNIQ_KEY ,
			Poitems.ord_qty-Poitems.acpt_qty AS balance, Poitems.ord_qty,
			ISNULL(Inventor.part_no,Poitems.part_no) AS part_no,
			ISNULL(Inventor.revision,Poitems.revision) AS revision,
			ISNULL(Inventor.descript,Poitems.descript) AS  descript,
			ISNULL(Inventor.Part_class,Poitems.part_class) AS part_class,
			ISNULL( Inventor.part_type,Poitems.part_type) AS part_type,
			Poitems.u_of_meas,Poitems.pur_uofm, Poitems.overage,
			ISNULL(Inventor.insp_req,CAST(0 as bit)) AS insp_req,
			ISNULL((CASE WHEN Inventor.insp_req=1 THEN 'Yes' ELSE 'No ' END),'No ') AS insp_yes,
			ISNULL((CASE WHEN Inventor.cert_req=1 AND ((Inventor.cert_type='Both')  OR (Inventor.cert_type='Receive')) THEN 'Yes' ELSE 'No ' END),'No ') AS cert_yes,
			Poitems.partmfgr,Poitems.mfgr_pt_no
		FROM podock,pomain,supinfo,poitems 
			LEFT OUTER JOIN inventor ON  Poitems.uniq_key = Inventor.uniq_key
		WHERE Pomain.uniqsupno = Supinfo.uniqsupno
		AND  Poitems.ponum = Pomain.ponum 
		AND  Poitems.lcancel =0
		AND  Podock.uniqlnno = Poitems.uniqlnno 
		AND  Podock.ponum = Poitems.ponum 
		AND  Podock.receiverno = @lcReceiverno 
		ORDER BY Poitems.itemno
END