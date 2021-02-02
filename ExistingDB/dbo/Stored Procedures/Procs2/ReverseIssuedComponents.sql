-- =============================================
-- Author:	Rajendra K
-- Create date: 07/19/2017
-- Description:	Used to Reverse issued components
-- ReverseIssuedComponents '0000000555','_0UB0PIZ4N'
 --03/01/18 YS lotcode size change to 25
-- =============================================

CREATE PROCEDURE [dbo].[ReverseIssuedComponents]  
  @WoNo char(10),
  @KaSeqNum char(10) = null,
  @UserId uniqueidentifier= null	
AS
BEGIN
SET NoCount ON;

-- get ready to handle any errors
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	--Temp table for warehous/lot
	 --03/01/18 YS lotcode size change to 25
	declare @WarehouseLotIssuedData table (invtisu_no char(10),UNIQ_KEY char(10),w_key char(10),ExpDate smalldatetime,REFERENCE char(12),LotCode char(25),PONUM char(15)
	,QtyUsed numeric(12,2),IsLotted bit,useipkey bit,serialyes bit,kaseqnum char(10))

	--Temp table for IssueIpKey
	declare @IssueIpKeyData table (invtisu_no char(10),IPKEYUNIQUE char(10),QtyUsed numeric(12,2))

	--Temp table for IssueSerial
	declare @IssueSerialData table (invtisu_no char(10),IPKEYUNIQUE char(10),SERIALUNIQ char(10),SERIALNO char(30))

	-- get g/l # for the wip account
	declare @wipGL char(13)
	select @wipGl=dbo.fn_GetWIPGl()
	
	BEGIN TRY
	BEGIN TRANSACTION 

;WITH IssuedComponantList AS (
			SELECT i.UNIQ_KEY AS UniqKey,p.LOTDETAIL AS IsLotted, i.useipkey, i.serialyes, k.act_qty AS QtyIssued,KaSeqnum
			FROM kamain k
			inner join WOENTRY w ON w.WONO =k.WONO
			inner join inventor i ON k.uniq_key=i.uniq_key
			inner join PARTTYPE p ON p.PART_TYPE = i.PART_TYPE and p.PART_CLASS = i.PART_CLASS
			WHERE  k.wono= @WoNo 
			AND (@KaSeqNum IS NULL OR @KaSeqNum='' OR k.KASEQNUM = @KaSeqNum) and k.act_qty > 0
			GROUP BY   i.useipkey, i.serialyes, i.UNIQ_KEY ,k.act_qty,p.LOTDETAIL,KaSeqnum
)

INSERT INTO @WarehouseLotIssuedData
SELECT  dbo.fn_GenerateUniqueNumber() AS invtisu_no,Isulist.UniqKey,isu.w_key,isu.ExpDate,isu.Reference,isu.LotCode,isu.PONUM,sum(Qtyisu) AS 'QtyUsed', 
			 IsLotted,Isulist.useipkey,Isulist.serialyes,Isulist.KaSeqnum 
			FROM invt_isu isu
			INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY
			INNER JOIN IssuedComponantList Isulist ON  i.UNIQ_KEY = Isulist.UniqKey
			INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY AND isu.UNIQMFGRHD = mpn.uniqmfgrhd
			INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
			INNER JOIN INVTMFGR mf ON isu.uniq_key = mf.uniq_key and isu.UNIQMFGRHD = mf.UNIQMFGRHD and mf.W_KEY =isu.W_KEY
			INNER JOIN WAREHOUS w ON mf.UNIQWH = w.UNIQWH			
			LEFT OUTER JOIN invtlot lot ON ISNULL(lot.W_KEY,'') =ISNULL(isu.w_key,'') AND  ISNULL(lot.lotcode,'') = ISNULL(isu.lotcode,'')  AND  ISNULL(lot.EXPDATE,1) = ISNULL(isu.EXPDATE,1) 
			AND  ISNULL(lot.REFERENCE,'') = ISNULL(isu.REFERENCE,'') 
			WHERE isu.ISSUEDTO like '%(WO:'+@WoNo+'%'
			AND isu.wono =@WoNo 
			GROUP BY Partmfgr,mfgr_pt_no,Warehouse,Location,isu.ExpDate,isu.Reference,isu.LotCode,isu.PONUM,isu.W_KEY,Isulist.UniqKey,IsLotted,Isulist.useipkey,Isulist.serialyes,Isulist.KaSeqnum 
			HAVING sum(Qtyisu) > 0


