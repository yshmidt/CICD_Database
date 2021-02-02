-- =============================================
-- Author:		Sachin b
-- Create date: 07/13/2017
-- Description:	Get SFT Reserved Serial no for the parts which donot have ipkey
-- 07/28/2017 Sachin B Add Kaseqnum for the handle line item scenario
-- GetWarehouseReservedSerialNo '_26V0MTTWO','0000000545','_26V0MX3S4','HEH26632IC',1,'NDA0LI78YM',1,500,'','' 
--02/09/18 YS changed size of the lotcode column to 25 char  
-- 06/16/2020 Rajendra k : Added Kaseqnum in join to to avoid wrong serials
-- =============================================
CREATE PROCEDURE GetWarehouseReservedSerialNo 
@uniqKey char(10),
@wono char(10),
@W_Key char(10) ='',
@Uniq_lot char(10) ='',
@IsLotted bit,
@kaseqnum char(10) ='',
@StartRecord int,
@EndRecord int, 
@SortExpression char(1000) = null,
@Filter nvarchar(1000) = null

AS
DECLARE @SQL NVARCHAR(max)
BEGIN

Declare @SFTSerialList table(
IPKEYUNIQUE char(10),
SERIALUNIQ char(10),
SERIALNO char(30)
);

SET NoCount ON; 
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

if(@IsLotted = 0)
   BEGIN
        INSERT INTO @SFTSerialList
		SELECT distinct '' as IPKEYUNIQUE, iResSer.serialuniq,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO 
		FROM KAMAIN k 
		INNER JOIN Inventor i ON k.Uniq_Key = i.Uniq_Key
		-- 07/28/2017 Sachin B Add Kaseqnum for the handle line item scenario 
		INNER JOIN INVT_RES res ON res.KaSeqnum = k.KaSeqnum and res.KaSeqnum =@kaseqnum 
  INNER JOIN iReserveSerial iResSer ON iResSer.invtres_no = res.INVTRES_NO and iResSer.isDeallocate =0  -- 06/16/2020 Rajendra k : Added Kaseqnum in join to to avoid wrong serials
  INNER JOIN INVTSER ser ON ser.SERIALUNIQ = iResSer.serialuniq and ser.ISRESERVED = 1  AND ser.reservedno = @kaseqnum
		WHERE k.UNIQ_KEY=@uniqKey and k.wono=@wono and res.QTYALLOC > 0 and res.W_KEY = @W_Key 
   END
ELSE
    BEGIN
 --02/09/18 YS changed size of the lotcode column to 25 char  
     DECLARE @Lotcode nvarchar(25) = (select lotcode from INVTLOT where UNIQ_LOT = @Uniq_lot);  
		DECLARE @Reference char(12) = (select REFERENCE from INVTLOT where UNIQ_LOT = @Uniq_lot);
		DECLARE @ExpDate smalldatetime = (select EXPDATE from INVTLOT where UNIQ_LOT = @Uniq_lot);
		DECLARE @ponum char(15) = (select PONUM from INVTLOT where UNIQ_LOT = @Uniq_lot);

		INSERT INTO @SFTSerialList
		SELECT distinct '' as IPKEYUNIQUE, iResSer.serialuniq,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO 
		FROM KAMAIN k 
		JOIN Inventor i ON k.Uniq_Key = i.Uniq_Key
		-- 07/28/2017 Sachin B Add Kaseqnum for the handle line item scenario 
		JOIN INVT_RES res ON res.KaSeqnum = k.KaSeqnum and res.KaSeqnum =@kaseqnum
  LEFT OUTER JOIN iReserveSerial iResSer ON iResSer.invtres_no = res.INVTRES_NO and iResSer.isDeallocate =0  -- 06/16/2020 Rajendra k : Added Kaseqnum in join to to avoid wrong serials
  INNER JOIN INVTSER ser ON ser.SERIALUNIQ = iResSer.serialuniq and ser.ISRESERVED =1  AND ser.reservedno = @kaseqnum
		WHERE k.UNIQ_KEY=@uniqKey and k.wono=@wono and res.QTYALLOC > 0 and res.W_KEY = @W_Key
		AND res.LOTCODE =@Lotcode and res.REFERENCE =@Reference and res.EXPDATE = @ExpDate and res.PONUM =@ponum
	END

	SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @SFTSerialList 

  IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP ) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@StartRecord)+' AND '+Convert(varchar,@EndRecord)+''
   END
   exec sp_executesql @SQL
ENd