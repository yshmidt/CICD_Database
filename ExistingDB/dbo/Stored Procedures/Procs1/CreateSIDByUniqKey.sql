
CREATE PROCEDURE [dbo].[CreateSIDByUniqKey] 
	@uniqKey AS CHAR (10),
	@fkUserId AS uniqueidentifier =null  
AS 
BEGIN

	SET NOCOUNT ON;
	DECLARE @partWithMfgrDetails TABLE (uniqKey char(10) ,uniqmfgrhd char(10),W_KEY char(10),QTY_OH numeric(12,2),QtyPerPackages numeric(12,2),ROW int,
	lotCode NVARCHAR(25) default '',poNum char(15)  default '',reference char(12)  default '',expDate smalldatetime);
	DECLARE @TotalRecords INT, @result  numeric(12,2), @QTYOH numeric(12,2), @QtyPerPkg numeric(12,2) ,
	@packegeQty numeric(12,2), @pkgBalance numeric(12,2),@ErrorMsg VARCHAR(MAX) ,	@Count INT = 1;

	Insert Into @partWithMfgrDetails(uniqKey,uniqmfgrhd,W_KEY,QTY_OH, QtyPerPackages,ROW,lotCode,reference,expDate,poNum)
	SELECT DISTINCT 
	 INVENTOR.UNIQ_KEY
	,INVTMFGR.UNIQMFGRHD
	,INVTMFGR.W_KEY
	,INVTMFGR.QTY_OH
	,COALESCE(mfg.qtyPerPkg,INVENTOR.ORDMULT,INVTMFGR.QTY_OH) AS QtyPerPackages 
	,ROW_NUMBER() OVER(ORDER BY INVTMFGR.W_KEY DESC) AS ROW  
	,ISNULL(INVTLOT.LOTCODE,'')
	,ISNULL(INVTLOT.REFERENCE,'')
	,INVTLOT.EXPDATE
	,ISNULL(INVTLOT.PONUM,'')
	FROM INVENTOR
	JOIN INVTMFGR ON INVENTOR.UNIQ_KEY = INVTMFGR.UNIQ_KEY AND INVENTOR.STATUS='active' AND INVTMFGR.IS_DELETED = 0  AND INVTMFGR.QTY_OH <> 0
	JOIN PARTTYPE ON INVENTOR.PART_CLASS = PARTTYPE.PART_CLASS AND INVENTOR.PART_TYPE  = PARTTYPE.PART_TYPE 
	INNER JOIN InvtMPNLink invtlk ON INVENTOR.UNIQ_KEY = invtlk.uniq_key AND INVTMFGR.UNIQMFGRHD = invtlk.uniqmfgrhd AND invtlk.Is_deleted = 0
	INNER JOIN Mfgrmaster mfg ON invtlk.mfgrmasterId =  mfg.MfgrMasterId AND mfg.is_deleted = 0
	LEFT JOIN INVTLOT ON INVTMFGR.W_KEY = INVTLOT.W_KEY
	WHERE INVENTOR.UNIQ_KEY = @uniqKey
 
	SET @TotalRecords = @@ROWCOUNT;

	BEGIN TRANSACTION		
		WHILE (@Count <= @totalRecords)
		BEGIN 
					SELECT @QTYOH = QTY_OH, @QtyPerPkg = QtyPerPackages from @partWithMfgrDetails where ROW = @Count
					BEGIN
							WHILE @QTYOH > 0
								BEGIN 
									set @result = @QTYOH % @QtyPerPkg;
									IF @result = 0
									  BEGIN
										set	@packegeQty = @QtyPerPkg;
									  END
									ELSE
									  BEGIN
										set	@packegeQty = @result;
									  END
							
									set @QTYOH = @QTYOH - @packegeQty;
								
									Insert Into IPKEY(IPKEYUNIQUE,UNIQ_KEY,fk_userid,LOTCODE,PONUM,originalPkgQty,pkgBalance,QtyAllocatedOver,qtyAllocatedTotal,
									recordCreated,RecordId,REFERENCE,TRANSTYPE,UNIQMFGRHD,W_KEY,EXPDATE)
									SELECT dbo.fn_GenerateUniqueNumber(),t.uniqKey, @fkUserId,t.lotCode,t.poNum,@packegeQty,@packegeQty,0,0,GETDATE(),'',t.reference,
									'O',t.uniqmfgrhd,t.W_KEY,t.expDate
									FROM @partWithMfgrDetails t WHERE t.ROW = @Count
								END 
					END 
					SELECT @Count = @Count + 1
	END
	 IF @@TRANCOUNT>0
		COMMIT TRANSACTION
END

