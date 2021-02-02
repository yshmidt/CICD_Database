-- =============================================
-- Author:		Sachin B
-- Create date: 09/09/2016
-- Description:	this procedure will be called from the SF module and get all the Serial data which are associated with this warehouse/Lot and by IpKeyUnique
-- 10/19/16 Sachin b Removing the Leading zeros from serial no
-- 03/21/17 Sachin b Removed and Condition with ipkey and add inner query for the serialunique
-- [dbo].[GetWareHouseSerialDataWithIpKey] '_1ED0O2FS5','_1ED0O2FSC','','5BP7RZZVKD',0,1,3000,'',''
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================

CREATE PROCEDURE [dbo].[GetWareHouseSerialDataWithIpKey] 
	-- Add the parameters for the stored procedure here
	@Uniq_key char(10)=' ',
	@W_Key char(10) ='',
	@Uniq_lot char(10) ='',
	@ipkey char(10) ='',
	@IsLotted bit,
	@StartRecord INT,
	@EndRecord INT, 
	@SortExpression CHAR(1000) = null,
	@Filter NVARCHAR(1000) = null
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
IF OBJECT_ID('dbo.#TEMP', 'U') IS NOT NULL      
DROP TABLE dbo.#TEMP;

DECLARE @SQL nvarchar(max);
Declare @SFTSerialList table(
IPKEYUNIQUE char(10),
SERIALUNIQ char(10),
SERIALNO char(30)
);

if(@IsLotted = 0)
	BEGIN
	    INSERT INTO @SFTSerialList
		--- 10/19/16 Sachin b Removing the Leading zeros from serial no
		select distinct ser.IPKEYUNIQUE,ser.SERIALUNIQ,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO 
		from INVENTOR i
		Inner Join InvtMPNLink mpn on mpn.uniq_key = i.UNIQ_KEY
		Inner join MfgrMaster mfMaster  on mfMaster.MfgrMasterId = mpn.MfgrMasterId
		Inner join INVTMFGR imfgr on imfgr.UNIQ_KEY =i.UNIQ_KEY and mpn.uniqmfgrhd = imfgr.UNIQMFGRHD
		Inner join WAREHOUS w on imfgr.UNIQWH = w.UNIQWH
		Inner Join INVTSER ser on ser.ID_VALUE =imfgr.W_KEY and imfgr.UNIQ_KEY =i.UNIQ_KEY
		Inner Join IPKEY ip on ip.IPKEYUNIQUE = ser.ipkeyunique
		where 
		i.UNIQ_KEY = @Uniq_key
		AND WAREHOUSE <> 'WIP   ' 
		AND WAREHOUSE <> 'WO-WIP'	
		AND Warehouse <> 'MRB   '
		AND ser.ID_KEY = 'W_KEY' 
		AND ip.pkgBalance > 0
		AND imfgr.W_KEY = @W_Key
		AND imfgr.IS_DELETED = 0 
		AND imfgr.INSTORE = 0
		-- 03/21/17 Sachin b Removed and Condition with ipkey and add inner query for the serialunique
		AND ser.SERIALUNIQ not in (select SERIALUNIQ from iReserveSerial where isDeallocate =0 and IPKEYUNIQUE =@ipkey and serialuniq not in (select SERIALUNIQ from iReserveSerial where isDeallocate =1 and IPKEYUNIQUE =@ipkey ))
		--AND ip.IPKEYUNIQUE not in (select IPKEYUNIQUE from iReserveIpKey group by ipkeyunique,KaSeqnum having SUM(qtyAllocated) >0)
		AND ip.IPKEYUNIQUE =@ipkey
	END
ELSE
    BEGIN
	    --- 09/13/16 Sachin b Gettting IpKey if part is lotted
		--02/09/18 YS changed size of the lotcode column to 25 char
		DECLARE @Lotcode nvarchar(25) = (select lotcode from INVTLOT where UNIQ_LOT = @Uniq_lot);
		DECLARE @Reference char(12) = (select REFERENCE from INVTLOT where UNIQ_LOT = @Uniq_lot);
		DECLARE @ExpDate smalldatetime = (select EXPDATE from INVTLOT where UNIQ_LOT = @Uniq_lot);

		INSERT INTO @SFTSerialList
		--- 10/19/16 Sachin b Removing the Leading zeros from serial no
        SELECT DISTINCT ser.IPKEYUNIQUE,ser.SERIALUNIQ,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO 
		FROM INVENTOR i
		Inner Join InvtMPNLink mpn on mpn.uniq_key = i.UNIQ_KEY
		Inner join MfgrMaster mfMaster  on mfMaster.MfgrMasterId = mpn.MfgrMasterId
		Inner join INVTMFGR imfgr on imfgr.UNIQ_KEY =i.UNIQ_KEY and mpn.uniqmfgrhd = imfgr.UNIQMFGRHD
		Inner join WAREHOUS w on imfgr.UNIQWH = w.UNIQWH
		Inner Join INVTSER ser on ser.ID_VALUE =imfgr.W_KEY and imfgr.UNIQ_KEY =i.UNIQ_KEY
		Inner Join IPKEY ip on ip.IPKEYUNIQUE = ser.ipkeyunique
		WHERE 
		i.UNIQ_KEY = @Uniq_key
		AND WAREHOUSE <> 'WIP   ' 
		AND WAREHOUSE <> 'WO-WIP'	
		AND Warehouse <> 'MRB   '
		AND ser.ID_KEY = 'W_KEY'
		AND ip.pkgBalance > 0 
		AND imfgr.W_KEY = @W_Key
		AND imfgr.IS_DELETED = 0 
		AND imfgr.INSTORE = 0
		-- 03/21/17 Sachin b Removed and Condition with ipkey and add inner query for the serialunique
		AND ser.SERIALUNIQ not in (select SERIALUNIQ from iReserveSerial where isDeallocate =0 and IPKEYUNIQUE =@ipkey and serialuniq not in (select SERIALUNIQ from iReserveSerial where isDeallocate =1 and IPKEYUNIQUE =@ipkey ))
		--AND ip.IPKEYUNIQUE not in (select IPKEYUNIQUE from iReserveIpKey group by ipkeyunique,KaSeqnum having SUM(qtyAllocated) >0)
		AND ser.LOTCODE = @Lotcode
		AND ser.REFERENCE = @Reference
		AND ser.EXPDATE = @ExpDate
		AND ip.IPKEYUNIQUE =@ipkey
	END
SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from @SFTSerialList

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
END