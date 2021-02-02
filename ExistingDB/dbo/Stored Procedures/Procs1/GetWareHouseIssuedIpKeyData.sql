-- =============================================
-- Author:		Sachin B
-- Create date: 11/15/2016
-- Description:	this procedure will be called from the SF module and get all the ipkey data which are issued to work order
-- For the part which do not have lot [GetWareHouseIssuedIpKeyData] '0000000598','_1LR0NALBG','_1LR0NB4D0','sds            ','2           ','000000000001687','10/21/2017 12:00:00 AM',1,'MDOHS752UV',1,'',1,3000,'',''  
-- For lotted Part [GetWareHouseIssuedIpKeyData] '0000000555','_25P0KUM80','_25P0KVBES','0000000526','101014447777','','2016-10-25 00:00:00',1,1,3000,'','' 
-- 12/05/2016 Sachin b Add If/Else block conditions for Get Assembly Allocated SID Data and add parameter @IsAssemblyAllocated and @AssemblySerialUniq
-- 07/31/2017 Sachin B add @kaseqnum parameter in join with invt_isu table and optimize code also
-- 10/10/2017 Sachin B get qtyAllocatedTotal insted of pkgbalance in select statement
-- 10/26/2017 Sachin B Change datatype of QtyUsed int to numeric(12,2) because it may have decimal value if they dont have U_OF_MES 'Each' and apply coding standard
-- 11/07/2017 Sachin B Increase Size of @Reference from CHAR(12) to CHAR(15)
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================


CREATE PROCEDURE [dbo].[GetWareHouseIssuedIpKeyData] 
	-- Add the parameters for the stored procedure here
	@wono CHAR(10),
	@Uniq_key CHAR(10)=' ',
	@W_Key CHAR(10) ='',
	--02/09/18 YS changed size of the lotcode column to 25 char
	@Lotcode nvarCHAR(25) ='',
	@Reference CHAR(12) ='',
	@Ponum CHAR(15) ='',
	@ExpDate SMALLDATETIME,
	@IsLotted BIT,
	@kaseqnum CHAR(10),
	-- 12/05/2016 Sachin b Add If/Else block conditions for Get Assembly Allocated SID Data and add parameter @IsAssemblyAllocated and @AssemblySerialUniq
	@IsAssemblyAllocated BIT,
	@AssemblySerialUniq CHAR(10), 
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

DECLARE @sql NVARCHAR(MAX);

--Temp table for All SID Data
-- 10/26/2017 Sachin B Change datatype of QtyUsed int to numeric(12,2) because it may have decimal value if they dont have U_OF_MES 'Each' and apply coding standard
--02/09/18 YS changed size of the lotcode column to 25 char
DECLARE @selectedSidComponantList TABLE(
IPKEYUNIQUE CHAR(10),QtyAllocated NUMERIC(12,2),Unit CHAR(10),RoHS BIT,QtyUsed NUMERIC(12,2),ReverseQty INT,ExpDate SMALLDATETIME NULL,LotCode nvarCHAR(25),Reference CHAR(12),PoNum CHAR(15)
);

-- 12/05/2016 Sachin b Add If/Else block conditions for Get Assembly Allocated SID Data and add parameter @IsAssemblyAllocated and @AssemblySerialUniq
IF(@IsAssemblyAllocated =0)
	BEGIN
		INSERT INTO @selectedSidComponantList
		SELECT DISTINCT isuIp.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS,SUM(isuIP.qtyissued) AS QtyUsed,0 AS ReverseQty,
		ip.EXPDATE,ip.LOTCODE,ip.REFERENCE,ip.PONUM
		FROM inventor i 
		INNER JOIN invt_isu isu ON i.UNIQ_KEY = isu.UNIQ_KEY AND isu.kaseqnum =@kaseqnum
		INNER JOIN issueipkey isuIP ON isu.invtisu_no = isuIP.invtisu_no 
		INNER JOIN ipkey ip ON isuIP.ipkeyunique = ip.IPKEYUNIQUE
		WHERE isu.ISSUEDTO LIKE '%(WO:'+@wono+'%'
		AND isu.wono =@wono AND isu.uniq_key = @Uniq_key
		AND ip.W_KEY = @W_Key
		GROUP BY isuIp.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS,ip.EXPDATE,ip.LOTCODE,ip.REFERENCE,ip.PONUM
		HAVING SUM(isuIP.qtyissued) >0
	END
ELSE
	BEGIN
	    INSERT INTO @selectedSidComponantList
	    SELECT DISTINCT isuIp.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS AS Unit,CAST(1 AS BIT) RoHS,ass.Qtyisu AS QtyUsed,0 as ReverseQty,
		ip.EXPDATE,ip.LOTCODE,ip.REFERENCE,ip.PONUM
		FROM inventor i
		INNER JOIN invt_isu isu  ON i.UNIQ_KEY = isu.UNIQ_KEY and isu.kaseqnum =@kaseqnum
		INNER JOIN issueipkey isuIP ON isu.invtisu_no = isuIP.invtisu_no 
		INNER JOIN ipkey ip ON isuIP.ipkeyunique = ip.IPKEYUNIQUE
		INNER JOIN SerialComponentToAssembly ass ON ip.IPKEYUNIQUE = ass.PartIpkeyUnique
		WHERE isu.ISSUEDTO LIKE '%(WO:'+@wono+'%'
		AND isu.wono =@wono AND isu.uniq_key = @Uniq_key
		AND ip.W_KEY = @W_Key AND ass.serialuniq = @AssemblySerialUniq
		GROUP BY isuIp.IPKEYUNIQUE,ip.pkgBalance,i.U_OF_MEAS,ass.Qtyisu,ip.EXPDATE,ip.LOTCODE,ip.REFERENCE,ip.PONUM
		HAVING ass.Qtyisu >0
	END

-- 10/25/16 Sachin B Add three parameter U_OF_MEAS and RoHS and QtyUsed
-- 10/26/2017 Sachin B Change datatype of QtyUsed int to numeric(12,2) because it may have decimal value if they dont have U_OF_MES 'Each' and apply coding standard
DECLARE @sftSidComponantList 
TABLE(IPKEYUNIQUE CHAR(10),QtyAllocated NUMERIC(12,2),Unit CHAR(10),RoHS BIT,QtyUsed NUMERIC(12,2),ReverseQty INT);

if(@IsLotted = 0)
	BEGIN	    
	    INSERT INTO @sftSidComponantList
		SELECT IPKEYUNIQUE,QtyAllocated,Unit,RoHS,QtyUsed,ReverseQty FROM @selectedSidComponantList
	END
ELSE
    BEGIN
		INSERT INTO @sftSidComponantList
		SELECT IPKEYUNIQUE,QtyAllocated,Unit,RoHS,QtyUsed,ReverseQty FROM @selectedSidComponantList 
		WHERE LOTCODE = @Lotcode AND REFERENCE = @Reference AND PONUM = @Ponum AND EXPDATE = @ExpDate
	END

SELECT IDENTITY(INT,1,1) AS RowNumber,*INTO #TEMP FROM @sFTSidComponantList

	IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @sql=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+' ORDER BY '+ @SortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @sql=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP ) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @sql=N'select  t.* ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
      RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END
   ELSE
     BEGIN
      SET @sql=N'select  t.*,(SELECT COUNT(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+CONVERT(VARCHAR,@StartRecord)+' AND '+CONVERT(VARCHAR,@EndRecord)+''
   END
   EXEC SP_EXECUTESQL @sql
END