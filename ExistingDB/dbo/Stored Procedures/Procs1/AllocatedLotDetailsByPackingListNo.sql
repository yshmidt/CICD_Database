-- Author:Sachin Shevale
-- Create date: 10/09/2014
-- Description:	 Get lot details for packing list which lot qty is 0
-- Modified : Satish B : 12-30-16 If part is lotted then get the loted part allocated qty else get allocated qty from pkAlloc
--	: Satish B- 04-07-2018 : Added the parameter @uniqueLnNo 
--	: Satish B : 04-07-18 Added the filter of @uniqueLnNo
--	: Satish B : 04/13/2018 : Remove the empty space from lotcode
--	: Satish B : 04/13/2018 : Select UNIQUELN from PlAlloc table
--	: Shrikant B : 01/23/2019 : Added Column WHNO, Invtmfgr.SFBL for consign transfer change
-- AllocatedLotDetailsByPackingListNo  '_1EP0P6HIB','0000000737','_47O15DR6N',1,50,' ',''
 -- AllocatedLotDetailsByPackingListNo @uniqKey='MJRL5OAJSZ',@packingListNo ='0000000005'
 -- : Ayder 12/8/2020 Added Select 'LocSelSO' to show location selected at sales order
-- =============================================  
CREATE PROCEDURE [dbo].[AllocatedLotDetailsByPackingListNo] 
 @uniqKey char(10)='' ,
 @packingListNo char(10)='' , 
  --Satish B- 04-07-2018 : Added the parameter @uniqueLnNo 
 @uniqueLnNo char(10)='',
 @startRecord int=0,
 @endRecord int=50,   
 @sortExpression nvarchar(1000) = null, --'WHLOC ASC'
 @filter nvarchar(1000) = null --'Order by WHLOC ' 
AS
DECLARE @SQL nvarchar(max)
BEGIN
;WITH AvailableLotItems
AS
(
-- Ayder 12/3/2020 For Sales Order Location
SELECT DISTINCT  
(select 'LocSelSO' from SODETAIL s 
inner join INVENTOR i
on s.UNIQ_KEY = i.UNIQ_KEY
inner join INVTMFGR mf on s.UNIQ_KEY=mf.UNIQ_KEY
inner join WAREHOUS w on mf.UNIQWH=w.UNIQWH
where s.w_key=mf.w_key and PART_SOURC='BUY'and exists
(select 'LocSelSO' from INVTMFGR i
inner join WAREHOUS w on i.UNIQWH=w.uniqwh  
where
i.w_key=s.w_key and
i.uniq_key=@uniqKey)) as LocSelSO,
    MfgrMaster.Partmfgr,
	MfgrMaster.mfgr_pt_no ,
  CONCAT(warehous.Warehouse, '/', invtmfgr.Location) WHLoc,  
  --Satish B : 04/13/2018 : Remove the empty space from lotcode
  RTRIM(LTRIM(ISNULL(pkInvtLot.LOTCODE, Space(10)))) AS lotcode,	
  pkInvtLot.EXPDATE AS EXPDATE,		
  ISNULL(pkInvtLot.REFERENCE, Space(10)) AS Reference,
  ISNULL(pkInvtLot.PONUM, Space(10)) AS PONUM,
   0  AS LOTRESQTY,   
  ISNULL(parttype.LOTDETAIL, 0) AS LOTDETAIL,  
	0 AvailableQty, 
	0 BaseAvailableQty, 
	--Satish B : 12-30-16 If part is lotted then get the loted part allocated qty else get allocated qty from pkAlloc
	
	CASE WHEN pkInvtLot.ALLOCQTY IS NOT NULL
			THEN ISNULL(pkInvtLot.ALLOCQTY,0 )
			ELSE ISNULL(pkAlloc.ALLOCQTY,0 ) 
		END AS  ALLOCQTY,
	--ISNULL(pkInvtLot.ALLOCQTY,0 ) AS ALLOCQTY,
	--ISNULL(pkInvtLot.ALLOCQTY,0 ) AS BaseAllocQty,
	CASE WHEN  pkInvtLot.ALLOCQTY IS NOT NULL THEN ISNULL(pkInvtLot.ALLOCQTY,0 ) ELSE ISNULL(pkAlloc.ALLOCQTY,0 ) 
		 END AS  BaseAllocQty,
	 Invtmfgr.W_KEY,
	 invtMpnlink.Uniq_key,
	 --dbo.fn_GenerateUniqueNumber() AS UNIQ_LOT,	
	 Space(10) AS UNIQ_LOT,	
	 Invtmfgr.UniqMfgrhd
	 ,inventor.SERIALYES AS SerialYes  
	,CASE WHEN  pkInvtLot.ALLOCQTY IS NOT NULL THEN ISNULL(pkInvtLot.ALLOCQTY,0 ) ELSE ISNULL(pkAlloc.ALLOCQTY,0 ) END AS PKALLOCQTY
	,pkAlloc.PACKLISTNO
  --Satish B : 04/13/2018 : Select UNIQUELN from PlAlloc table
	,ISNULL(pkAlloc.UniqueLn,'') AS UniqueLn
	--	: Shrikant B : 01/23/2019 : Added Column WHNO, Invtmfgr.SFBL for consign transfer change
  	 ,WHNO, Invtmfgr.SFBL
	FROM  pkAlloc pkAlloc 	
	LEFT OUTER JOIN PKINVLOT pkInvtLot ON pkAlloc.W_KEY = pkInvtLot.W_KEY AND pkAlloc.UNIQ_ALLOC=pkInvtLot.UNIQ_ALLOC --AND pkAlloc.PACKLISTNO=@packingListNo	 				
	INNER JOIN  Invtmfgr Invtmfgr ON Invtmfgr.W_KEY=pkAlloc.W_KEY 	
	INNER JOIN  Warehous Warehous ON Warehous.UNIQWH=Invtmfgr.UNIQWH		
	INNER JOIN invtMpnlink invtMpnlink ON Invtmfgr.UNIQMFGRHD =invtMpnlink.uniqmfgrhd
	INNER JOIN inventor inventor ON inventor.UNIQ_KEY=Invtmfgr.UNIQ_KEY
	INNER JOIN MfgrMaster mfgrMaster ON mfgrMaster.MfgrMasterId=invtMpnlink.MfgrMasterId
	LEFT OUTER  JOIN parttype parttype ON parttype.PART_TYPE = inventor.PART_TYPE	  	
	--Where pkAlloc.packlistno = @packingListNo AND ( invtMpnlink.Uniq_key is null or invtMpnlink.Uniq_key =@uniqKey)		
	--Satish B : 04-07-18 Added the filter of @uniqueLnNo
	Where pkAlloc.packlistno = @packingListNo AND ( invtMpnlink.Uniq_key is null or invtMpnlink.Uniq_key =@uniqKey) 
		AND (@uniqueLnNo IS NULL OR @uniqueLnNo='' OR pkAlloc.UNIQUELN= @uniqueLnNo)
  ),
	temptable as(SELECT *  from	AvailableLotItems)
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