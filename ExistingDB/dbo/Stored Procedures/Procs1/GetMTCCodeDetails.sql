
-- =============================================
-- Author: Shivshankar P
-- Create date: 08/24/2020
-- Description:	Used To Get Part Number MTC codes Data against uniq_key 
-- EXEC GetMTCCodeDetails @lcuniq_key = '_1EI0NK1ZM'
-- Shivshankar P 09/04/2020 : Remove originalIpkeyUnique<>'' to get MTC code
-- Shivshankar P 09/14/2020 : Bring only those MTC having Pkgbalance - qtyallocatedtotal > 0
-- =============================================
CREATE PROCEDURE GetMTCCodeDetails
  @lcuniq_key AS char(10) = '',
  @startRecord INT = 1,      
  @endRecord INT = 150,       
  @sortExpression NVARCHAR(1000) = NULL,      
  @filter NVARCHAR(1000) = NULL
AS
BEGIN
SET NOCOUNT ON;  
 DECLARE @SQL nvarchar(MAX),@rowCount NVARCHAR(MAX);
 IF(@sortExpression = NULL OR @sortExpression = '')      
 BEGIN      
   SET @sortExpression = 'receiverno asc'      
 END 

    Declare @TABLEVAR table (ipkeyunique char(10) ,parentipkeyunique char(10),pkgbalance numeric (12,5))
	;with ipkeytree as 
	(
	   select ipkeyunique, originalIpkeyUnique,pkgBalance
	   from IPKEY
	   -- Shivshankar P 09/14/2020 : Bring only those MTC having Pkgbalance - qtyallocatedtotal > 0
	   where UNIQ_KEY = @lcuniq_key and pkgBalance - qtyAllocatedTotal > 0 -- Shivshankar P 09/04/2020 : Remove originalIpkeyUnique<>'' to get MTC code
	   union all
	   select topipkey.ipkeyunique, topipkey.originalIpkeyUnique,topipkey.pkgBalance
	   from IPKEY topipkey
	   join ipkeytree c on C.originalIpkeyUnique = topipkey.ipkeyunique  -- this is the recursion
	  ) 
	-- Here you can insert directly to table variable
	INSERT INTO @TABLEVAR
	select *
	from ipkeytree
	OPTION (MAXRECURSION 0)

	SELECT p.receiverno, p.porecpkno, poi.ponum, t.ipkeyunique, t.pkgbalance, t.parentipkeyunique, ipkey.TRANSTYPE, ipkey.RecordId
	INTO #TEMP
	FROM @TABLEVAR t 
	inner join ipkey on (t.parentipkeyunique='' and t.ipkeyunique=ipkey.IPKEYUNIQUE)
	or (t.parentipkeyunique<>'' and t.parentipkeyunique=IPKEY.IPKEYUNIQUE)
	inner join porecdtl p on ipkey.RecordId=p.uniqrecdtl
	inner join poitems poi on p.uniqlnno=poi.UNIQLNNO
	and t.pkgbalance>0

 SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TEMP',@filter,@sortExpression,'','receiverno',@startRecord,@endRecord))         
      EXEC sp_executesql @rowCount      

 SET @SQL =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TEMP',@filter,@sortExpression,N'receiverno','',@startRecord,@endRecord))    
   EXEC sp_executesql @SQL 
END