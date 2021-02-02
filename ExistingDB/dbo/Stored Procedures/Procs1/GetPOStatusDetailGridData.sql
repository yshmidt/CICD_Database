-- =============================================
-- Author: Satish B
-- Create date: <09/06/2017>
-- Description:	<Get PO Status main grid data>
-- Modified : 09/12/2017 Satish B : Change condition from poitsc.BALANCE <> 0 TO (poit.RECV_QTY-poit.ACPT_QTY) > 0
-- Modified : 09/12/2017 Satish B : Select ITAR
-- Modified : 09/13/2017 Satish B : Change the selection of Balance,DueDate,DueQty
-- Modified : 09/13/2017 Satish B : Select the record which has minimun data from multiple records
-- Modified : 09/14/2017 Satish B : Select DockQty
-- Modified : 09/14/2017 Satish B : Added join of receiverDetail table to get DockQty
-- Modified : 09/14/2017 Satish B : Added group by clause
-- Modified : 09/19/2017 Satish B : Change selection of Balance from (poit.RECV_QTY-poit.ACPT_QTY) AS Balance  To (poit.ORD_QTY-poit.ACPT_QTY) AS Balance 
-- Modified : 09/19/2017 Satish B : Added filter of recDtl.isCompleted=0 to get DockQty
-- Modified : 09/19/2017 Satish B : Change condition from --AND (poitsc.REQ_DATE < GETDATE() and (poit.RECV_QTY-poit.ACPT_QTY) > 0) to AND (poitsc.SCHD_DATE < GETDATE() and (poit.ORD_QTY-poit.ACPT_QTY) > 0)
-- Modified : 09/19/2017 Satish B : Check null for DockQty
-- Modified : 09/19/2017 Satish B : Replace Inner join with Left Join
-- Modified : 10/04/2017 Satish B : Replace Inner join with Left Join
-- Modified : 10/04/2017 Satish B : Replace Inner join of Inventor with Left Join
-- Modified : 10/24/2017 Satish B : Replace Inner join of INVTMPNLINK and MFGRMASTER with Left Join
-- Modified : 10/24/2017 Satish B : Check IsNull for ITAR
-- Modified : 10/26/2017 Satish B : Select poit.PART_NO and poit.REVISION for MRO part if part is MRO
-- Modified : 10/26/2017 Satish B : Select poit.DESCRIPT for MRO part if part is MRO
-- Modified : 10/26/2017 Satish B : Select poit.PART_NO,poit.REVISION,poit.DESCRIPT in group by
-- exec GetPOStatusDetailGridData '000000000001805','','',1,100,0
-- =============================================
CREATE PROCEDURE [dbo].[GetPOStatusDetailGridData] 
	-- Add the parameters for the stored procedure here
