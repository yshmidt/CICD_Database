-- =================================================
-- Author:		Shivshankar P
-- Create date: <04/19/2017>
-- DescriptiON:	PO receiving label printing
-- PoLineItemsView '000000000001518'
-- Modification
-- 10/11/2017 Rajendra K : Added logic for Multiple label printing
-- 11/10/2017 Shiv P : Modified query to get EXPDATE, REFERENCE, LOTCODE, UNIQ_LOT column values
-- 11/11/2017 SPatil : Added Trim
-- 11/14/2017 Shiv P: Changed type Char to Varchar, Added cONditiON to get PartNo with revisiON if revisiON empty, Added joins to get data for all the parts cONditiONally
-- 11/15/17   Shiv P:  Print lables for all the Parts,Print only in Part contyains SID and apply coding standard
-- 11/17/17   Shiv P:  Print Lables for all the parts
-- 11/30/2017 Rajendra K : Added logic to get records for UnReserved components
-- 11/30/2017 Shiv P : Display AcceptedQty & removed case statement		
-- 03/16/2018 Nilesh Sa : Added @invtRecNoList
-- 03/16/2018 Nilesh Sa : Added to print GR receiving labels
-- Nilesh Sa 3/23/2018 Updated lotcode datatype & length 
-- 07/16/2018 Rajendra K : Added SupInfo and Customer table in join 
-- 07/16/2018 Rajendra K : Added SupplierName and CustPartNo in select list
-- 07/30/2018 Rajendra K : Rename COSTMER to CUSTOMER in join section
-- 09/28/2018 Rajendra K : Added Received date for SID data
-- 01/03/2018 Mahesh B: Added the mfgrPart column
-- Nitesh B: 02/5/2019 : Added new column WOPRJNUMBER and REQUESTTP   
-- Nitesh B: 01/22/2020 : Added case when ExpDate is null
-- Nitesh B: 01/22/2020 : Get ReceivedDate from INVT_Rec or INVT_RES or porecdtl for all parts
-- Vijay G: 01/28/2020 : Added new join with WareHous tabel   
-- Vijay G: 01/28/2020 : Added new join with WareHous and InvtMfgr table   
-- Vijay G: 01/28/2020 : Get Wh/Loc value
-- Shivshankar P : 04/17/2020 : Remove join with INVTMFGR table and get the location from PORECLOC  
-- Shivshankar P : 04/29/2020 : Get IPKEYUNIQUE is null then get empty string
-- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number
-- EXEC rptPOreceive 'KB2A5U97GD', '', 1, '', '', '' 
-- =================================================
CREATE PROCEDURE [dbo].[rptPOreceive]     
(
	@RecordId VarChar(10)=' ',
	@IpKeyList VARCHAR(MAX)=' ',
	@Counter INT= 1,
	@UniqReckDtl CHAR(10) =' ',
	@invtResNoList VARCHAR(MAX)=' ', -- 11/30/2017 Rajendra K : Added @invtResNoList
	@invtRecNoList VARCHAR(MAX)=' ' -- 03/16/2018 Nilesh Sa : Added @invtRecNoList
)
AS
BEGIN
SET NOCOUNT ON;

 -- 11/30/2017 Rajendra K : Added to print UnReserve components
IF(@invtResNoList <> ' '  AND @invtResNoList IS NOT NULL)
BEGIN
	SET @invtResNoList = @invtResNoList + ',';
	WITH InvtResNoList AS
	(
		SELECT SUBSTRING(@invtResNoList,1,CHARINDEX(',',@invtResNoList,1)-1) AS InvtResNo, SUBSTRING(@invtResNoList,CHARINDEX(',',@IpKeyList,1)+1,LEN(@IpKeyList)) AS Invt 
		UNION ALL
		SELECT SUBSTRING(A.Invt,1,CHARINDEX(',',A.Invt,1)-1)AS InvtResNo, SUBSTRING(A.Invt,CHARINDEX(',',A.Invt,1)+1,LEN(A.Invt)) 
		FROM InvtResNoList A WHERE LEN(A.Invt)>=1
	)								 
	SELECT InvtResNo,Invt  INTO #tempInvtResNoList FROM InvtResNoList
END	

