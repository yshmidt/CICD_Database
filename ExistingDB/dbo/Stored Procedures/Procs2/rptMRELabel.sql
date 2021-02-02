-- =============================================
-- Author:Satish B
-- Create date: 03/01/2017
-- Description:	Used to print Manual Reject Entry Label
-- exec rptMRELabel 'KFC5V0YK2G','_1LR0NAL9R','0000000851'
-- Modified : 05/19/2017 Satish B : Remove the alise of PARTMFGR and MFGR_PT_NO
-- Modified : 05/19/2017 Satish B : Select Part_no field
-- Modified : 05/19/2017 Satish B : Add the alise As Rev for Revision
-- Modified : 05/19/2017 Satish B : Change @lcRcvnumber to @lcRcvNumber
-- Modified : 03/22/2018 Rajendra K : Added Transfer block to print Warehouse transer record
-- Modified : 03/27/2018 Rajendra K : Added alias 'IPKEYUNIQUE' to 'toIpkeyUnique' column in first select query  
-- Modified : 05/4/2018 Rajendra K : Added to SET NOCOUNT ON
-- =============================================
CREATE PROCEDURE rptMRELabel
	@lcSid char(10),
	@lcUniqKey char(10),
	@lcRcvNumber char(10),
	@lcTransNoList NVARCHAR(MAX)='',
	@lcIsTransfer BIT= 0
AS
BEGIN
    IF(@lcIsTransfer = 1)
	-- 03/22/2018 Rajendra K : Added to print Warehouse transer record
	BEGIN
	-- 05/4/2018 Rajendra K : Added to SET NOCOUNT ON
	 SET NOCOUNT ON
	 SELECT id AS InvtTransNo INTO #tempInvtTransTable from dbo.[fn_simpleVarcharlistToTable](@lcTransNoList,',') order by id  
		SELECT MM.PARTMFGR 
		      ,MM.MFGR_PT_NO 
		      ,I.MATLTYPE AS RoHS
		      ,I.ITAR
		      ,I.Part_no 
		      ,I.Descript
		      ,I.Revision AS Rev
			  ,ITP.toIpkeyunique AS IPKEYUNIQUE -- 03/27/2018 Rajendra K : Added alias 'IPKEYUNIQUE' 
		      ,ISNULL(ITP.toIpkeyunique,I.PART_NO) AS Sid_PartNo
			  ,ITR.QTYXFER AS Qty
		FROM INVTTRNS ITR
		      INNER JOIN #tempInvtTransTable TIT ON ITR.INVTXFER_N = TIT.InvtTransNo
			  INNER JOIN INVENTOR I ON ITR.Uniq_Key =  I.UNIQ_KEY
			  INNER JOIN INVTMFGR INVTMF ON ITR.UNIQ_KEY  = INVTMF.UNIQ_KEY AND ITR.TOWKEY = InvtMF.W_Key  								  
			  INNER JOIN InvtMpnLink IML ON INVTMF.UNIQMFGRHD = IML.uniqmfgrhd
			  INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId
			  LEFT JOIN iTransferipkey ITP ON ITR.INVTXFER_N = ITP.invtxfer_n
	END 
	ELSE
	BEGIN 
	if(@lcSid<>'')
	   BEGIN
	 	SET NOCOUNT ON
		SELECT  mfgrmaster.PARTMFGR 
		,mfgrmaster.MFGR_PT_NO 
		,inventor.MATLTYPE AS RoHS
		,inventor.ITAR
		,inventor.Descript
		,inventor.Revision AS Rev
		,inventor.Part_no 
		,ip.IPKEYUNIQUE
		,ip.IPKEYUNIQUE AS Sid_PartNo
		,0 AS Qty
	    FROM ipkey ip
		INNER JOIN INVENTOR inventor ON inventor.UNIQ_KEY=ip.UNIQ_KEY
		INNER JOIN InvtMPNLink invtlink ON invtlink.uniqmfgrhd=ip.UNIQMFGRHD
		INNER JOIN MfgrMaster mfgrmaster ON mfgrmaster.MfgrMasterId=invtlink.MfgrMasterId
		WHERE 
		ip.IPKEYUNIQUE=@lcSid
	  END
	ELSE
	  BEGIN
		SET NOCOUNT ON
		--05/19/2017 Satish B : Remove the alise of PARTMFGR and MFGR_PT_NO
		SELECT porecdtl.PARTMFGR 
		 ,porecdtl.MFGR_PT_NO 
		 ,inventor.MATLTYPE AS RoHS
		 ,inventor.ITAR
		 --05/19/2017 Satish B : Select Part_no field
		 ,inventor.Part_no 
		 ,inventor.Descript
		 --05/19/2017 Satish B : Add the alise as Rev for Revision
		 ,inventor.Revision AS Rev
		 ,inventor.PART_NO AS Sid_PartNo
		 FROM PORECDTL porecdtl
		 INNER JOIN receiverDetail recdetail ON porecdtl.receiverdetId=recdetail.receiverdetId AND recdetail.uniqlnno=porecdtl.uniqlnno
		 INNER JOIN INVENTOR inventor ON inventor.UNIQ_KEY=recdetail.Uniq_key
		 WHERE inventor.UNIQ_KEY= @lcUniqKey
		 --05/19/2017 Satish B : Change @lcRcvnumber to @lcRcvNumber
		 AND porecdtl.receiverno= @lcRcvNumber
	 END	
	END
END	
	
