-- =============================================
-- Author: Satish B
-- Create date: <07/31/2017>
-- Description:	<Get Receiving Status main grid data>
-- Modified : 09/12/2017 Satish B : Select ITAR column
--          : 09/13/2017 Satish B : Added parameters @workOrder,@project
--          : 09/13/2017 Satish B : Added condition for @workOrder and @project
--			: 07/06/2018 Satish B : Added parameter @partRev
--			: 07/06/2018 Satish B : Added filter for part revision
-- Exec GetReceivingStatusGridData '','000-0003128','j','','','11',1,50,0
-- 07/12/2018 YS supname column increased from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[GetReceivingStatusGridData] 
	-- Add the parameters for the stored procedure here
	@poNumber nvarchar(15) = '' ,
	@partNumber nvarchar(35) = '',
	--07/06/2018 Satish B : Added parameter @partRev
	@partRev nvarchar(35) = '',
	-- 07/12/2018 YS supname column increased from 30 to 50
	@supplier nvarchar(50) = '' ,
	-- 09/13/2017 Satish B : Added parameters @workOrder,@project
	@workOrder nvarchar(10) = '' ,
	@project nvarchar(10) = '' ,
	@startRecord int =1,
    @endRecord int =100,
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	-- 09/13/2017 Satish B : Added condition for @workOrder and @project
	IF(@workOrder<>'' OR @project<>'')
	BEGIN
	    SELECT COUNT(1) AS RowCnt -- Get total counts 
			INTO #tempRevDetails 
			FROM INVENTOR inventor
			INNER JOIN receiverDetail receiverDetl ON receiverDetl.Uniq_key = inventor.Uniq_key	
			INNER JOIN receiverHeader receiverHdr ON receiverHdr.receiverHdrId = receiverDetl.receiverHdrId
			INNER JOIN POMAIN pomain ON receiverHdr.PONUM = pomain.PONUM
			INNER JOIN SUPINFO supinfo ON pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS p on (@workOrder =''  OR @project='') OR (p.PONUM= pomain.PONUM AND p.UNIQ_KEY = inventor.UNIQ_KEY)
		    INNER JOIN POITSCHD ps on (@workOrder =''  OR @project='') OR (ps.UNIQLNNO=p.UNIQLNNO)
		WHERE receiverDetl.isCompleted=0
			 AND (((@poNumber IS NULL OR @poNumber='') OR (receiverHdr.ponum LIKE '%'+ RTRIM(@poNumber) +'%'))
			 AND ((@partNumber IS NULL OR @partNumber='') OR (inventor.PART_NO LIKE '%'+ RTRIM(@partNumber) +'%'))
			 --07/06/2018 Satish B : Added filter for part revision
			 AND ((@partRev IS NULL OR @partRev='') OR (inventor.Revision LIKE '%'+ RTRIM(@partRev) +'%'))
			 AND ((@supplier IS NULL OR @supplier='') OR (supinfo.SUPNAME LIKE '%'+ RTRIM(@supplier) +'%'))
			 AND ((@workOrder IS NULL OR @workOrder ='') OR (ps.REQUESTTP='WO Alloc' and ps.WOPRJNUMBER LIKE '%'+ RTRIM(@workOrder) +'%'))
			 AND ((@project IS NULL OR @project = '') OR(ps.REQUESTTP='Prj Alloc ' and ps.WOPRJNUMBER LIKE '%'+ RTRIM(@project) +'%')))
		SELECT RTRIM(inventor.PART_NO) + CASE WHEN inventor.REVISION IS NULL OR inventor.REVISION='' THEN '' ELSE '/' END + inventor.REVISION AS PartNumber
			,RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_CLASS IS NULL OR inventor.PART_CLASS='' THEN '' ELSE '/' END + 
					 RTRIM(inventor.PART_TYPE) + CASE WHEN inventor.PART_TYPE IS NULL OR inventor.PART_TYPE='' THEN '' ELSE '/' END +
					 inventor.DESCRIPT AS Descript
			,inventor.UNIQ_KEY AS UniqKey
			,receiverDetl.Partmfgr
			,receiverDetl.mfgr_pt_no AS MfgrPartNo
			,SUM(receiverDetl.Qty_rec) AS Quantity
			,supinfo.SUPNAME AS Supplier
			,CAST(dbo.fremoveLeadingZeros(receiverHdr.ponum) AS VARCHAR(MAX)) AS PoNumber
			,receiverDetl.uniqlnno
			,inventor.ITAR
			,inventor.UNIQ_KEY
		FROM INVENTOR inventor
			INNER JOIN receiverDetail receiverDetl ON receiverDetl.Uniq_key = inventor.Uniq_key	
			INNER JOIN receiverHeader receiverHdr ON receiverHdr.receiverHdrId = receiverDetl.receiverHdrId
			INNER JOIN POMAIN pomain ON receiverHdr.PONUM = pomain.PONUM
			INNER JOIN SUPINFO supinfo ON pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS p on p.PONUM= pomain.PONUM AND p.UNIQ_KEY = inventor.UNIQ_KEY
		    INNER JOIN POITSCHD ps on ps.UNIQLNNO=p.UNIQLNNO
		WHERE receiverDetl.isCompleted=0
			 AND (((@poNumber IS NULL OR @poNumber='') OR (receiverHdr.ponum LIKE '%'+ RTRIM(@poNumber) +'%'))
			 AND ((@partNumber IS NULL OR @partNumber='') OR (inventor.PART_NO LIKE '%'+ RTRIM(@partNumber) +'%'))
			 --07/06/2018 Satish B : Added filter for part revision
			 AND ((@partRev IS NULL OR @partRev='') OR (inventor.Revision LIKE '%'+ RTRIM(@partRev) +'%'))
			 AND ((@supplier IS NULL OR @supplier='') OR (supinfo.SUPNAME LIKE '%'+ RTRIM(@supplier) +'%'))
			 AND ((@workOrder IS NULL OR @workOrder ='') OR (ps.REQUESTTP='WO Alloc' and ps.WOPRJNUMBER LIKE '%'+ RTRIM(@workOrder) +'%'))
			 AND ((@project IS NULL OR @project = '') OR(ps.REQUESTTP='Prj Alloc ' and ps.WOPRJNUMBER LIKE '%'+ RTRIM(@project) +'%')))
		GROUP BY inventor.UNIQ_KEY,INVENTOR.PART_NO,receiverHdr.ponum,SUPINFO.SUPNAME,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.REVISION,
				  inventor.Descript,receiverDetl.uniqlnno,receiverDetl.Partmfgr,receiverDetl.mfgr_pt_no,inventor.ITAR
		ORDER BY receiverHdr.ponum
		OFFSET(@startRecord-1) ROWS
		FETCH NEXT @EndRecord ROWS ONLY;
		SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempRevDetails) -- Set total count to Out parameter 
	END
	ELSE
		BEGIN
			SELECT COUNT(1) AS RowCnt -- Get total counts 
			INTO #tempReceivingDetails 
			FROM INVENTOR inventor
				INNER JOIN receiverDetail receiverDetl ON receiverDetl.Uniq_key = inventor.Uniq_key	
				INNER JOIN receiverHeader receiverHdr ON receiverHdr.receiverHdrId = receiverDetl.receiverHdrId
				INNER JOIN POMAIN pomain ON receiverHdr.PONUM = pomain.PONUM
				INNER JOIN SUPINFO supinfo ON pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			 WHERE receiverDetl.isCompleted=0
				 AND (((@poNumber IS NULL OR @poNumber='') OR (receiverHdr.ponum LIKE '%'+ RTRIM(@poNumber) +'%'))
				 AND ((@partNumber IS NULL OR @partNumber='') OR (inventor.PART_NO LIKE '%'+ RTRIM(@partNumber) +'%'))
				 AND ((@supplier IS NULL OR @supplier='') OR (supinfo.SUPNAME LIKE '%'+ RTRIM(@supplier) +'%')))
			 GROUP BY inventor.UNIQ_KEY,INVENTOR.PART_NO,receiverHdr.ponum,SUPINFO.SUPNAME,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.REVISION,
					  Descript,receiverDetl.uniqlnno,receiverDetl.Partmfgr,receiverDetl.mfgr_pt_no
					   --09/12/2017 Satish B : Select ITAR in group by
					  ,inventor.ITAR 
			 SELECT RTRIM(inventor.PART_NO) + CASE WHEN inventor.REVISION IS NULL OR inventor.REVISION='' THEN '' ELSE '/' END + inventor.REVISION AS PartNumber
				,RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_CLASS IS NULL OR inventor.PART_CLASS='' THEN '' ELSE '/' END + 
						 RTRIM(inventor.PART_TYPE) + CASE WHEN inventor.PART_TYPE IS NULL OR inventor.PART_TYPE='' THEN '' ELSE '/' END +
						 inventor.DESCRIPT AS Descript
				,inventor.UNIQ_KEY AS UniqKey
				,receiverDetl.Partmfgr
				,receiverDetl.mfgr_pt_no AS MfgrPartNo
				,SUM(receiverDetl.Qty_rec) AS Quantity
				,supinfo.SUPNAME AS Supplier
				,CAST(dbo.fremoveLeadingZeros(receiverHdr.ponum) AS VARCHAR(MAX)) AS PoNumber
				,receiverDetl.uniqlnno
				--09/12/2017 Satish B : Select ITAR column
				,inventor.ITAR
			FROM INVENTOR inventor
				INNER JOIN receiverDetail receiverDetl ON receiverDetl.Uniq_key = inventor.Uniq_key	
				INNER JOIN receiverHeader receiverHdr ON receiverHdr.receiverHdrId = receiverDetl.receiverHdrId
				INNER JOIN POMAIN pomain ON receiverHdr.PONUM = pomain.PONUM
				INNER JOIN SUPINFO supinfo ON pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			WHERE receiverDetl.isCompleted=0
				 AND (((@poNumber IS NULL OR @poNumber='') OR (receiverHdr.ponum LIKE '%'+ RTRIM(@poNumber) +'%'))
				 AND ((@partNumber IS NULL OR @partNumber='') OR (inventor.PART_NO LIKE '%'+ RTRIM(@partNumber) +'%'))
				  --07/06/2018 Satish B : Added filter for part revision
			     AND ((@partRev IS NULL OR @partRev='') OR (inventor.Revision LIKE '%'+ RTRIM(@partRev) +'%'))
				 AND ((@supplier IS NULL OR @supplier='') OR (supinfo.SUPNAME LIKE '%'+ RTRIM(@supplier) +'%')))
			GROUP BY inventor.UNIQ_KEY,INVENTOR.PART_NO,receiverHdr.ponum,SUPINFO.SUPNAME,INVENTOR.PART_CLASS,INVENTOR.PART_TYPE,INVENTOR.REVISION,
					  Descript,receiverDetl.uniqlnno,receiverDetl.Partmfgr,receiverDetl.mfgr_pt_no
					  --09/12/2017 Satish B : Select ITAR in group by
					  ,inventor.ITAR 
			ORDER BY receiverHdr.ponum
			OFFSET(@startRecord-1) ROWS
			FETCH NEXT @EndRecord ROWS ONLY;
			SET @outTotalNumberOfRecord = (SELECT COUNT(1) FROM #tempReceivingDetails) -- Set total count to Out parameter 
		END
END