ELSE IF(@IpKeyList <> ' '  AND @IpKeyList IS NOT NULL)
BEGIN
	SET @IpKeyList = @IpKeyList + ',';
	WITH IpKeyList AS
	(
		SELECT SUBSTRING(@IpKeyList,1,CHARINDEX(',',@IpKeyList,1)-1) AS InvtResNo, SUBSTRING(@IpKeyList,CHARINDEX(',',@IpKeyList,1)+1,LEN(@IpKeyList)) AS IpKey 
		UNION ALL
		SELECT SUBSTRING(A.IpKey,1,CHARINDEX(',',A.IpKey,1)-1)AS InvtResNo, SUBSTRING(A.IpKey,CHARINDEX(',',A.IpKey,1)+1,LEN(A.IpKey)) 
		FROM IpKeyList A WHERE LEN(a.IpKey)>=1
	)								 
	SELECT InvtResNo,IpKey  INTO #tempIpList FROM IpKeyList
END			
 -- 03/16/2018 Nilesh Sa : Added to print label for general receiving
ELSE IF(@invtRecNoList <> ' '  AND @invtRecNoList IS NOT NULL)
BEGIN
	 SELECT id AS invtRecNo INTO #tempInvtRecNoTable from dbo.[fn_simpleVarcharlistToTable](@invtRecNoList,',') order by id  
END	

DECLARE @MAXID INT, @NewCOUNTER INT
SET @NewCOUNTER = 1
		
--10/09/2017 Rajendra K : Create temp table #TempSIDList
CREATE TABLE #TempSIDList
(
	RecordId CHAR(10),
	partNoRev VARCHAR(100), -- 11/14/17 Changed type Char to Varchar
	partmfgr CHAR(8),
    mfgrPart CHAR(30),  -- 01/03/2018 Mahesh B: Added the mfgrPart column  
	DESCRIPT CHAR(45),
	ITAR BIT,
	IPKEYUNIQUE CHAR(10),
	ReceivedQty NUMERIC(12,2),
	ROHS CHAR(10),
	EXPDATE SMALLDATETIME,
	REFERENCE CHAR(12),
	LOTCODE NVARCHAR(25), -- Nilesh Sa 3/23/2018 Updated lotcode datatype & length 
	UNIQ_LOT CHAR(10),
	SupplierName CHAR(30),
	CustPartNo VARCHAR(100),
	ReceivedDate DATETIME, -- 09/28/2018 Rajendra K : Added Received date for SID data    
	WOPRJNUMBER VARCHAR(100),  
	REQUESTTP VARCHAR(30),  -- Nitesh B: 2/5/2019 Added new column WOPRJNUMBER and REQUESTTP        
	Wh_Loc VARCHAR(406), -- Vijay G: 01/28/2020 : Get Wh/Loc value  
	inspectionSource CHAR(2)   -- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number 
)

