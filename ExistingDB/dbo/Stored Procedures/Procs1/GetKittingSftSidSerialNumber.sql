-- =============================================
-- Author:		Anuj
-- Create date: 03/02/2016
-- Description:	Show Serial number and IpKey information related to a component in SFT
-- 10/19/16 Sachin b Removing the Leading zeros from serial no
-- 03/10/2017 Sachin b Change left join to Inner join
-- 06/13/2017 Sachin b Add Distinct in the select query and add ser.ISRESERVED =1
-- 07/13/2017 Sachin b Add parameter @W_Key,@Uniq_lot,@IsLotted and Seprate logic for get reserved serial for the lotted and without lotted parts 
-- 07/28/2017 Sachin B Add Kaseqnum for the handle line item scenario 
-- GetKittingSftSidSerialNumber '_2FG0N2SI3','0000000427' ,'O46SG0WANH',1,50,'',''
-- GetKittingSftSidSerialNumber '_3IE0WL6K1','0985201010' ,'U0DSEYNPZF',1,50,'',''
--02/09/18 YS changed size of the lotcode column to 25 char  
-- 06/17/2020 Rajendra k : Added Kaseqnum in join to avoid wrong serials
-- =============================================
CREATE PROCEDURE GetKittingSftSidSerialNumber 
@uniqKey char(10),
@wono char(10),
@ipkey char(10),
-- 07/13/2017 Sachin b Add parameter @W_Key,@Uniq_lot,@IsLotted and Seprate logic for get reserved serial for the lotted and without lotted parts 
@W_Key char(10) ='',
@Uniq_lot char(10) ='',
@IsLotted bit,
@kaseqnum char(10) ='',
@StartRecord int,
@EndRecord int, 
@SortExpression char(1000) = null,
@Filter nvarchar(1000) = null
AS
DECLARE @SQL nvarchar(max)
BEGIN

Declare @SFTSerialList table(
IPKEYUNIQUE char(10),
SERIALUNIQ char(10),
SERIALNO char(30)
);

SET NoCount ON; 
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

-- 07/13/2017 Sachin b Add parameter @W_Key,@Uniq_lot,@IsLotted and Seprate logic for get reserved serial for the lotted and without lotted parts 
if(@IsLotted = 0)
   BEGIN
        INSERT INTO @SFTSerialList
		--- 10/19/16 Sachin b Removing the Leading zeros from serial no
		-- 06/13/2017 Sachin b Add Distinct in the select query and add ser.ISRESERVED =1
		SELECT distinct ip.IPKEYUNIQUE, iResSer.serialuniq,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO 
		FROM KAMAIN k 
		JOIN Inventor i ON k.Uniq_Key = i.Uniq_Key
		-- 07/28/2017 Sachin B Add Kaseqnum for the handle line item scenario 
		JOIN INVT_RES res ON res.KaSeqnum = k.KaSeqnum and res.KaSeqnum =@kaseqnum  
		LEFT OUTER JOIN iReserveIpKey ipReserve ON res.INVTRES_NO = ipReserve.invtres_no
		LEFT OUTER JOIN iReserveSerial iResSer ON iResSer.invtres_no = res.INVTRES_NO and iResSer.ipkeyunique = ipReserve.ipkeyunique and iResSer.isDeallocate =0
		-- 03/10/2017 Sachin b Change left join to Inner join
  -- 06/17/2020 Rajendra k : Added Kaseqnum in join to avoid wrong serials
  INNER JOIN INVTSER ser ON ser.SERIALUNIQ = iResSer.serialuniq and ser.ISRESERVED =1  AND ser.reservedno = @kaseqnum
		LEFT OUTER JOIN ipkey ip ON ip.IPKEYUNIQUE = ipReserve.ipkeyunique
		WHERE k.UNIQ_KEY=@uniqKey and k.wono=@wono and ip.IPKEYUNIQUE =@ipkey and res.QTYALLOC > 0 and res.W_KEY = @W_Key
   END
ELSE
    BEGIN
 --02/09/18 YS changed size of the lotcode column to 25 char  
     DECLARE @Lotcode nvarchar(25) = (select lotcode from INVTLOT where UNIQ_LOT = @Uniq_lot);  
		DECLARE @Reference char(12) = (select REFERENCE from INVTLOT where UNIQ_LOT = @Uniq_lot);
		DECLARE @ExpDate smalldatetime = (select EXPDATE from INVTLOT where UNIQ_LOT = @Uniq_lot);
		DECLARE @ponum char(15) = (select PONUM from INVTLOT where UNIQ_LOT = @Uniq_lot);

		INSERT INTO @SFTSerialList
		SELECT distinct ip.IPKEYUNIQUE, iResSer.serialuniq,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO 
		FROM KAMAIN k 
		JOIN Inventor i ON k.Uniq_Key = i.Uniq_Key
		-- 07/28/2017 Sachin B Add Kaseqnum for the handle line item scenario 
		JOIN INVT_RES res ON res.KaSeqnum = k.KaSeqnum and res.KaSeqnum =@kaseqnum 
		LEFT OUTER JOIN iReserveIpKey ipReserve ON res.INVTRES_NO = ipReserve.invtres_no
		LEFT OUTER JOIN iReserveSerial iResSer ON iResSer.invtres_no = res.INVTRES_NO and iResSer.ipkeyunique = ipReserve.ipkeyunique and iResSer.isDeallocate =0
  -- 06/17/2020 Rajendra k : Added Kaseqnum in join to avoid wrong serials
  INNER JOIN INVTSER ser ON ser.SERIALUNIQ = iResSer.serialuniq and ser.ISRESERVED =1  AND ser.reservedno = @kaseqnum
		LEFT OUTER JOIN ipkey ip ON ip.IPKEYUNIQUE = ipReserve.ipkeyunique
		WHERE k.UNIQ_KEY=@uniqKey and k.wono=@wono and ip.IPKEYUNIQUE =@ipkey and res.QTYALLOC > 0 and res.W_KEY = @W_Key
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