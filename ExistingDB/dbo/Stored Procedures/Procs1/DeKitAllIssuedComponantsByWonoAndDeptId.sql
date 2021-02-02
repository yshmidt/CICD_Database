-- =============================================
-- Author:	Sachin B
-- Create date: 11/28/2016
-- Description:	this procedure will be called from the SF module and DeKit all the issued componants to work order by WONo and DeptID
-- DeKitAllIssuedComponantsByWonoAndDeptId '0000000555','STAG'
-- DeKitAllIssuedComponantsByWonoAndDeptId '0000000558','STAG'
-- 08/09/2017 Sachin B remove Ambiguity of k.Dept_Id and use as k.DEPT_ID
-- 10/16/2017 Sachin B correct the Syntex for the SP parameter and variable declares
-- 10/16/2017 Sachin B Implement Logic for the breaking SID and Create new SID for the SID Parts 
-- 02/06/2018 YS Changed lotcode column length
-- 01/25/2019 Sachin B Fix the Issue on DeKit Will Insert wrong data on the Invt_Isu and Issueipkey table if same comp is available at more then one Work Center add join with kaseqnum
-- =============================================
-- 10/16/2017 Sachin B correct the Syntex for the SP parameter and variable declares
CREATE PROCEDURE [dbo].[DeKitAllIssuedComponantsByWonoAndDeptId]  
  @woNo CHAR(10),
  @deptId CHAR(10) = NULL,
  @userId UNIQUEIDENTIFIER= NULL	
AS
BEGIN
SET NOCOUNT ON;

-- get ready to handle any errors
	DECLARE @errorMessage NVARCHAR(4000);
    DECLARE @errorSeverity INT;
    DECLARE @errorState INT;

	--Temp table for warehous/lot
	-- 02/06/2018 YS Changed lotcode column length
	DECLARE @warehouseLotIssuedData TABLE (invtisu_no CHAR(10),UNIQ_KEY CHAR(10),w_key CHAR(10),ExpDate SMALLDATETIME,REFERENCE CHAR(12),
	LotCode nvarchar(25),PONUM CHAR(15)
	,QtyUsed NUMERIC(12,2),IsLotted BIT,useipkey BIT,serialyes BIT,kaseqnum CHAR(10))

	--Temp table for IssueIpKey
	DECLARE @issueIpKeyData TABLE (invtisu_no CHAR(10),IPKEYUNIQUE CHAR(10),QtyUsed NUMERIC(12,2))

	--Temp table for IssueSerial
	DECLARE @issueSerialData TABLE (invtisu_no CHAR(10),IPKEYUNIQUE CHAR(10),SERIALUNIQ CHAR(10),SERIALNO CHAR(30))

	-- get g/l # for the wip account
	DECLARE @wipGL CHAR(13)
	SELECT @wipGl=dbo.fn_GetWIPGl()
	
	BEGIN TRY
	BEGIN TRANSACTION 

;WITH IssuedComponantList AS (
			SELECT i.UNIQ_KEY AS UniqKey,p.LOTDETAIL AS IsLotted, i.useipkey, i.serialyes, k.act_qty AS QtyIssued,KaSeqnum
			FROM kamain k
			INNER JOIN WOENTRY w ON w.WONO =k.WONO
			INNER JOIN inventor i ON k.uniq_key=i.uniq_key
			LEFT JOIN PARTTYPE p ON p.PART_TYPE = i.PART_TYPE AND p.PART_CLASS = i.PART_CLASS
			WHERE  k.wono= @woNo 
			-- 08/09/2017 Sachin B remove Ambiguity of k.Dept_Id and use as k.DEPT_ID
			AND (@deptId IS NULL OR @deptId='' OR k.DEPT_ID = @deptId) AND k.act_qty > 0
			GROUP BY i.useipkey, i.serialyes, i.UNIQ_KEY ,k.act_qty,p.LOTDETAIL,KaSeqnum
)