--10/11/2017 Rajendra K : Get multiple records for same IpkeyUnique
WHILE (@NewCOUNTER <= @Counter)  
BEGIN	
	 -- 03/16/2018 Nilesh Sa : Added to print GR receiving labels
    IF (@invtRecNoList IS NOT NULL AND @invtRecNoList <>'')
		BEGIN 
			INSERT INTO  #TempSIDList --11/14/17 Shiv P: Added cONditiON to get PartNo with revisiON if revisiON empty
			SELECT DISTINCT ip.RecordId,  TRIM(invt.PART_NO) + '/' + invt.REVISION as partNoRev,mfMaster.partmfgr, mfmaster.mfgr_pt_no AS mfgrPart, -- 01/03/2018 Mahesh B: Added the mfgrPart column   
			invt.DESCRIPT,invt.ITAR ,ISNULL(ip.IPKEYUNIQUE,'') AS IPKEYUNIQUE, -- Shivshankar P : 04/29/2020 : Get IPKEYUNIQUE is null then get empty string
			CASE WHEN invt.useipkey = 1 THEN iRecIpKey.qtyReceived ELSE INVT_Rec.QTYREC END AS ReceivedQty,
			invt.MATLTYPE AS ROHS ,
			CASE WHEN invt.useipkey = 1 THEN NULL ELSE IL.EXPDATE END AS EXPDATE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE IL.REFERENCE END AS REFERENCE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE IL.LOTCODE END AS LOTCODE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE IL.UNIQ_LOT END AS UNIQ_LOT,
			-- 07/16/2018 Rajendra K : Added SupplierName and CustPartNo in select list
			'' AS SupplierName,
			ISNULL(TRIM(invt.CUSTPARTNO), '') + '/' + ISNULL(invt.CUSTREV, '') AS CustPartNo, -- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number
			-- Nitesh B: 01/22/2020 : Get ReceivedDate from INVT_Rec or INVT_RES or porecdtl for all parts
			INVT_Rec.[DATE] AS ReceivedDate, -- 09/28/2018 Rajendra K : Added Received date for SID data  
			'' AS WOPRJNUMBER,
			'' AS REQUESTTP ,  -- Nitesh B: 2/5/2019 Added new columns WOPRJNUMBER and REQUESTTP       
			wh.warehouse  +  '/'  +imfgr.[LOCATION] AS Wh_Loc,    -- Vijay G: 01/28/2020 : Get Wh/Loc value   
			RecType.inspectionSource AS inspectionSource
			FROM INVT_Rec 
				INNER JOIN INVENTOR invt ON INVT_Rec.UNIQ_KEY =  invt.Uniq_key
				INNER JOIN InvtMPNLink mpn on mpn.uniq_key =invt.UNIQ_KEY
				INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
				INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =invt.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = INVT_Rec.W_KEY										
                -- Vijay G: 01/28/2020 : Added new join with WareHous tabel   
                INNER JOIN WAREHOUS wh ON wh.uniqWH=imfgr.uniqWh      
				LEFT JOIN INVTLOT IL ON IL.LOTCODE= INVT_Rec.LOTCODE AND IL.REFERENCE= INVT_Rec.REFERENCE AND 1 = (CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1 --IL.EXPDATE= INVT_Rec.EXPDATE
	       							 WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND INVT_Rec.EXPDATE IS NULL OR INVT_Rec.EXPDATE = '' THEN 1 
	       							 WHEN IL.EXPDATE = INVT_Rec.EXPDATE THEN 1 ELSE 0 END) -- Nitesh B: 01/22/2020 : Added case when ExpDate is null 
				LEFT JOIN iRecIpKey  ON INVT_Rec.INVTREC_NO = iRecIpKey.invtrec_no
				LEFT JOIN IPKEY IP ON iRecIpKey.IpKeyUnique = IP.IPKEYUNIQUE AND INVT_Rec.W_KEY = IP.W_KEY
				-- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number
				OUTER APPLY (Select rh.inspectionSource from receiverHeader rh JOIN receiverDetail rd ON rh.receiverHdrId = rd.receiverHdrId
							WHERE rd.receiverDetId = INVT_Rec.receiverdetId) AS RecType
			WHERE  INVT_Rec.INVTREC_NO IN (SELECT invtRecNo FROM #tempInvtRecNoTable)
			SET @NewCOUNTER = @NewCOUNTER + 1
		END
    -- 11/30/2017 Rajendra K : Added to print UnReserve components
  ELSE  IF (@invtResNoList IS NOT NULL AND @invtResNoList <>'')
		BEGIN 
			INSERT INTO  #TempSIDList --11/14/17 Shiv P: Added cONditiON to get PartNo with revisiON if revisiON empty
            SELECT ip.RecordId,  RTRIM(LTRIM(invt.PART_NO)) + '/' + invt.REVISION as partNoRev,mfMaster.partmfgr, mfmaster.mfgr_pt_no As mfgrPart,  -- 01/03/2018 Mahesh B: Added the mfgrPart column   
			invt.DESCRIPT,invt.ITAR ,ISNULL(ip.IPKEYUNIQUE,'') AS IPKEYUNIQUE, -- Shivshankar P : 04/29/2020 : Get IPKEYUNIQUE is null then get empty string
			(CASE WHEN IR.QTYALLOC < 0 THEN -IR.QTYALLOC ELSE IR.QTYALLOC END) AS ReceivedQty,
			invt.MATLTYPE AS ROHS ,
			CASE WHEN invt.useipkey = 1 THEN NULL ELSE IL.EXPDATE END AS EXPDATE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE IL.REFERENCE END AS REFERENCE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE IL.LOTCODE END AS LOTCODE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE IL.UNIQ_LOT END AS UNIQ_LOT,
			-- 07/16/2018 Rajendra K : Added SupplierName and CustPartNo in select list
			'' AS SupplierName,
			'' AS CustPartNo,
			-- Nitesh B: 01/22/2020 : Get ReceivedDate from INVT_Rec or INVT_RES or porecdtl for all parts
			IR.[DATETIME] AS ReceivedDate, -- 09/28/2018 Rajendra K : Added Received date for SID data     
			'' AS WOPRJNUMBER,
			'' AS REQUESTTP ,  -- Nitesh B: 2/5/2019 Added new columns WOPRJNUMBER and REQUESTTP        
			wh.warehouse  +  '/'  +imfgr.LOCATION AS Wh_Loc, -- Vijay G: 01/28/2020 : Get Wh/Loc value   
			'' AS inspectionSource   -- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number
			FROM INVT_RES IR
				INNER JOIN INVENTOR invt ON IR.UNIQ_KEY =  invt.Uniq_key
				INNER JOIN InvtMPNLink mpn on mpn.uniq_key =invt.UNIQ_KEY
				INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
				INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =invt.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = IR.W_KEY										
                -- Vijay G: 01/28/2020 : Added new join with WareHous tabel   
                INNER JOIN WAREHOUS wh ON wh.uniqWH=imfgr.uniqWh     
				LEFT JOIN INVTLOT IL ON IL.LOTCODE= IR.LOTCODE AND IL.REFERENCE= IR.REFERENCE AND 1 = (CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1 --IL.EXPDATE= IR.EXPDATE
	       							 WHEN IL.EXPDATE IS NULL OR IL.EXPDATE= '' AND IR.EXPDATE IS NULL OR IR.EXPDATE = '' THEN 1 
	       							 WHEN IL.EXPDATE = IR.EXPDATE THEN 1 ELSE 0 END) -- Nitesh B: 01/22/2020 : Added case when ExpDate is null 
				LEFT JOIN IReserveIpKey IRP ON IR.INVTRES_NO = IRP.INVTRES_NO AND IR.KaSeqnum = IRP.KaSeqnum
				LEFT JOIN IPKEY IP ON IRP.IpKeyUnique = IP.IPKEYUNIQUE AND IR.W_KEY = IP.W_KEY
			WHERE  IR.INVTRES_NO IN (SELECT InvtResNo FROM #tempInvtResNoList)
			SET @NewCOUNTER = @NewCOUNTER + 1
		END
	ELSE IF ( @IpKeyList = ' ' OR @IpKeyList IS NULL)
		BEGIN    
		    --11/15/17 Shiv P: Print lables for all the Parts
			INSERT INTO  #TempSIDList --11/14/17 Shiv P: Added cONditiON to get PartNo with revisiON if revisiON empty
			SELECT IPKEY.RecordId, CASE WHEN invt.REVISION Is NOT NULL and invt.REVISION <> '' THEN
			RTRIM(LTRIM(invt.PART_NO)) + '/' + RTRIM(LTRIM(invt.REVISION)) 
			ELSE  RTRIM(LTRIM(invt.PART_NO))
            END AS partNoRev,prd.partmfgr, prd.mfgr_pt_no As mfgrPart,  --11/10/2017 Shiv P : Modified query to get EXPDATE, REFERENCE, LOTCODE, UNIQ_LOT column values    -- 01/03/2018 Mahesh B: Added the mfgrPart column
			RTRIM(LTRIM(invt.DESCRIPT)) -- 11/11/2017 SPatil : Added Trim
			,invt.ITAR , ISNULL(IPKEY.IPKEYUNIQUE,'') AS IPKEYUNIQUE -- Shivshankar P : 04/29/2020 : Get IPKEYUNIQUE is null then get empty string
			,ISNULL(IPKEY.pkgBalance,ISNULL(INVTLOT.LOTQTY,ISNULL(prd.AcceptedQty,0))), --11/30/2017 Shiv P : Display AcceptedQty & removed case statement			
			invt.MATLTYPE AS ROHS ,
			CASE WHEN invt.useipkey = 1 THEN NULL ELSE INVTLOT.EXPDATE END AS EXPDATE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE INVTLOT.REFERENCE END AS REFERENCE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE INVTLOT.LOTCODE END AS LOTCODE,
			CASE WHEN invt.useipkey = 1 THEN '' ELSE INVTLOT.UNIQ_LOT END AS UNIQ_LOT,
			-- 07/16/2018 Rajendra K : Added SupplierName and CustPartNo in select list
			ISNULL(s.SupName,'') AS SupplierName,
			ISNULL(Invt.CUSTPARTNO,'') AS CustPartNo,
			-- Nitesh B: 01/22/2020 : Get ReceivedDate from INVT_Rec or INVT_RES or porecdtl for all parts
			prd.[recvdate] AS ReceivedDate, -- 09/28/2018 Rajendra K : Added Received date for SID data    
			--,INVTLOT.EXPDATE,INVTLOT.REFERENCE,INVTLOT.LOTCODE ,INVTLOT.UNIQ_LOT
			dbo.fRemoveLeadingZeros(POITSCHD.WOPRJNUMBER),   
			POITSCHD.REQUESTTP,  -- Nitesh B: 2/5/2019 Added new columns WOPRJNUMBER and REQUESTTP  
			-- Shivshankar P : 04/17/2020 : Remove join with INVTMFGR table and get the location from PORECLOC     
			wh.warehouse  +  '/'  +PORECLOC.LOCATION AS Wh_Loc,    -- Vijay G: 01/28/2020 : Get Wh/Loc value  
			'' AS inspectionSource    -- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number
			FROM porecdtl prd 
			JOIN PORECLOC ON uniqrecdtl = FK_UNIQRECDTL AND PORECLOC.ACCPTQTY > 0--11/14/17 Shiv P: Added joins to get data for all the parts cONditiONally
			LEFT JOIN receiverDetail ON  receiverDetail.receiverDetId =prd.receiverdetId
			LEFT JOIN receiverHeader ON  receiverHeader.receiverHdrId =receiverDetail.receiverHdrId
			LEFT JOIN PORECLOT ON PORECLOC.LOC_UNIQ= PORECLOT.LOC_UNIQ
			LEFT JOIN INVTLOT ON INVTLOT.LOTCODE= PORECLOT.LOTCODE AND INVTLOT.REFERENCE= PORECLOT.REFERENCE AND 1 = (CASE WHEN INVTLOT.LOTCODE IS NULL OR INVTLOT.LOTCODE= '' THEN 1 --INVTLOT.EXPDATE= PORECLOT.EXPDATE
	       							 WHEN INVTLOT.EXPDATE IS NULL OR INVTLOT.EXPDATE= '' AND PORECLOT.EXPDATE IS NULL OR PORECLOT.EXPDATE = '' THEN 1 
	       							 WHEN INVTLOT.EXPDATE = PORECLOT.EXPDATE THEN 1 ELSE 0 END) -- Nitesh B: 01/22/2020 : Added case when ExpDate is null
			LEFT JOIN IPKEY ON  prd.uniqrecdtl =  IPKEY.RecordId
			LEFT JOIN INVENTOR invt ON receiverDetail.UNIQ_KEY =  invt.Uniq_key 	
            -- Vijay G: 01/28/2020 : Added new join with WareHous and InvtMfgr table   
			-- Shivshankar P : 04/17/2020 : Remove join with INVTMFGR table and get the location from PORECLOC     
            --INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =receiverDetail.UNIQ_KEY AND imfgr.UNIQMFGRHD = prd.uniqmfgrhd AND imfgr.W_KEY = IPKEY.W_KEY      
            INNER JOIN WAREHOUS wh ON wh.uniqWH=PORECLOC.uniqWh        
			-- 07/16/2018 Rajendra K : Added SupInfo and Customer table in join 	
			LEFT JOIN SUPINFO s ON receiverHeader.senderId = s.UNIQSUPNO		
			-- 07/30/2018 Rajendra K : Rename COSTMER to CUSTOMER in join section
			LEFT JOIN CUSTOMER C ON receiverHeader.senderId = C.CUSTNO
            LEFT JOIN POITSCHD ON POITSCHD.UNIQLNNO = prd.uniqlnno   -- Nitesh B: 2/5/2019 Added new column WOPRJNUMBER,REQUESTTP  
			WHERE ((@RecordId  IS NOT NULL AND @RecordId <> '' AND @uniqReckDtl =' ' AND IPKEY.RecordId = @RecordId ) OR
			       (@RecordId = ' ' AND @uniqReckDtl IS NOT NULL AND @uniqReckDtl <> ' ' AND prd.uniqrecdtl = @uniqReckDtl )) -- 11/17/17   Shiv P:  Print Lables for all the parts
			SET @NewCOUNTER = @NewCOUNTER + 1
		END
	ELSE  
		BEGIN 
			--11/15/17 Shiv P: Print only in Part contyains SID
			INSERT INTO  #TempSIDList --11/14/17 Shiv P: Added cONditiON to get PartNo with revisiON if revisiON empty
            SELECT ip.RecordId,  rtrim(ltrim(invt.PART_NO)) + '/' + invt.REVISION as partNoRev,mfMaster.partmfgr,mfMaster.mfgr_pt_no As mfgrPart,  -- 01/03/2018 Mahesh B: Added the mfgrPart column
			invt.DESCRIPT,invt.ITAR , ISNULL(ip.IPKEYUNIQUE,'') AS IPKEYUNIQUE, -- Shivshankar P : 04/29/2020 : Get IPKEYUNIQUE is null then get empty string
			ip.pkgBalance AS ReceivedQty,invt.MATLTYPE AS ROHS ,NULL,'','','',
			-- 07/16/2018 Rajendra K : Added SupplierName and CustPartNo in select list
			'' AS SupplierName,
			ISNULL(Invt.CUSTPARTNO,'') AS CustPartNo,
			IP.RecordCreated AS ReceivedDate, -- 09/28/2018 Rajendra K : Added Received date for SID data     
			'' AS WOPRJNUMBER,
			'' AS REQUESTTP,   -- Nitesh B: 2/5/2019 Added new columns WOPRJNUMBER and REQUESTTP        
			wh.warehouse  +  '/'  +imfgr.LOCATION AS Wh_Loc,    -- Vijay G: 01/28/2020 : Get Wh/Loc value 
			'' AS inspectionSource   -- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number
			FROM IPKEY ip 
			INNER JOIN INVENTOR invt ON ip.UNIQ_KEY =  invt.Uniq_key
			INNER JOIN InvtMPNLink mpn on mpn.uniq_key =invt.UNIQ_KEY
			INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
			INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =invt.UNIQ_KEY AND imfgr.UNIQMFGRHD = mpn.uniqmfgrhd AND imfgr.W_KEY = ip.W_KEY										
            -- Vijay G: 01/28/2020 : Added new join with WareHous table  
            INNER JOIN WAREHOUS wh ON imfgr.UNIQWH=wh.UNIQWH                 
			WHERE  ip.IPKEYUNIQUE IN  (SELECT InvtResNo FROM #tempIpList)
			SET @NewCOUNTER = @NewCOUNTER + 1			
		END
	END
--10/11/2017 Rajendra K : Get Result from #TempSIDList 
--11/10/2017 Shiv P : Modified query to get EXPDATE, REFERENCE, LOTCODE, UNIQ_LOT column values
-- Vijay G: 01/28/2020 : Get Wh/Loc value 
-- Shivshankar P : 12/30/2020 : Get inspectionSource and CustPartNo for the receiving type and customer part number      
SELECT DISTINCT RecordId,partNoRev,partmfgr,mfgrPart, DESCRIPT,ITAR,IPKEYUNIQUE,ReceivedQty,ROHS,EXPDATE,REFERENCE,LOTCODE,UNIQ_LOT,ReceivedDate,WOPRJNUMBER,REQUESTTP,Wh_Loc,inspectionSource,CustPartNo FROM #TempSIDList ORDER BY IPKEYUNIQUE         
-- 09/28/2018 Rajendra K : Added Received date for SID data            
-- Nitesh B: 2/5/2019 Added new column WOPRJNUMBER and REQUESTTP  
-- 01/03/2018 Mahesh B: Added the mfgrPart column
END