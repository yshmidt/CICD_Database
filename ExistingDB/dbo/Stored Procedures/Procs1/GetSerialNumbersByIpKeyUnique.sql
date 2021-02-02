-- =============================================
-- Author:Sachin s
-- Create date: 05/31/2016
-- Description:	Get SID detail based on unique key and ware house key if item is Used in SID and is Serialized and lotted
/* used for SID with serialized and lotted*/
--Sachin s 10-08-2016 Get All serial numbers 
--Sachin s 10-08-2016 Remove @startRecord and @endRecord 
--Sachin s 10-08-2016 -Get Empty date if ISNUll value 
--Satish B :11-04-2016 :Get serial number list without leading zeros
--Satish B :12-30-2016 :Avoid Space in EXPDATE when null
--Satish B :12-30-2016 :Get EXPDATE instaed of space when null
-- Sachin B :07-25-2019 :Added packlser join to fixed the issue of the serial numbers are displaying more than package balance of sid after transfer from sid in sfbl warehouse 
-- Sachin B :08-21-2019 :Added packlistno parameter for getting only shipped serial no's to sfbl warehouse of selected pl 
-- Nitesh B :02/11/2020 :Modify the @ipKeyUnique match based on warehouse selection
-- Sachin B :02/19/2020 Added PACKLISTNO condition to avoid unneccesary data when packlist no passed
-- Sachin B :02/25/2020 Modify LEFT OUTER JOIN INVTMFGR from join to fixed the issue of In normal packing list issued serial no not getting displayed 
-- GetSerialNumbersByIpKeyUnique 'OXBC7NB85K','WYYNMTBWV6', '7I69GC3F40','','' 
-- GetSerialNumbersByIpKeyUnique '55L0GKWH0V','1J9P94Y53M', '9D2ZJ0VPV3','','', '0000000877'
-- GetSerialNumbersByIpKeyUnique 'ZC04F7117O','5M3EZVIDTP', 'XQTCO9PC21','','', '0000000883'  
-- =============================================
CREATE PROCEDURE GetSerialNumbersByIpKeyUnique
	@uniqKey AS char(10)='',--'_01F15SZ9N'
	@wKey AS char(10)='', --'_1ED0O2FSC'
	@ipKeyUnique char(10)='', --0GKT4ILP27
    @sortExpression nvarchar(1000) = null,
    @filter nvarchar(1000) = NULL,
	-- Sachin B :08-21-2019 :Added packlistno parameter for getting only shipped serial no's to sfbl warehouse of selected pl 
	@packlistno char(10) =''
    --Sachin s 10-08-2016 Remove @startRecord and @endRecord 
AS
DECLARE @SQL nvarchar(max)
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	;WITH packingList as(
	SELECT DISTINCT	    	 
		 invtser.SerialUniq
		,substring(invtser.SerialNo, patindex('%[^0]%',invtser.SerialNo),30) as SerialNo  --Satish B :11-04-2016 :Get serial number list without leading zeros
		,invtser.UNIQ_KEY
		,invtser.UNIQMFGRHD
		,invtser.UNIQ_LOT
		,invtser.ID_KEY
		,invtser.ID_VALUE
		,invtser.SAVEDTTM
		,invtser.SAVEINIT
		,invtser.LOTCODE
		--,invtser.EXPDATE
		--Sachin s 10-08-2016 -Get Empty date if ISNUll value 
		--,ISNULL(invtser.EXPDATE, Space(20)) AS EXPDATE	  --Satish B :12-30-2016 :Avoid Space in EXPDATE when null
		--Satish B :12-30-2016 :Get EXPDATE instaed of space when null
		,invtser.EXPDATE
		,invtser.REFERENCE
		,invtser.PONUM
		,invtser.ISRESERVED
		,invtser.ACTVKEY
		,invtser.OLDWONO
		,invtser.WONO
		,invtser.RESERVEDFLAG
		,invtser.RESERVEDNO
		,invtser.IpKeyUnique
		,ipkey.W_KEY
	  from invtser invtser      	  
	  LEFT OUTER JOIN IPKEY ipkey ON ipkey.UNIQ_KEY = invtser.UNIQ_KEY 
   -- Sachin B :07-25-2019 :Added packlser join to fixed the issue of the serial numbers are displaying more than package balance of sid after transfer from sid in sfbl warehouse 
	 LEFT OUTER JOIN packlser on packlser.SERIALUNIQ= INVTSER.SERIALUNIQ AND PACKLISTNO = @packlistno
   -- Sachin B :02/25/2020 Modify LEFT OUTER JOIN INVTMFGR from join to fixed the issue of In normal packing list issued serial no not getting displayed 
	 LEFT OUTER JOIN INVTMFGR on invtser.ID_VALUE = INVTMFGR.W_KEY
	  WHERE 
	  --invtser.ID_key = 'w_key' 
	  --AND invtser.id_value = @wKey AND
	  invtser.SERIALUNIQ= CASE WHEN  INVTMFGR.SFBL= 1 THEN  PACKLSER.SERIALUNIQ ELSE invtser.SERIALUNIQ END AND
	  invtser.UNIQ_KEY = @uniqKey	 
	  AND invtser.ISRESERVED = 0 
-- Nitesh B :02/11/2020 :Modify the @ipKeyUnique match based on warehouse selection
	 -- AND ( @ipKeyUnique is null OR @ipKeyUnique = CASE WHEN INVTMFGR.SFBL= 1 THEN PACKLSER.IPKEYUNIQUE ELSE invtser.IPKEYUNIQUE   END)
	 -- Sachin B :02/19/2020 Added PACKLISTNO condition to avoid unneccesary data when packlist no passed
	 AND ( @ipKeyUnique is null OR (invtser.IPKEYUNIQUE= @ipKeyUnique )--AND PACKLISTNO = CASE WHEN  INVTMFGR.SFBL= 1 THEN  @packlistno ELSE PACKLISTNO END 
	     ) 
	 AND ( @ipKeyUnique is null OR IPKEY.IPKEYUNIQUE= @ipKeyUnique)
	  ) 
	  SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from packingList 
IF @filter <> '' AND @sortExpression <> ''
  BEGIN
  --Sachin s 10-08-2016 Get All serial numbers 
   SET @SQL=N'select * ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP '
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select *,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP '
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select * ,(SELECT COUNT(RowNumber) FROM #TEMP WHERE '+@filter+') AS TotalCount from #TEMP'
   END
   ELSE
     BEGIN
      SET @SQL=N'select *,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  '
   END
   exec sp_executesql @SQL 


END