-- Create date: 01/31/2017
-- Description:	Get Serial Number List Against Selected Part Number And Receiver Number For Non SID Part
-- MRE : Manual Reject Entry
-- Modified : 10/11/2017 Satish B : Avoid selection of reserved serial number
--          : 02/16/2018 Satish B : Added the filter of @wkey
--			: 02/16/2018 Satish B : Removed filter of iTransferSerial table
-- GetSerialNumberListForMRE '_25P0KXKVI','0000001065','KQII5D3YZA','YA7Q3QSLAU'  
-- =============================================
CREATE PROCEDURE GetSerialNumberListForMRE
  @uniqKey char(10)='',
  @rcvNumber char(10)='',
  @uniqLot char(10)='',
  @wKey char(10)=''
 AS
 DECLARE @expDt smalldatetime ,@reference char(12),@lotcode char(12)
 BEGIN
	SET NOCOUNT ON
	IF @uniqLot<>'' 
		BEGIN
			SELECT @expDt =EXPDATE,@reference=REFERENCE,@lotcode=LOTCODE FROM INVTLOT where UNIQ_LOT=@uniqLot
			SELECT * FROM INVTSER invtser
			--02/16/2018 Satish B : Added the filter of @wkey
			JOIN PORECSER porecser ON porecser.FK_SERIALUNIQ=invtser.SERIALUNIQ AND ID_VALUE=@wkey
			JOIN PORECLOC porecloc ON porecloc.LOC_UNIQ=porecser.LOC_UNIQ
			LEFT JOIN PORECDTL porecdtl ON porecdtl.uniqrecdtl=porecloc.FK_UNIQRECDTL
			LEFT JOIN PORECLOT poreclot ON poreclot.LOC_UNIQ=porecloc.LOC_UNIQ  
			INNER JOIN INVTMFGR invtmfgr ON invtmfgr.UNIQMFGRHD=porecdtl.uniqmfgrhd AND invtmfgr.LOCATION=porecloc.LOCATION AND invtmfgr.UNIQWH=porecloc.UNIQWH --and invtmfgr.INSTORE = 0
			WHERE invtser.UNIQ_KEY=@uniqKey 
			AND porecser.RECEIVERNO=@rcvNumber 
			AND poreclot.LOTCODE=@lotcode
			AND poreclot.REFERENCE=@reference
			AND poreclot.EXPDATE=@expDt
			AND invtser.UNIQ_LOT=@uniqLot
			AND invtmfgr.W_KEY=@wKey
			--02/16/2018 Satish B : Removed filter of iTransferSerial table
			--AND invtser.SERIALUNIQ NOT IN(SELECT serialuniq FROM iTransferSerial ) 
			--10/11/2017 Satish B : Avoid selection of reserved serial number
			AND invtser.ISRESERVED=0
		END
	ELSE
		BEGIN
			SELECT * FROM INVTSER invtser
			--02/16/2018 Satish B : Added the filter of @wkey
			JOIN PORECSER porecser ON porecser.FK_SERIALUNIQ=invtser.SERIALUNIQ AND ID_VALUE=@wkey
			JOIN PORECLOC porecloc ON porecloc.LOC_UNIQ=porecser.LOC_UNIQ
			LEFT JOIN PORECDTL porecdtl ON porecdtl.uniqrecdtl=porecloc.FK_UNIQRECDTL
			INNER JOIN INVTMFGR invtmfgr ON invtmfgr.UNIQMFGRHD=porecdtl.uniqmfgrhd AND invtmfgr.LOCATION=porecloc.LOCATION AND invtmfgr.UNIQWH=porecloc.UNIQWH --and invtmfgr.INSTORE = 0
			WHERE invtser.UNIQ_KEY=@uniqKey 
			AND porecser.RECEIVERNO=@rcvNumber  
			AND invtmfgr.W_KEY=@wKey
			--02/16/2018 Satish B : Removed filter of iTransferSerial table
			--AND invtser.SERIALUNIQ NOT IN(SELECT serialuniq FROM iTransferSerial ) 
			--10/11/2017 Satish B : Avoid selection of reserved serial number
			AND invtser.ISRESERVED=0
		END
 END



