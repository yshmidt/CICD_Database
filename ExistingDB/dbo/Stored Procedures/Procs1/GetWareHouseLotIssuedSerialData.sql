-- =============================================
-- Author:		Sachin B
-- Create date: 11/15/2016
-- Description:	this procedure will be called from the SF module and get all the serial data which are issued to work order
-- 07/31/2017 Sachin B add @kaseqnum parameter in join with invt_isu and optimize the code by Adding new temp table @SelectedSerialList
-- For the part which do not have lot,sid [GetWareHouseLotIssuedSerialData] '0000000557','_26L0THVA8','_26L0TICAQ','','','',null,0,0,'',1,3000,'',''
-- 08/09/2017 Sachin B Increase size for ponum 12 to 15 in SP 
--02/09/18 YS changed size of the lotcode column to 25 char 
-- =============================================

CREATE PROCEDURE [dbo].[GetWareHouseLotIssuedSerialData] 
	-- Add the parameters for the stored procedure here
	@wono char(10),
	@Uniq_key char(10)=' ',
	@W_Key char(10) ='',
	--02/09/18 YS changed size of the lotcode column to 25 char
	@Lotcode nvarchar(25) ='',
	@Reference char(12) ='',
	-- 08/09/2017 Sachin B Increase size for ponum 12 to 15 in SP  
	@Ponum char(15) ='',
	@ExpDate smalldatetime,
	@IsLotted bit,
	@kaseqnum CHAR(10),
	@IsSID bit,
	@IpKeyUniq char(10),
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

--Temp table for all data
Declare @SelectedSerialList table(
IpKeyUnique char(10),
SERIALUNIQ char(10),
SERIALNO char(30),
ExpDate smalldatetime null,
LotCode nvarchar(25),
Reference char(12),
PoNum char(15)
);

--put data in table
INSERT INTO @SelectedSerialList
SELECT DISTINCT ser.IPKEYUNIQUE,ser.SERIALUNIQ,SUBSTRING(ser.SERIALNO, PATINDEX('%[^0]%', ser.SERIALNO+'.'), LEN(ser.SERIALNO)) as SERIALNO,
ser.EXPDATE,ser.LOTCODE,ser.REFERENCE,ser.PONUM
FROM inventor i 
INNER JOIN invt_isu isu ON i.UNIQ_KEY = isu.UNIQ_KEY and isu.kaseqnum =@kaseqnum
INNER JOIN issueSerial isuSer ON isu.invtisu_no = isuSer.invtisu_no 
INNER JOIN INVTSER ser ON isuSer.SERIALUNIQ = ser.SERIALUNIQ
WHERE isu.ISSUEDTO like '%(WO:'+@wono+'%'
AND isu.wono =@wono 
AND isu.uniq_key = @Uniq_key
AND isu.W_KEY = @W_Key
AND ser.ID_KEY = 'WONO'
AND ser.ID_VALUE = @wono

--Temp Table for the return selected serial number
Declare @SFTSerialList table(
IPKEYUNIQUE char(10),
SERIALUNIQ char(10),
SERIALNO char(30)
);

If(@IsSID = 0)
	BEGIN
		IF(@IsLotted = 0)
			BEGIN
				INSERT INTO @SFTSerialList
				SELECT IpKeyUnique,SERIALUNIQ,SERIALNO FROM @SelectedSerialList	
			END
		ELSE
			BEGIN
				INSERT INTO @SFTSerialList
				SELECT IpKeyUnique,SERIALUNIQ,SERIALNO FROM @SelectedSerialList
				WHERE LOTCODE = @Lotcode AND REFERENCE = @Reference AND PONUM = @Ponum AND EXPDATE = @ExpDate
			END
	END
ELSE
	BEGIN
		IF(@IsLotted = 0)
			BEGIN
				INSERT INTO @SFTSerialList
				SELECT ser.IpKeyUnique,SERIALUNIQ,SERIALNO FROM @SelectedSerialList ser
				INNER JOIN IPKEY ip ON ser.ipkeyunique = ip.ipkeyunique
				WHERE ip.IPKEYUNIQUE = @IpKeyUniq		
			END
		ELSE
			BEGIN
				INSERT INTO @SFTSerialList
				SELECT ser.IpKeyUnique,SERIALUNIQ,SERIALNO FROM @SelectedSerialList ser
				INNER JOIN IPKEY ip ON ser.ipkeyunique = ip.ipkeyunique
				WHERE ip.IPKEYUNIQUE = @IpKeyUniq AND ser.LOTCODE = @Lotcode AND ser.REFERENCE = @Reference AND ser.PONUM = @Ponum AND ser.EXPDATE = @ExpDate
			END     
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