INSERT INTO @warehouseLotIssuedData
SELECT  dbo.fn_GenerateUniqueNumber() AS invtisu_no,Isulist.UniqKey,isu.w_key,isu.ExpDate,isu.Reference,isu.LotCode,isu.PONUM,SUM(Qtyisu) AS 'QtyUsed', 
			 IsLotted,Isulist.useipkey,Isulist.serialyes,Isulist.KaSeqnum 
			FROM invt_isu isu
			INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY
			-- 01/25/2019 Sachin B Fix the Issue on DeKit Will Insert wrong data on the Invt_Isu and Issueipkey table if same comp is available at more then one Work Center add join with kaseqnum
			INNER JOIN IssuedComponantList Isulist ON  i.UNIQ_KEY = Isulist.UniqKey AND isu.kaseqnum =Isulist.KASEQNUM
			INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY AND isu.UNIQMFGRHD = mpn.uniqmfgrhd
			INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
			INNER JOIN INVTMFGR mf ON isu.uniq_key = mf.uniq_key AND isu.UNIQMFGRHD = mf.UNIQMFGRHD AND mf.W_KEY =isu.W_KEY
			INNER JOIN WAREHOUS w ON mf.UNIQWH = w.UNIQWH			
			LEFT OUTER JOIN invtlot lot ON ISNULL(lot.W_KEY,'') =ISNULL(isu.w_key,'') AND  ISNULL(lot.lotcode,'') = ISNULL(isu.lotcode,'')  AND  ISNULL(lot.EXPDATE,1) = ISNULL(isu.EXPDATE,1) 
			AND  ISNULL(lot.REFERENCE,'') = ISNULL(isu.REFERENCE,'') 
			WHERE isu.ISSUEDTO LIKE '%(WO:'+@woNo+'%'
			AND isu.wono =@woNo 
			GROUP BY Partmfgr,mfgr_pt_no,Warehouse,Location,isu.ExpDate,isu.Reference,isu.LotCode,isu.PONUM,isu.W_KEY,Isulist.UniqKey,IsLotted,Isulist.useipkey,Isulist.serialyes,Isulist.KaSeqnum 
			HAVING SUM(Qtyisu) > 0


--Getting Issued IPkey Data for the WoNo 
INSERT INTO @issueIpKeyData
SELECT DISTINCT ware.invtisu_no, isuIp.IPKEYUNIQUE,SUM(isuIP.qtyissued) AS QtyUsed
		FROM invt_isu isu 		
		INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY
		INNER JOIN issueipkey isuIP ON isu.invtisu_no = isuIP.invtisu_no 
		INNER JOIN ipkey ip ON isuIP.ipkeyunique = ip.IPKEYUNIQUE
		-- 01/25/2019 Sachin B Fix the Issue on DeKit Will Insert wrong data on the Invt_Isu and Issueipkey table if same comp is available at more then one Work Center add join with kaseqnum
		INNER JOIN @warehouseLotIssuedData ware ON ip.UNIQ_KEY = ware.UNIQ_KEY AND isu.kaseqnum =ware.KASEQNUM
		AND ip.W_KEY = ware.W_KEY and ISNULL(ip.ExpDate,1) = ISNULL(ware.ExpDate,1) AND ip.Reference = ware.Reference AND ip.LotCode = ware.LotCode AND ip.PONUM = ware.PONUM
		WHERE isu.ISSUEDTO LIKE '%(WO:'+@woNo+'%' AND isu.wono =@woNo AND ware.useipkey =1 AND ware.SERIALYES = 0
		--and 
		GROUP BY ware.invtisu_no,isuIp.IPKEYUNIQUE
		HAVING SUM(isuIP.qtyissued) >0