@poNumber nvarchar(15) = null ,
@partNumber nvarchar(35) = null ,
@supplier nvarchar(35) = null ,
@startRecord int =1,
@endRecord int =10,
@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	SELECT COUNT(1) AS RowCnt -- Get total counts 
		INTO #tempReceivingDetails 
	FROM POITEMS poit 
	--10/04/2017 Satish B : Replace Inner join of Inventor with Left Join
	LEFT JOIN INVENTOR inv ON poit.UNIQ_KEY = inv.UNIQ_KEY
	--10/24/2017 Satish B : Replace Inner join of INVTMPNLINK and MFGRMASTER with Left Join
	LEFT JOIN INVTMPNLINK invlk ON poit.UNIQMFGRHD = invlk.uniqmfgrhd
	LEFT JOIN MFGRMASTER mfgMst ON invlk.MfgrMasterId = mfgMst.MfgrMasterId
	INNER JOIN POITSCHD poitsc ON poit.UNIQLNNO = poitsc.UNIQLNNO
	--09/14/2017 Satish B : Added join of receiverDetail table to get DockQty
	--10/04/2017 Satish B : Replace Inner join with Left Join
	LEFT JOIN receiverDetail recDtl ON recDtl.uniqlnno=poit.UNIQLNNO
	--09/13/2017 Satish B : Select the record which has minimun data from multiple records
	INNER JOIN (SELECT ps.UNIQLNNO,min(ps.SCHD_DATE) as SCHD_DATE from POITEMS p
					INNER JOIN POITSCHD ps on ps.UNIQLNNO=p.UNIQLNNO 
				    WHERE  ps.PONUM=@poNumber and ps.BALANCE > 0
			        GROUP BY ps.UNIQLNNO
				) poitschd ON poitschd.UNIQLNNO = poitsc.UNIQLNNO and poitschd.SCHD_DATE =poitsc.SCHD_DATE 
	WHERE poit.PONUM = @poNumber 
	--09/19/2017 Satish B : Change from REQ_DATE to SCHD_DATE
		--AND (poitsc.REQ_DATE < GETDATE() and (poit.RECV_QTY-poit.ACPT_QTY) > 0)
		AND (poitsc.SCHD_DATE < GETDATE() and (poit.RECV_QTY-poit.ACPT_QTY) > 0)

	SELECT poit.ITEMNO AS Item
	--10/26/2017 : Satish B : Select poit.PART_NO and poit.REVISION for MRO part if part is MRO
		,ISNULL(RTRIM(invt.PART_NO) + CASE WHEN invt.REVISION IS NULL OR invt.REVISION='' THEN '' ELSE '/' END + invt.REVISION,
				RTRIM(poit.PART_NO) + CASE WHEN poit.REVISION IS NULL OR poit.REVISION='' THEN '' ELSE '/' END + poit.REVISION) AS PartNumberRev
		,mfgMst.PartMfgr AS MFGR
		,mfgMst.mfgr_pt_no AS MFGRPartNumber
		--10/26/2017 : Satish B : Select poit.DESCRIPT for MRO part if part is MRO
		,ISNULL(RTRIM(invt.PART_CLASS) + CASE WHEN invt.PART_CLASS IS NULL OR invt.PART_CLASS='' THEN '' ELSE '/' END + 
				 RTRIM(invt.PART_TYPE) + CASE WHEN invt.PART_TYPE IS NULL OR invt.PART_TYPE='' THEN '' ELSE '/' END +
				 invt.DESCRIPT,poit.DESCRIPT) AS [Description]
		,poit.ORD_QTY AS ORDQty
		--09/13/2017 Satish B : Change the selection of Balance,DueDate,DueQty
		--,poit.RECV_QTY AS Balance
		--,poitsc.REQ_DATE AS DueDate
		--,poitsc.SCHD_QTY AS DueQty
		--,poitsc.REQ_DATE
		,poitsc.SCHD_DATE AS DueDate
		,poitsc.BALANCE AS DueQty
		--09/19/2017 Satish B : Change selection of Balance from (poit.RECV_QTY-poit.ACPT_QTY) AS Balance  To (poit.ORD_QTY-poit.ACPT_QTY) AS Balance 
		,(poit.ORD_QTY-poit.ACPT_QTY) AS Balance 
		--,(poit.RECV_QTY-poit.ACPT_QTY) AS Balance 
		--09/12/2017 Satish B : Select ITAR
		--10/24/2017 Satish B : Check IsNull for ITAR
		,ISNULL(invt.ITAR,0)
		--09/14/2017 Satish B : Select DockQty
		--09/19/2017 Satish B :Check null for DockQty
		,ISNULL(SUM(recDtl.Qty_rec),0) AS DockQty
		--,SUM(recDtl.Qty_rec) AS DockQty
	FROM POITEMS poit 
	--10/04/2017 Satish B : Replace Inner join of Inventor with Left Join
	LEFT JOIN INVENTOR invt ON poit.UNIQ_KEY = invt.UNIQ_KEY
	--10/24/2017 Satish B : Replace Inner join of INVTMPNLINK and MFGRMASTER with Left Join
	LEFT JOIN INVTMPNLINK invlk ON poit.UNIQMFGRHD = invlk.uniqmfgrhd
	LEFT JOIN MFGRMASTER mfgMst ON invlk.MfgrMasterId = mfgMst.MfgrMasterId
	INNER JOIN POITSCHD poitsc ON poit.UNIQLNNO = poitsc.UNIQLNNO 
	--09/14/2017 Satish B : Added join of receiverDetail table to get DockQty
	--09/19/2017 Satish B : Replace Inner join with Left Join
	LEFT JOIN receiverDetail recDtl ON recDtl.uniqlnno=poit.UNIQLNNO AND recDtl.isCompleted=0  --09/19/2017 Satish B : Added filter of recDtl.isCompleted=0 to get DockQty
	--09/13/2017 Satish B : Select the record which has minimun data from multiple records
	INNER JOIN (SELECT ps.UNIQLNNO,min(ps.SCHD_DATE) as SCHD_DATE from POITEMS p
					INNER JOIN POITSCHD ps on ps.UNIQLNNO=p.UNIQLNNO 
				    WHERE  ps.PONUM=@poNumber and ps.BALANCE > 0
			        GROUP BY ps.UNIQLNNO
				) poitschd ON poitschd.UNIQLNNO = poitsc.UNIQLNNO and poitschd.SCHD_DATE =poitsc.SCHD_DATE 
	WHERE poit.PONUM = @poNumber 
	--09/12/2017 Satish B : Change condition from poitsc.BALANCE <> 0 TO (poit.RECV_QTY-poit.ACPT_QTY) > 0
	--AND (poitsc.REQ_DATE < GETDATE() and poitsc.BALANCE <> 0)
	--09/19/2017 Satish B : Change condition from --AND (poitsc.REQ_DATE < GETDATE() and (poit.RECV_QTY-poit.ACPT_QTY) > 0) to AND (poitsc.SCHD_DATE < GETDATE() and (poit.ORD_QTY-poit.ACPT_QTY) > 0)
	AND (poitsc.SCHD_DATE < GETDATE() and (poit.ORD_QTY-poit.ACPT_QTY) > 0)
	--09/14/2017 Satish B : Added group by clause
	GROUP BY invt.PART_NO,invt.REVISION,mfgMst.PartMfgr,mfgMst.mfgr_pt_no,invt.PART_CLASS,invt.PART_TYPE,invt.DESCRIPT,poit.ORD_QTY,poitsc.SCHD_DATE,poitsc.BALANCE,poit.ITEMNO
	,poit.RECV_QTY,poit.ACPT_QTY,invt.ITAR
	--10/26/2017 Satish B : Select poit.PART_NO,poit.REVISION,poit.DESCRIPT in group by
	,poit.PART_NO,poit.REVISION,poit.DESCRIPT
	ORDER BY poit.ITEMNO
	OFFSET(@startRecord-1) ROWS
	FETCH NEXT @EndRecord ROWS ONLY;
	SET @outTotalNumberOfRecord = (SELECT COUNT(1) FROM #tempReceivingDetails) 
END

