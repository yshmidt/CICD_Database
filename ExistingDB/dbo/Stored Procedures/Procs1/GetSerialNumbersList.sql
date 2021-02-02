-- =============================================
-- Author:Satish B
-- Create date: 02/13/2018
-- Description:	Get serial number list against ipkeyuniq and wkey
-- exec GetSerialNumbersList '_2AY0TEPED','7DVC47D0UK','','IVIY4PTWHO',1,500,0
-- =============================================
CREATE PROCEDURE GetSerialNumbersList
	@uniqKey AS char(10)='',
	@wKey AS char(10)='', 
	@ipKeyUnique char(10)='',
	@uniqLot char(10)='',
	@startRecord int=0,
    @endRecord int=50,   
    @outTotalNumberOfRecord int OUTPUT
AS
DECLARE @SQL nvarchar(max)
BEGIN
	SET NOCOUNT ON;
	SELECT COUNT(ser.SerialNo) AS RowCnt -- Get total counts 
	INTO #tempSerialData
	FROM INVTSER ser      	  
		  LEFT OUTER JOIN IPKEY ip ON ip.UNIQ_KEY = ser.UNIQ_KEY AND ip.IPKEYUNIQUE=ser.IPKEYUNIQUE
		  LEFT OUTER JOIN INVTLOT l ON l.Uniq_Lot=ser.Uniq_Lot AND ser.ID_VALUE=l.W_KEY
	WHERE ser.ID_key = 'W_KEY' 
		  AND ser.id_value = @wKey 
		  AND ser.UNIQ_KEY = @uniqKey	 
		  AND ser.ISRESERVED = 0 
		  AND (@ipKeyUnique IS NULL OR @ipKeyUnique='' OR ser.IPKEYUNIQUE= @ipKeyUnique)
		  AND (@ipKeyUnique IS NULL OR @ipKeyUnique='' OR ip.IPKEYUNIQUE= @ipKeyUnique)
		  AND (@uniqLot IS NULL OR @uniqLot='' OR ser.Uniq_Lot= @uniqLot)
	SELECT 
		 ser.SerialUniq
		,substring(ser.SerialNo, patindex('%[^0]%',ser.SerialNo),30) as SerialNo  
		,ser.UNIQ_KEY AS UniqKey
		,ser.UniqMfgrHd
		,ser.UNIQ_LOT AS UniqLot
		,ser.ID_KEY AS IdKey
		,ser.ID_VALUE AS IdValue
		,ser.LotCode
		,ser.ExpDate
		,ser.Reference
		,ser.PONum
		,ser.IsReserved
		,ser.IpKeyUnique
		,ip.W_KEY AS WKey
	FROM INVTSER ser      	  
	  LEFT OUTER JOIN IPKEY ip ON ip.UNIQ_KEY = ser.UNIQ_KEY AND ip.IPKEYUNIQUE=ser.IPKEYUNIQUE
	  LEFT OUTER JOIN INVTLOT l ON l.Uniq_Lot=ser.Uniq_Lot AND ser.ID_VALUE=l.W_KEY
	WHERE ser.ID_key = 'W_KEY' 
	  AND ser.id_value = @wKey 
	  AND ser.UNIQ_KEY = @uniqKey	 
	  AND ser.ISRESERVED = 0 
	  AND (@ipKeyUnique IS NULL OR @ipKeyUnique='' OR ser.IPKEYUNIQUE= @ipKeyUnique)
	  AND (@ipKeyUnique IS NULL OR @ipKeyUnique='' OR ip.IPKEYUNIQUE= @ipKeyUnique)
	  AND (@uniqLot IS NULL OR @uniqLot='' OR ser.Uniq_Lot= @uniqLot)
	  ORDER BY ser.SerialNo  
	  OFFSET(@startRecord-1) ROWS
	  FETCH NEXT @EndRecord ROWS ONLY
   
   SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempSerialData) -- Set total count to Out parameter 
END
