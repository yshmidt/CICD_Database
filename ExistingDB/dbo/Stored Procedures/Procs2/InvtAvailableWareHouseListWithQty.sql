-- =============================================
-- Author:Sachin Shevale
-- Create date: 10/09/2014
-- Description:	 Get warehouse details based on inventor For get updated Qty
-- Modified : Sachin s- 08-29-2016 :Remove space
--	: Sachin s- 08-29-2016 :Added space for reference	
--	: Sachin s- 08-29-2016 :Added space for poNum
--	: Sachin s- 08-29-2016 :For lotted part temporary zero as PACKLISTNO
--	: Sachin s- 08-29-2016 Insert into temp table values
--	: Sachin s- 08-29-2016 Get lot list which are not present in the invtlot table
--	: Sachin s- 08-29-2016 Get two tables for warehouse list with lot and Get allready allocated lot  which are not present in the invtlot table
--	: Satish B- 09-23-2016 Added SHIPPEDREV column in InvtAvailableWarehouseGrid
--	: Satish B- 12-17-2016 Addes case to display warehouse grid data when ship all qty in add mode and available qty is zero
--	: Satish B- 08-28-2017 set PACKLISTNO to null instaed of 0
--	: Satish B- 09-08-2017  : display '/' only if location is present
--	: Satish B- 04-04-2018 : Added the filter of @uniqueLnNo while editing packing list
--	: Satish B- 04-04-2018 : Added the parameter @uniqueLnNo 
--  : Satish B- 04-08-2018 : Modified the filter and Check PACKLISTNO IS NULL OR PACKLISTNO=''
--	: Satish B- 04/13/2018 : Declare UniqueLn in temp @AllocateLot
--	: Satish B- 04/13/2018 : Remove the empty space from lotcode
--	: Satish B- 04/13/2018 : Select UNIQUELN from PlAlloc table
--	: Satish B- 04-13-2018 : Insert values into UniqueLn
--  : Satish B- 04/13/2018 : Pass paremeter @packingListNo to sp AllocatedLotDetailsByPackingListNo
--  : Shrikant B 01/23/2019 : Added column WHNO, SFBL, SFBLWKEY for consign transfer change
--	: Shrikant B 01/23/2019 : Added column Warehous.WHNO and Invtmfgr.SFBL for consign transfer change
--  : Shrikant B 06/11/2019 : Shrikant adds the INSTORE=0 condition to fixed the issue of Single serial number search is not working because of instore =1 
--  : Sachin B - 07/19/2019 Added PART_CLASS column in parttype join 
--  : Nitesh B 02/04/2020 Filtered invtmfgr tables location column for sfbl warehouse whenever there is sfbl warehouse filtered it on sales order uniq_ln column not to shown another sales order data   
--  : Sachin B 02/04/2020 check the lot details for lotted part when warehouse is sfbl to avoid duplicate sfbl warehouse displayed on UI. Even if it not exists
--  : Sachin B 03/06/2020  Added parameter @soNo for getting uniqln information when creating new PL 
--  : Sachin B 03/06/2020  Added join @SODETAIL for getting uniqln information when creating new PL 
--  : Ayder 12/8/2020 Added Select 'LocSelSO' to show location selected at sales order
-- InvtAvailableWareHouseListWithQty 'H30X3EOC2Y','0000000878','_5P5115395',1,150,'',''     
-- InvtAvailableWareHouseListWithQty 'XOPXWDN8DA','0000000854','_5PI0Y1VGR',1,150,'',''   
-- =============================================
CREATE PROCEDURE [dbo].[InvtAvailableWareHouseListWithQty] 
	-- Add the parameters for the stored procedure here
 @uniqKey CHAR(10)='' ,
 @packingListNo CHAR(10)='' ,
 --Satish B- 04-04-2018 : Added the parameter @uniqueLnNo 
 @uniqueLnNo CHAR(10) = '' , 
 @startRecord INT = 0,
 @endRecord INT = 50,   
 @sortExpression NVARCHAR(1000) = null, --'WHLOC ASC'
 @filter NVARCHAR(1000) = null --'Order by WHLOC ' 

AS
DECLARE @SQL NVARCHAR(max)
BEGIN
--Sachin s- 08-29-2016 Get two tables for warehouse list with lot and Get allready allocated lot  which are not present in the invtlot table
 DECLARE @AllocateLot TABLE
