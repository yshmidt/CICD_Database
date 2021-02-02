-- =============================================
-- Author:		Rajendra K	
-- Create date: <02/13/2016>
-- Description:	Get Kit SID Serial Number
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[GetKitSidSerialNumber] 
@UniqKey CHAR(10),
@WoNo CHAR(10),
--02/09/18 YS changed size of the lotcode column to 25 char
@LotCode nvarchar(25),
@IPkey CHAR(10),
@StartRecord INT,
@EndRecord INT, 
@SortExpression CHAR(1000) = NULL,
@Filter NVARCHAR(1000) = NULL
AS
DECLARE @SQL nvarchar(max)
BEGIN
SET NOCOUNT ON; 
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

;WITH SFTSerialNumberList AS(
    --- 10/19/16 Sachin b Removing the Leading zeros from serial no
	SELECT ip.IPKEYUNIQUE
		   ,iResSer.serialuniq
		   ,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.')
		   ,LEN(ser.SERIALNO)) AS SERIALNO 
	FROM KAMAIN k 
	JOIN Inventor i ON k.Uniq_Key = i.Uniq_Key
	JOIN INVT_RES res ON res.KaSeqnum = k.KaSeqnum  
	LEFT OUTER JOIN iReserveIpKey ipReserve ON res.INVTRES_NO = ipReserve.invtres_no
	LEFT OUTER JOIN iReserveSerial iResSer ON iResSer.invtres_no = res.INVTRES_NO and iResSer.ipkeyunique = ipReserve.ipkeyunique and iResSer.isDeallocate =0
	LEFT OUTER JOIN INVTSER ser ON ser.SERIALUNIQ = iResSer.serialuniq
	LEFT OUTER JOIN ipkey ip ON ip.IPKEYUNIQUE = ipReserve.ipkeyunique
	WHERE k.UNIQ_KEY=@uniqKey and k.wono=@wono and ip.IPKEYUNIQUE =@ipkey and ser.LOTCODE = @LotCode AND
	res.QTYALLOC > 0
	)

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM SFTSerialNumberList 

  IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP ) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END
   EXEC SP_EXECUTESQL @SQL
ENd