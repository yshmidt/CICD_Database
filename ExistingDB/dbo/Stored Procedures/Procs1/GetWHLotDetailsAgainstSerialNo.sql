-- =============================================
-- Author:Satish B
-- Create date: 02/10/2017
-- Description:	Get Serial Number Details When Scan Serial NUmber
-- MRE : Manual Reject Entry
-- GetWHLotDetailsAgainstSerialNo '000000000000000000000123456789'   
-- =============================================
CREATE PROCEDURE GetWHLotDetailsAgainstSerialNo
	@serialNo varchar(30)=''
AS
BEGIN
	 SET NOCOUNT ON;
	 SELECT porecdtl.PARTMFGR AS MFGR
	 ,invtmfgr.LOCATION 
		 ,porecdtl.MFGR_PT_NO AS MFGRPtNo
		 ,porecdtl.UNIQMFGRHD
		 ,invtlot.LOTCODE
		 ,invtlot.EXPDATE
		 ,invtlot.REFERENCE
		 ,invtlot.LOTQTY
		 ,invtlot.UNIQ_LOT
		 ,invtmfgr.W_KEY
		 ,warehous.WAREHOUSE + (CASE WHEN invtmfgr.LOCATION IS NULL OR invtmfgr.LOCATION = '' THEN '' ELSE '/' END)+ invtmfgr.LOCATION AS WhLocation  
		 ,warehous.UNIQWH
		
	FROM INVENTOR inventor
	INNER JOIN INVTMFGR invtmfgr ON invtmfgr.UNIQ_KEY =inventor.UNIQ_KEY 
	INNER JOIN WAREHOUS warehous ON invtmfgr.UNIQWH = warehous.UNIQWH			
	INNER JOIN INVTSER invtser on invtser.UNIQ_KEY = inventor.UNIQ_KEY and invtser.ID_VALUE =invtmfgr.W_KEY
	INNER JOIN PORECSER porecser ON porecser.FK_SERIALUNIQ=invtser.SERIALUNIQ
	INNER JOIN PORECLOC porecloc ON porecloc.LOC_UNIQ=porecser.LOC_UNIQ
	LEFT  JOIN PORECDTL porecdtl ON porecdtl.uniqrecdtl=porecloc.FK_UNIQRECDTL
	LEFT  OUTER JOIN IPKEY ip ON ip.W_KEY =invtmfgr.W_KEY AND invtmfgr.UNIQ_KEY = inventor.UNIQ_KEY AND ip.IPKEYUNIQUE =invtser.ipkeyunique
	LEFT  OUTER JOIN INVTLOT invtlot ON invtlot.W_KEY =invtmfgr.W_KEY AND invtlot.EXPDATE = invtser.EXPDATE AND invtlot.LOTCODE = invtser.LOTCODE AND invtlot.REFERENCE = invtser.REFERENCE
	WHERE 
		invtser.SERIALNO = @serialNo
		AND WAREHOUSE <> 'WIP' 
		AND WAREHOUSE <> 'WO-WIP'	
		AND Warehouse <> 'MRB'
END