( 
	 RowNumber INT 
	 -- Ayder 12/3/2020 For Sales Order Location
	,LocSelSO NVARCHAR(10)
	,Partmfgr NVARCHAR(100)
	,mfgr_pt_no NVARCHAR(100)
	,WHLoc NVARCHAR(100)  
	,lotcode NVARCHAR(100)	   
	,EXPDATE DATETIME			   
	,Reference NVARCHAR(100)
	,PONUM NVARCHAR(100)   
	,LOTRESQTY DECIMAL		   
	,LOTDETAIL bit
	,AvailableQty DECIMAL		   
	,BaseAvailableQty DECIMAL	   
	,ALLOCQTY DECIMAL			   
	,BaseAllocQty DECIMAL		   
	,W_KEY NVARCHAR(10)   
	,Uniq_key NVARCHAR(10)	   
	,UNIQ_LOT NVARCHAR(10)   
	,UniqMfgrhd NVARCHAR(10)	   
	,SerialYes bit		   
	,PKALLOCQTY DECIMAL   	 
	,PACKLISTNO NVARCHAR(10)
  --Satish B : 04/13/2018 : Declare UniqueLn in temp @AllocateLot
	,UniqueLn NVARCHAR(10)
--  : Shrikant B 01/23/2019 : Added column WHNO, SFBL, SFBLWKEY for consign transfer change
  	,WHNO CHAR(3)
	,SFBL bit
	,SFBLWKEY CHAR(10)
	,TotalCount INT			  
)