--Getting Issued Serial Data for the WoNo
INSERT INTO @issueSerialData
SELECT DISTINCT ware.invtisu_no,ser.IPKEYUNIQUE,ser.SERIALUNIQ,ser.SERIALNO 
				FROM invt_isu isu
				INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY
				INNER JOIN issueSerial isuSer ON isu.invtisu_no = isuSer.invtisu_no 
				INNER JOIN INVTSER ser ON isuSer.SERIALUNIQ = ser.SERIALUNIQ
				Inner Join @warehouseLotIssuedData ware ON ser.UNIQ_KEY = ware.UNIQ_KEY 
		        AND ISNULL(ser.ExpDate,1) = ISNULL(ware.ExpDate,1) AND ser.Reference = ware.Reference AND ser.LotCode = ware.LotCode AND ser.PONUM = ware.PONUM
				WHERE isu.ISSUEDTO LIKE '%(WO:'+@woNo+'%' AND isu.wono =@woNo  AND ser.ID_KEY = 'WONO' AND ser.ID_VALUE = @woNo

        --De-Kit componants and put negative entry of qtyisu on the Invt_ISU table
        INSERT INTO invt_isu (invtisu_no,w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)
	    SELECT ware.invtisu_no,ware.w_key,ware.UNIQ_KEY,'(WO:'+@woNo,-QtyUsed,@wipGl,@woNo,m.UNIQMFGRHD,@userid,KaSeqnum,ware.LOTCODE,ware.EXPDATE,ware.REFERENCE,ware.PONUM
	    FROM @warehouseLotIssuedData ware INNER JOIN invtmfgr m ON ware.W_key=m.W_KEY

	   -- De-Kit ipkey
		INSERT INTO issueipkey (invtisu_no,qtyissued,ipkeyunique,kaseqnum,issueIpKeyUnique)
		SELECT ip.invtisu_no,-ip.QtyUsed,ip.ipKeyUnique,ware.kaseqnum,dbo.fn_GenerateUniqueNumber() FROM @issueIpKeyData ip 
		INNER JOIN @warehouseLotIssuedData ware ON ip.invtisu_no=ware.invtisu_no
		
		-- De-Kit serial numbers
		INSERT INTO issueSerial (serialno,SerialUniq,iIssueSerUnique,invtisu_no,ipkeyunique,kaseqnum)
		SELECT s.serialno,ser.SerialUniq,dbo.fn_GenerateUniqueNumber(),ser.invtisu_no,ser.ipkeyunique , ware.KaSeqnum  
		FROM @issueSerialData ser 
		INNER JOIN @warehouseLotIssuedData ware ON ser.invtisu_no=ware.invtisu_no
		INNER JOIN invtser s ON ser.SerialUniq=s.SERIALUNIQ

		-- 10/16/2017 Sachin B Implement Logic for the breaking SID and Create new SID for the SID Parts 
		--Update old ipkeys pkg balance for the SID Parts
		UPDATE ip SET ip.pkgBalance = ip.pkgBalance - issueip.QtyUsed
		FROM IPKEY ip JOIN @issueIpKeyData issueip ON issueip.IPKEYUNIQUE = ip.IPKEYUNIQUE

		--Create new SID after break
		INSERT INTO ipkey (IPKEYUNIQUE,UNIQ_KEY,UNIQMFGRHD,LOTCODE,REFERENCE,EXPDATE,PONUM,UNIQMFSP,RecordId,TRANSTYPE,originalPkgQty,pkgBalance,fk_userid,recordCreated,W_KEY,qtyAllocatedTotal,QtyAllocatedOver,originalIpkeyUnique)		 
		SELECT dbo.fn_GenerateUniqueNumber(),UNIQ_KEY,UNIQMFGRHD,LOTCODE,REFERENCE,EXPDATE,PONUM,UNIQMFSP,RecordId,TRANSTYPE,issueip.QtyUsed,issueip.QtyUsed,fk_userid,GETDATE(),W_KEY,0,0,ip.IPKEYUNIQUE 
		FROM IPKEY ip INNER JOIN @issueIpKeyData issueip ON issueip.IPKEYUNIQUE = ip.IPKEYUNIQUE

		--Temp table for IssueSerial
	    DECLARE @ipKeywithQty TABLE (IPKEYUNIQUE CHAR(10),Quantity NUMERIC(12,2))

		--Get SIDs with qty with we have to create new SID
		INSERT INTO @ipKeywithQty(IPKEYUNIQUE,Quantity)
		SELECT IPKEYUNIQUE,COUNT(SERIALNO) FROM @issueSerialData issueSer
		INNER JOIN @warehouseLotIssuedData w ON issueSer.invtisu_no=w.invtisu_no
		INNER JOIN INVENTOR i ON w.UNIQ_KEY = i.UNIQ_KEY
		WHERE i.useipkey =1 GROUP BY IPKEYUNIQUE 

		--Update old ipkeys pkg balance for the SID Parts
		UPDATE ip SET ip.pkgBalance = ip.pkgBalance - ipQty.Quantity
		FROM IPKEY ip JOIN @ipKeywithQty ipQty ON ipQty.IPKEYUNIQUE = ip.IPKEYUNIQUE

		--Create new SID after break
		INSERT INTO ipkey (IPKEYUNIQUE,UNIQ_KEY,UNIQMFGRHD,LOTCODE,REFERENCE,EXPDATE,PONUM,UNIQMFSP,RecordId,TRANSTYPE,originalPkgQty,pkgBalance,fk_userid,recordCreated,W_KEY,qtyAllocatedTotal,QtyAllocatedOver,originalIpkeyUnique)		 
		SELECT dbo.fn_GenerateUniqueNumber(),UNIQ_KEY,UNIQMFGRHD,LOTCODE,REFERENCE,EXPDATE,PONUM,UNIQMFSP,RecordId,TRANSTYPE,ipQty.Quantity,ipQty.Quantity,fk_userid,GETDATE(),W_KEY,0,0,ip.IPKEYUNIQUE
		FROM IPKEY ip JOIN @ipKeywithQty ipQty ON ipQty.IPKEYUNIQUE = ip.IPKEYUNIQUE
		
		---Delete the Issued componants from the SerialComponentToAssembly table
		IF(@deptId ='')
			BEGIN
				DELETE FROM SerialComponentToAssembly WHERE Wono = @woNo
			END	
		ELSE
			BEGIN
			    DELETE w
				FROM SerialComponentToAssembly w
				INNER JOIN @warehouseLotIssuedData t ON w.uniq_key = t.UNIQ_KEY
				WHERE w.Wono = @woNo
			END

END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
			SELECT @errorMessage = ERROR_MESSAGE(),
			@errorSeverity = ERROR_SEVERITY(),
			@errorState = ERROR_STATE();
			RAISERROR (@errorMessage, -- Message text.
               @errorSeverity, -- Severity.
               @errorState -- State.
               );

	END CATCH	
	IF @@TRANCOUNT>0
		COMMIT 
END