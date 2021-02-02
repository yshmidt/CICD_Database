-- =============================================
-- Author:Sachin Shevale
-- Create date: 10/09/2014
-- Description:	 Get warehouse details based on inventor uniqKey 
-- Modified: 10/09/14 replace invtmfhd table with 2 new tables
-- Modified: 05/06/16 Sachin S--modified the sp for paging and sorting
-- Modified: 05/06/16 Get warehouse details based on inventor uniqKey 
-- Modified: 05/06/16  Sachin s- 05/17/2016 Added a mode if edit then display ALLOCQTY as 0
-- Modified: 08/10/16  Sachin s- Handle null values
-- Modified: 08/10/16  Sachin s- AvailableQty should be grater than 0
-- Modified: 03/21/18  VL -	remove the Netable = 1 restriction.  We didn't have this restriction in VFP, so remove this restriction in SQL, so user can ship from this location.  In Kit, we have code in different place (sp_GetNotInstoreLocation4Mfgrhd) that will use Kitdef.lKitAllowNonNettable
--[dbo].[InvtAvailableFGILocationwithInStoreView] '_1LR0NAL9Q',1,50,'','' 
-- =============================================
CREATE PROCEDURE [dbo].[InvtAvailableFGILocationwithInStoreView] 
	-- Add the parameters for the stored procedure here
	-- Add the parameters for the stored procedure here
 @uniqKey char(10)='' ,
 @startRecord int=0,
 @endRecord int=50,   
 @sortExpression nvarchar(1000) = null, --'WHLOC ASC'
 @filter nvarchar(1000) = null --'Order by WHLOC ' 
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH AvailableFgiList
AS
-- 10/09/14 replace invtmfhd table with 2 new tables
(
SELECT DISTINCT 
    MfgrMaster.Partmfgr,
	MfgrMaster.mfgr_pt_no ,
  --(warehous.Warehouse  invtmfgr.Location) AS WHLoc,

  -- Modified: 08/10/16  Sachin s- Handle null values
  CONCAT(warehous.Warehouse, '/', invtmfgr.Location) WHLoc,  
  ISNULL(invtlot.lotcode, SPACE(10)) AS lotcode,	
  ISNULL(invtlot.EXPDATE, null) AS EXPDATE,		
  ISNULL(invtlot.Reference, SPACE(20)) AS Reference,  
  ISNULL(invtlot.LOTRESQTY, 0) AS LOTRESQTY, 
  parttype.LOTDETAIL,     
  CASE 
  WHEN parttype.LOTDETAIL = 1
  THEN 
  -- Modified: 08/10/16  Sachin s- Handle null values
  ISNULL ((invtlot.LOTQTY - invtlot.LOTRESQTY),0)  
  ELSE
  -- Modified: 08/10/16  Sachin s- Handle null values
    ISNULL( (Invtmfgr.QTY_OH - Invtmfgr.RESERVED),0)	
	END	  
	AS  AvailableQty, 

CASE 
  WHEN parttype.LOTDETAIL = 1
  THEN 
  -- Modified: 08/10/16  Sachin s- Handle null values
  ISNULL( (invtlot.LOTQTY-invtlot.LOTRESQTY) ,0) 
  ELSE
  -- Modified: 08/10/16  Sachin s- Handle null values
    ISNULL ((Invtmfgr.QTY_OH - Invtmfgr.RESERVED),0)	
	END	  
	AS  BaseAvailableQty,   
		0 AS ALLOCQTY,
		0 AS BaseAllocQty,
	 Invtmfgr.W_KEY,
	 invtMpnlink.Uniq_key,
	 -- Modified: 08/10/16  Sachin s- Handle null values
	 ISNULL(invtlot.UNIQ_LOT, SPACE(10)) AS UNIQ_LOT,	
	 Invtmfgr.UniqMfgrhd
	 ,inventor.SERIALYES AS SerialYes  	
	
	FROM Invtmfgr Invtmfgr  	
	INNER JOIN  Warehous Warehous ON Warehous.UNIQWH=Invtmfgr.UNIQWH
	INNER JOIN invtMpnlink invtMpnlink ON Invtmfgr.UNIQMFGRHD =invtMpnlink.uniqmfgrhd
	INNER JOIN inventor inventor ON inventor.UNIQ_KEY=Invtmfgr.UNIQ_KEY
	INNER JOIN MfgrMaster mfgrMaster ON mfgrMaster.MfgrMasterId=invtMpnlink.MfgrMasterId
	LEFT Outer  JOIN invtlot invtlot ON invtlot.W_KEY =Invtmfgr.W_KEY	
	LEFT OUTER  JOIN parttype parttype ON parttype.PART_TYPE=inventor.PART_TYPE	  	
	WHERE 	
	( invtMpnlink.Uniq_key is null or invtMpnlink.Uniq_key =@uniqKey)		
	AND Warehouse <> 'WIP'
	AND Warehouse <> 'WO-WIP'
	AND Warehouse <> 'MRB'
	-- 03/21/18 VL removed the restriction
	--AND Netable = 1
	AND Invtmfgr.Is_Deleted = 0
	AND invtMpnlink.Is_deleted = 0 
	and mfgrMaster.is_deleted=0
	AND Invtmfgr.COUNTFLAG = ''		
	AND  (Invtmfgr.QTY_OH - Invtmfgr.RESERVED) > 0
	),
	-- Modified: 08/10/16  Sachin s- AvailableQty should be grater than 0
	temptable as(SELECT *  from	AvailableFgiList WHERE AvailableQty > 0)
SELECT identity(int,1,1) as RowNumber,*INTO #TEMP from temptable 
IF @filter <> '' AND @sortExpression <> ''
  BEGIN
   SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE '+@filter+' and
   RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+' ORDER BY '+ @sortExpression+''
   END
  ELSE IF @filter = '' AND @sortExpression <> ''
  BEGIN
    SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
    RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+' ORDER BY '+ @sortExpression+''
	END
  ELSE IF @filter <> '' AND @sortExpression = ''
  BEGIN
      SET @SQL=N'select  t.* ,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE  '+@filter+' and
     RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+''
   END
   ELSE
     BEGIN
      SET @SQL=N'select  t.*,(SELECT MAX(RowNumber) FROM #TEMP) AS TotalCount from #TEMP  t  WHERE 
   RowNumber BETWEEN '+Convert(varchar,@startRecord)+' AND '+Convert(varchar,@endRecord)+''
   END
   exec sp_executesql @SQL
   END