;WITH AvailableFgiList
AS
-- 10/09/14 replace invtmfhd table with 2 new tables
(
	SELECT DISTINCT
	(select 'LocSelSO' from SODETAIL s 
inner join INVENTOR i
on s.UNIQ_KEY = i.UNIQ_KEY
inner join INVTMFGR mf on s.UNIQ_KEY=mf.UNIQ_KEY
inner join WAREHOUS w on mf.UNIQWH=w.UNIQWH
where s.w_key=mf.w_key and PART_SOURC='BUY' and mf.w_key=Invtmfgr_.w_key and exists
(select 'LocSelSO' from INVTMFGR i
inner join WAREHOUS w on i.UNIQWH=w.uniqwh  
where
i.w_key=s.w_key and
i.uniq_key=@uniqKey and i.w_key=Invtmfgr_.w_key)) as LocSelSO,
    MfgrMaster.Partmfgr,
	MfgrMaster.mfgr_pt_no ,
  --(warehous.Warehouse  invtmfgr.Location) AS WHLoc,
  --09-08-2017 Satish B : display '/' only if location is present
  RTRIM(warehous.Warehouse) + CASE WHEN Invtmfgr_.Location IS NULL OR Invtmfgr_.Location='' THEN '' ELSE '/' END + Invtmfgr_.Location AS WHLoc
  --,CONCAT(warehous.Warehouse, '/', invtmfgr.Location) WHLoc,  
--Satish B : 04/13/2018 : Remove the empty space from lotcode
 ,RTRIM(LTRIM(ISNULL(invtlot.lotcode, Space(10)))) AS lotcode,	
--Sachin s- 08-29-2016 :Remove space
  --ISNULL(invtlot.EXPDATE, Space(20)) AS EXPDATE,		
  invtlot.EXPDATE AS EXPDATE,	
--Sachin s- 08-29-2016 :Added space for reference	
  ISNULL(invtlot.Reference, Space(10)) AS Reference, 
--Sachin s- 08-29-2016 :Added space for poNum
  ISNULL(invtlot.PONUM, Space(10)) AS PONUM, 
  ISNULL(invtlot.LOTRESQTY, 0) AS LOTRESQTY, 
  parttype.LOTDETAIL,     
  CASE 
  WHEN parttype.LOTDETAIL = 1
  THEN 
  ISNULL ((invtlot.LOTQTY - invtlot.LOTRESQTY),0)  
  ELSE
    ISNULL( (Invtmfgr_.QTY_OH - Invtmfgr_.RESERVED),0)	
	END	  
	AS  AvailableQty, 

CASE 
  WHEN parttype.LOTDETAIL = 1
  THEN 
  ISNULL((invtlot.LOTQTY-invtlot.LOTRESQTY) ,0) 
  ELSE
    ISNULL ((Invtmfgr_.QTY_OH - Invtmfgr_.RESERVED),0)	
	END	  
	AS  BaseAvailableQty,   
		--CASE WHEN  Invtmfgr.SFBL=1 THEN 
		0 AS ALLOCQTY,
		0 AS BaseAllocQty,
	 Invtmfgr_.W_KEY,
	 invtMpnlink.Uniq_key,
	 ISNULL(invtlot.UNIQ_LOT, SPACE(10)) AS UNIQ_LOT,	
	 Invtmfgr_.UniqMfgrhd
	 ,inventor.SERIALYES AS SerialYes  
	,ISNULL(pkAlloc.ALLOCQTY,0 )AS PKALLOCQTY
--Sachin s- 08-29-2016 :For lotted part temporary zero as PACKLISTNO
	--Satish B- 12-17-2016 Addes case to display warehouse grid data when ship all qty in add mode and available qty is zero
	,CASE 
	WHEN @packingListNo= ''
	--Satish B- 8-28-2017 set PACKLISTNO to null instaed of 0
		--then 0
		then null
	else
			@packingListNo 
		End AS PACKLISTNO,
		--Satish B- 09-23-2016 Added SHIPPEDREV column in InvtAvailableWarehouseGrid
		'' AS SHIPPEDREV   
    -- Satish B : 04/13/2018 : Select UNIQUELN from PlAlloc table
	-- ,ISNULL(pkAlloc.UniqueLn,'') AS UniqueLn
--  : Sachin B 03/06/2020  Added join @SODETAIL for getting uniqln information when creating new PL
	 , CASE WHEN @uniqueLnNo IS NULL THEN ISNULL(pkAlloc.UniqueLn,'') ELSE @uniqueLnNo END AS UniqueLn 
--	: Shrikant B 01/23/2019 : Added column Warehous.WHNO and Invtmfgr.SFBL for consign transfer change
  , Warehous.WHNO, Invtmfgr_.SFBL
	FROM Invtmfgr Invtmfgr_ 	
	INNER JOIN  Warehous Warehous ON Warehous.UNIQWH=Invtmfgr_.UNIQWH
	INNER JOIN invtMpnlink invtMpnlink ON Invtmfgr_.UNIQMFGRHD =invtMpnlink.uniqmfgrhd
	INNER JOIN inventor inventor ON inventor.UNIQ_KEY=Invtmfgr_.UNIQ_KEY
	INNER JOIN MfgrMaster mfgrMaster ON mfgrMaster.MfgrMasterId=invtMpnlink.MfgrMasterId
	--Satish B- 04-04-2018 : Added the filter of @uniqueLnNo while editing packing list
	LEFT OUTER JOIN  pkAlloc pkAlloc ON pkAlloc.W_KEY = Invtmfgr_.W_KEY AND pkAlloc.PACKLISTNO = @packingListNo AND pkAlloc.UNIQUELN=@uniqueLnNo
	-- LEFT OUTER JOIN PKINVLOT pkInvtLot ON pkInvtLot.W_KEY = Invtmfgr.W_KEY AND pkInvtLot.packlistno = @packingListNo 
	LEFT OUTER JOIN invtlot invtlot ON invtlot.W_KEY =Invtmfgr_.W_KEY 
--  : Sachin B 02/04/2020 check the lot details for lotted part when warehouse is sfbl to avoid duplicate sfbl warehouse displayed on UI. Even if it not exists	                
                 --   AND invtlot.lotcode = CASE WHEN (Invtmfgr.SFBL =1 ) THEN (SELECT LOTCODE FROM PKINVLOT WHERE lotcode = invtlot.lotcode AND packlistno=@packingListNo) ELSE  invtlot.lotcode END  
	                --AND invtlot.EXPDATE = CASE WHEN (Invtmfgr.SFBL =1 ) THEN (SELECT EXPDATE FROM PKINVLOT WHERE lotcode = invtlot.lotcode AND packlistno=@packingListNo) ELSE invtlot.EXPDATE END  
                 --   AND invtlot.REFERENCE = CASE WHEN (Invtmfgr.SFBL =1 ) THEN (SELECT REFERENCE FROM PKINVLOT WHERE lotcode = invtlot.lotcode AND packlistno=@packingListNo) ELSE  invtlot.REFERENCE END
                 --   AND invtlot.ponum = CASE WHEN (Invtmfgr.SFBL =1 ) THEN (SELECT ponum FROM PKINVLOT WHERE lotcode = invtlot.lotcode AND packlistno=@packingListNo) ELSE invtlot.ponum END								
--  : Sachin -  07-19-2019 Added PART_CLASS column in parttype join   
	LEFT OUTER JOIN parttype parttype ON parttype.PART_TYPE=inventor.PART_TYPE	AND parttype.PART_CLASS=inventor.PART_CLASS
--  : Sachin B 03/06/2020  Added join @SODETAIL for getting uniqln information when creating new PL 
	LEFT OUTER JOIN SODETAIL sod ON Invtmfgr_.UNIQ_KEY = sod.UNIQ_KEY AND Invtmfgr_.W_KEY = sod.W_KEY AND sod.UNIQUELN = @uniqueLnNo			
	WHERE 	
	( invtMpnlink.Uniq_key is null or invtMpnlink.Uniq_key =@uniqKey)		
	AND Warehouse <> 'WIP' AND Warehouse <> 'WO-WIP' AND Warehouse <> 'MRB'
	-- 11/02/2018 Shrikant Remove netable =1 consition for display consign location whioch has sfbl is 1
	AND Netable = CASE WHEN (Invtmfgr_.SFBL=1 AND 1=  (SELECT isSFBL FROM  SODETAIL WHERE UNIQUELN = @uniqueLnNo )) THEN  Invtmfgr_.Netable ELSE 1 END
	AND Invtmfgr_.Is_Deleted = 0 AND invtMpnlink.Is_deleted = 0  AND mfgrMaster.is_deleted=0 AND Invtmfgr_.COUNTFLAG = ''
-- : Shrikant B 06/11/2019 : Shrikant adds the INSTORE=0 condition to fixed the issue of Single serial number search is not working because of instore =1 
	AND INSTORE=0 
	--  : Nitesh B 02/04/2020 Filtered invtmfgr tables location column for sfbl warehouse whenever there is sfbl warehouse filtered it on sales order uniq_ln column not to shown another sales order data   
	AND Invtmfgr_.[LOCATION] = CASE WHEN Invtmfgr_.SFBL=1 THEN @uniqueLnNo  ELSE Invtmfgr_.[LOCATION]  END
	),

	--temptable as(SELECT *  from	AvailableFgiList WHERE AvailableQty > 0 OR PACKLISTNO IS NOT NULL )
	--Satish B- 04-08-2018 : Modified the filter and Check PACKLISTNO IS NULL OR PACKLISTNO=''
	temptable as(SELECT *  from	AvailableFgiList WHERE (AvailableQty > 0  AND (PACKLISTNO IS NULL OR PACKLISTNO='' OR PACKLISTNO= @packingListNo))) 
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
	
	--Sachin s- 08-29-2016 Insert into temp table values
	INSERT INTO @AllocateLot(
		RowNumber
		-- Ayder 12/3/2020 For Sales Order Location
		,LocSelSO
		,Partmfgr
		,mfgr_pt_no
		,WHLoc
		,lotcode
		,EXPDATE
		,Reference
		,PONUM	
		,LOTRESQTY
		,LOTDETAIL
		,AvailableQty
		,BaseAvailableQty
		,ALLOCQTY
		,BaseAllocQty
		,W_KEY
		,Uniq_key
		,UNIQ_LOT
		,UniqMfgrhd
		,SerialYes
		,PKALLOCQTY				
		,PACKLISTNO
      --Satish B : 04-13-2018 : Insert values into UniqueLn
		,UniqueLn 
		--  : Shrikant B 01/23/2019 : Added column WHNO, SFBL, SFBLWKEY for consign transfer change
		,WHNO
		,SFBL
		,TotalCount
	)	
	--Sachin s- 08-29-2016 Get lot list which are not present in the invtlot table
	--Satish B : 04/13/2018 : Pass paremeter @packingListNo to sp AllocatedLotDetailsByPackingListNo
  EXEC AllocatedLotDetailsByPackingListNo @uniqKey, @packingListNo, @uniqueLnNo 
	SELECT * from @AllocateLot
   END