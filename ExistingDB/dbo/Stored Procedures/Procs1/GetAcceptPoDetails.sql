-- =============================================
-- Author:Satish B
-- Create date: 06/16/2017
-- Description:	Get accepted data details in accepted queue tab
-- Modified : 06/28/2017 Satish B : Added ITAR column
--		    : 06/29/2017 Satish B : Use existing function to remove leading zeros
--		    : 07/25/2017 Satish B : Change the filter condition from (insHeader.FailedQty -insHeader.ReturnQty>0) to (insHeader.FailedQty -insHeader.ReturnQty-insHeader.Buyer_Accept >0) 
--		    : 08/16/2017 Satish B : Comment selection of only description and select class,type and description as Description
--		    : 08/28/2017 Satish B : Select Distinct record
--		    : 08/28/2017 Satish B : Comment extra filter of invtmfgr.uniqwh=@uniqMrbWh
--		    : 08/28/2017 Satish B : Avoid selection of Uniqlot,lotcode,ecpdate and reference when rejected at Receiving and Inspection
--		    : 08/28/2017 Satish B : Modified the where condition
--		    : 10/12/2017 Satish B : Added filter of invtlot.W_KEY=invtmfgr.W_KEY
--			: 05/09/2018 Satish B : Modified the where condition : Check IsInspReq and IsInspCompleted only when Rejected At = 'Inspection' and optimize the condition
--			: 05/23/2018 Satish B : Added new parameter @startRecord,@endRecord,@filter
--			: 05/23/2018 Satish B : Added the code to apply filters
--			: 06/13/2018 Satish B : Modified the filters i.e.Added the '(' and ')' bracket
--          : 04/30/2020 Shivshankar P : Added OUTER APPLY to get recordId of note
--          : 05/05/2020 Shivshankar P : Added OUTER APPLY to get UNIQMFGRHD from INVTMFGR if POITEM.UNIQMFGRHD is empty or null 
-- exec GetAcceptPoDetails 
-- =============================================
CREATE PROCEDURE GetAcceptPoDetails
 -- 05/23/2018 Satish B : Added new parameter @startRecord,@endRecord,@filter
 @startRecord INT =1,
 @endRecord INT =150,
 @filter NVARCHAR(1000) = null
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 DECLARE @sqlQuery NVARCHAR(MAX);	    
	 DECLARE @uniqMrbWh char(10)=' '
		SELECT @uniqMrbWh = UniqWH  
				FROM WAREHOUS where  Warehouse='MRB'
	 --08/28/2017 Satish B : Select Distinct record
	 SELECT DISTINCT insHeader.InspHeaderId
	 ,recHeader.RecPklNo
	 ,recHeader.senderId AS SenderId
	 ,inventor.Part_No As PartNo
	 ,inventor.Revision
	 ,inventor.SERIALYES
	 --06/28/2017 Satish B : Added ITAR column
	 ,inventor.ITAR
	 ,inventor.useipkey
	 ,parttype.LOTDETAIL
	 --08/16/2017 Satish B : Comment selection of only description and select class,type and description as Description
	 --,inventor.Descript As Description
	 ,RTRIM(inventor.PART_CLASS) + CASE WHEN inventor.PART_CLASS IS NULL OR inventor.PART_CLASS='' THEN '' ELSE '/' END + 
				 RTRIM(inventor.PART_TYPE) + CASE WHEN inventor.PART_TYPE IS NULL OR inventor.PART_TYPE='' THEN '' ELSE '/' END +
				 inventor.DESCRIPT AS Description
	 ,recDetail.PartMfgr
	 ,recDetail.mfgr_pt_no As MfgrPtNo
	 ,insHeader.RejectedAt
	 ,(insHeader.FailedQty - insHeader.Buyer_Accept-insHeader.ReturnQty) As Rejected
	 ,insHeader.ReturnQty As ReturnedQty
	 ,(CASE WHEN insHeader.BuyerAction='Accept' THEN  insHeader.FailedQty - insHeader.Buyer_Accept- insHeader.ReturnQty ELSE NULL END) As Returned
	 ,inventor.Uniq_Key As UniqKey
	 -- 05/05/2020 Shivshankar P : Added OUTER APPLY to get UNIQMFGRHD from INVTMFGR if POITEM.UNIQMFGRHD is empty or null 
	 --,poitem.UNIQMFGRHD As UniqMfgrHd
	 ,IIF(TRIM(ISNULL(poitem.UNIQMFGRHD,'')) = '',tempmfgr.UNIQMFGRHD, poitem.UNIQMFGRHD) As UniqMfgrHd
	 --08/28/2017 Satish B : Avoid selection of Uniqlot,lotcode,ecpdate and reference when rejected at Receiving and Inspection
	 ,CASE WHEN insHeader.RejectedAt='Production' THEN  invtlot.UNIQ_LOT ELSE '' END AS UNIQ_LOT   
	 ,CASE WHEN (insHeader.RejectedAt='Production') THEN  invtlot.LOTCODE   ELSE '' END AS LOTCODE
	 ,CASE WHEN (insHeader.RejectedAt='Production') THEN  invtlot.REFERENCE   ELSE '' END AS REFERENCE
	 ,CASE WHEN (insHeader.RejectedAt='Production') THEN  invtlot.EXPDATE   ELSE '' END AS EXPDATE
     ,ipkey.IPKEYUNIQUE
	 ,invtmfgr.W_KEY
	 ,recHeader.receiverno AS ReceiverNo
	 ,recDetail.uniqlnno As UniqlnNo
	 --06/29/2017 Satish B : Use existing function to remove leading zeros
	 ,CAST(dbo.fremoveLeadingZeros(recHeader.PONUM) AS VARCHAR(MAX)) AS PoNumber
	 --,SUBSTRING(recHeader.PONUM , PATINDEX('%[^0]%',recHeader.PONUM ), 10) AS PoNumber
	 ,sup.SUPNAME AS Supplier
	 ,Note.RecordId -- 04/30/2020 Shivshankar P : Added OUTER APPLY to get recordId of note
	 INTO #tempAcceptDet
	 FROM inspectionHeader insHeader
		INNER JOIN receiverDetail recDetail ON recDetail.receiverDetId=insHeader.receiverDetId
		INNER JOIN receiverHeader recHeader ON recHeader.receiverHdrId=recDetail.receiverHdrId
		INNER JOIN Inventor inventor ON  recDetail.Uniq_key=inventor.Uniq_Key
		INNER JOIN PARTTYPE parttype ON  parttype.PART_CLASS=inventor.PART_CLASS AND parttype.PART_TYPE=inventor.PART_TYPE
		INNER JOIN POITEMS poitem ON  recDetail.Uniq_key=poitem.UNIQ_KEY and recHeader.ponum=poitem.PONUM
		LEFT JOIN porecdtl ON porecdtl.receiverdetId=recDetail.receiverDetId
		LEFT JOIN PORECLOC porecloc ON  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl
		INNER JOIN SUPINFO sup ON recHeader.SenderId=sup.Uniqsupno
		LEFT JOIN poreclot ON porecloc.LOC_UNIQ=poreclot.loc_uniq
		LEFT JOIN INVTMFGR invtmfgr ON poitem.UNIQ_KEY=invtmfgr.UNIQ_KEY AND invtmfgr.UNIQWH=@uniqMrbWh AND invtmfgr.INSTORE = 0 AND insHeader.inspHeaderId=invtmfgr.LOCATION 
		LEFT JOIN INVTLOT invtlot ON poreclot.LOTCODE=invtlot.lotcode
							AND poreclot.EXPDATE=invtlot.expdate
							AND poreclot.REFERENCE=invtlot.reference 
							-- 10/12/2017 Satish B : Added filter of invtlot.W_KEY=invtmfgr.W_KEY
							AND invtlot.W_KEY=invtmfgr.W_KEY
		-- 08/28/2017 Satish B : Comment extra filter of invtmfgr.uniqwh=@uniqMrbWh
		--AND invtmfgr.uniqwh=@uniqMrbWh
		LEFT JOIN IPKEY ipkey ON ipkey.W_KEY=invtmfgr.W_KEY
		-- 04/30/2020 Shivshankar P : Added OUTER APPLY to get recordId of note
		OUTER APPLY (SELECT RecordId FROM wmNotes WHERE RecordType = 'BuyerAction' and RecordId = recHeader.ponum)Note 
		-- 05/05/2020 Shivshankar P : Added OUTER APPLY to get UNIQMFGRHD from INVTMFGR if POITEM.UNIQMFGRHD is empty or null 
		OUTER APPLY (SELECT top 1 UNIQMFGRHD FROM INVTMFGR im WHERE  poitem.UNIQ_KEY=im.UNIQ_KEY AND im.UNIQWH = PORECLOC.uniqWh AND porecloc.LOCATION=im.LOCATION )tempmfgr
		-- 08/28/2017 Satish B : Modified the where condition
		WHERE insHeader.BuyerAction='Accept' and
		      -- 05/09/2018 Satish B : Modified the where condition : Check IsInspReq and IsInspCompleted only when Rejected At = 'Inspection' and optimize the condition
			  -- 06/13/2018 Satish B : Modified the filters i.e.Added the '(' and ')' bracket
			  (insHeader.RejectedAt IN('Receiving','Production') OR 
			  ((insHeader.RejectedAt='Inspection') AND (recDetail.IsInspReq = recDetail.IsInspCompleted))) -- OR (recDetail.IsInspReq=0 and recDetail.IsInspCompleted=0))) 
			  -- Modified : 07/25/2017 Satish B : Change the filter condition from (insHeader.FailedQty -insHeader.ReturnQty>0) to (insHeader.FailedQty -insHeader.ReturnQty-insHeader.Buyer_Accept >0) 
			  AND ((insHeader.FailedQty -insHeader.ReturnQty-insHeader.Buyer_Accept) >0) 
			 
  -- 05/23/2018 Satish B : Added the code to apply filters
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempAcceptDet',@filter,'','PoNumber','',@startRecord,@endRecord))
	EXEC sp_executesql @sqlQuery
 END