--Getting Issued IPkey Data for the WoNo 
INSERT INTO @IssueIpKeyData
SELECT DISTINCT ware.invtisu_no, isuIp.IPKEYUNIQUE,SUM(isuIP.qtyissued) AS QtyUsed
		FROM invt_isu isu 		
		INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY
		INNER JOIN issueipkey isuIP ON isu.invtisu_no = isuIP.invtisu_no 
		INNER JOIN ipkey ip ON isuIP.ipkeyunique = ip.IPKEYUNIQUE
		INNER JOIN @WarehouseLotIssuedData ware ON ip.UNIQ_KEY = ware.UNIQ_KEY 
		AND ip.W_KEY = ware.W_KEY and ISNULL(ip.ExpDate,1) = ISNULL(ware.ExpDate,1) and ip.Reference = ware.Reference and ip.LotCode = ware.LotCode and ip.PONUM = ware.PONUM
		WHERE isu.ISSUEDTO like '%(WO:'+@WoNo+'%'
		AND isu.wono =@WoNo AND ware.useipkey =1 AND ware.SERIALYES = 0
		--and 
		GROUP BY ware.invtisu_no,isuIp.IPKEYUNIQUE
		HAVING sum(isuIP.qtyissued) >0

--Getting Issued Serial Data for the WoNo
INSERT INTO @IssueSerialData
SELECT DISTINCT ware.invtisu_no,ser.IPKEYUNIQUE,ser.SERIALUNIQ,ser.SERIALNO 
				FROM invt_isu isu
				INNER JOIN inventor i ON i.UNIQ_KEY = isu.UNIQ_KEY
				INNER JOIN issueSerial isuSer ON isu.invtisu_no = isuSer.invtisu_no 
				INNER JOIN INVTSER ser ON isuSer.SERIALUNIQ = ser.SERIALUNIQ
				Inner Join @WarehouseLotIssuedData ware ON ser.UNIQ_KEY = ware.UNIQ_KEY 
		        AND ISNULL(ser.ExpDate,1) = ISNULL(ware.ExpDate,1) and ser.Reference = ware.Reference and ser.LotCode = ware.LotCode and ser.PONUM = ware.PONUM
				WHERE isu.ISSUEDTO like '%(WO:'+@WoNo+'%'
				AND isu.wono =@WoNo 
				AND ser.ID_KEY = 'WONO'
				AND ser.ID_VALUE = @WoNo

       --De-Kit componants and put negative entry of qtyisu on the Invt_ISU table
       INSERT INTO invt_isu (invtisu_no,w_key,UNIQ_KEY,issuedto,qtyisu,GL_NBR,wono,UNIQMFGRHD,fk_userid,kaseqnum,LOTCODE,EXPDATE,REFERENCE,PONUM)
	   SELECT t.invtisu_no,t.w_key,t.UNIQ_KEY,'(WO:'+@WoNo,-QtyUsed,@wipGl,@WoNo,m.UNIQMFGRHD,@UserId,KaSeqnum,t.LOTCODE,t.EXPDATE,t.REFERENCE,t.PONUM
	   FROM @WarehouseLotIssuedData t
	   INNER JOIN invtmfgr m ON t.W_key=m.W_KEY

	   -- De-Kit ipkey
		INSERT INTO issueipkey (invtisu_no,qtyissued,ipkeyunique,kaseqnum,issueIpKeyUnique)
			SELECT t.invtisu_no,-t.QtyUsed,t.ipKeyUnique,h.kaseqnum,dbo.fn_GenerateUniqueNumber() FROM @IssueIpKeyData t 
			INNER JOIN @WarehouseLotIssuedData h ON t.invtisu_no=h.invtisu_no
		
		-- De-Kit serial numbers
		INSERT INTO issueSerial (serialno,SerialUniq,iIssueSerUnique,invtisu_no,ipkeyunique,kaseqnum)
		SELECT s.serialno,t.SerialUniq,dbo.fn_GenerateUniqueNumber(),t.invtisu_no,t.ipkeyunique , h.KaSeqnum  
		FROM @IssueSerialData t 
		INNER JOIN @WarehouseLotIssuedData h ON t.invtisu_no=h.invtisu_no
		INNER JOIN invtser s ON t.SerialUniq=s.SERIALUNIQ
		
		---Delete the Issued componants from the SerialComponentToAssembly table
			    DELETE w
				FROM SerialComponentToAssembly w
				INNER JOIN @WarehouseLotIssuedData t ON w.uniq_key = t.UNIQ_KEY
				WHERE w.Wono = @WoNo

END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
			SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	END CATCH	
	IF @@TRANCOUNT>0
		COMMIT 
END