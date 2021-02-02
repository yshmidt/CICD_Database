-- =============================================
-- Author:		Satish B
-- Create date: 12/30/2016
-- Description:	This stored procedure get part details against scanned serial number
-- [dbo].[GetPlPartDetailsBySerialNumber] '000000000000000000000845120513'
-- for Reserve Serial no [dbo].[GetPlPartDetailsBySerialNumber] '000000000000000000000000000027'
-- =============================================
CREATE PROCEDURE [dbo].[GetPlPartDetailsBySerialNumber] 
	-- Add the parameters for the stored procedure here
	@SerialNo char(30) =''
AS
BEGIN

Declare @ReserveCount int
set @ReserveCount = (select count(*) from iReserveSerial where serialuniq in (select serialuniq from INVTSER where SERIALNO = @SerialNo))
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

if(@ReserveCount = 0)
	BEGIN
		SELECT DISTINCT i.UNIQ_KEY,imfgr.W_KEY,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,lot.LOTCODE,lot.EXPDATE,lot.REFERENCE,ip.IPKEYUNIQUE,ser.SERIALUNIQ,ser.SERIALNO
		FROM INVENTOR i
		INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY
		INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
		INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY and mpn.uniqmfgrhd = imfgr.UNIQMFGRHD
		INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH			
		INNER JOIN INVTSER ser on ser.UNIQ_KEY = i.UNIQ_KEY and ser.ID_VALUE =imfgr.W_KEY
		LEFT OUTER JOIN IPKEY ip ON ip.W_KEY =imfgr.W_KEY and imfgr.UNIQ_KEY = i.UNIQ_KEY and ip.IPKEYUNIQUE =ser.ipkeyunique
		LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY and lot.EXPDATE = ser.EXPDATE and lot.LOTCODE = ser.LOTCODE and lot.REFERENCE = ser.REFERENCE
		WHERE 
		ser.SERIALNO = @SerialNo
		AND WAREHOUSE <> 'WIP   ' 
		AND WAREHOUSE <> 'WO-WIP'	
		AND Warehouse <> 'MRB   '
		AND imfgr.IS_DELETED = 0 
		AND Netable = 1
		AND imfgr.INSTORE = 0
	END
ELSE
	BEGIN
		SELECT DISTINCT i.UNIQ_KEY,imfgr.W_KEY,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,lot.LOTCODE,lot.EXPDATE,lot.REFERENCE,ip.IPKEYUNIQUE,ser.SERIALUNIQ,ser.SERIALNO
		FROM INVENTOR i
		INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY
		INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId
		INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY and mpn.uniqmfgrhd = imfgr.UNIQMFGRHD
		INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH			
		INNER JOIN INVTSER ser on ser.UNIQ_KEY = i.UNIQ_KEY and ser.ID_VALUE =imfgr.W_KEY
		LEFT OUTER JOIN IPKEY ip ON ip.W_KEY =imfgr.W_KEY and imfgr.UNIQ_KEY = i.UNIQ_KEY and ip.IPKEYUNIQUE =ser.ipkeyunique
		LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY and lot.EXPDATE = ser.EXPDATE and lot.LOTCODE = ser.LOTCODE and lot.REFERENCE = ser.REFERENCE
		WHERE 
		ser.SERIALNO = @SerialNo
		AND WAREHOUSE <> 'WIP   ' 
		AND WAREHOUSE <> 'WO-WIP'	
		AND Warehouse <> 'MRB   '
		AND imfgr.IS_DELETED = 0 
		AND Netable = 1
		AND imfgr.INSTORE = 0
		AND ip.pkgBalance > 0
	END
END