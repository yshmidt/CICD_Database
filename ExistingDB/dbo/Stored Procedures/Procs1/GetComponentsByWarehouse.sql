-- =============================================
-- Author:		Rajendra K	
-- Create date: <04/03/2018>
-- Description:	Get Components by warehouse
-- [dbo].[GetComponentsByWarehouse] '','1618R36C8C','',0
-- Modification
   -- 04/16/2018 Rajendra K : Added temp #tempTransTable table to get Transfered components
   -- 04/16/2018 Rajendra K : Added new column Transdate in select list and in order by section
   -- 04/16/2018 Rajendra K : Added #tempTransTable in join section 
   -- 04/16/2018 Rajendra K : Removed use of funciton 'fn_GetDataBySortAndFilters'
   -- 11/22/2018 Mahesh B : Get the record on basis of the unique key  
   -- 04/11/2019 Rajendra K : Added new column "Netable"
   -- 04/11/2019 Rajendra K : Removed the setting 
   -- 04/11/2019 Rajendra K : Removed Netable condition  
   -- 05/10/2019 Rajendra K : Removed @out_TotalNumberOfRecord parameter &  Remove ORDER BY  
   -- 05/10/2019 Rajendra K : Added Condition For Location
   -- 05/10/2019  Rajendra K : Added @sqlQuery Variable
   -- 05/10/2019  Rajendra K : Added Dynamic Query 
   -- 05/17/2019 Rajendra K :  Get the row count after the filter and removed the filter from query and used fn_GetDataBySortAndFilters function to get rows
   -- 05/20/2019 Rajendra K : Added two column "CustPartNo" and "CUSTNO" in select list
   -- 03/02/2020 Rajendra K : Changed type VARCHAR to NVARCHAR
   -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition 
--=============================================================================================================
CREATE PROCEDURE GetComponentsByWarehouse
(
@uniqKey AS CHAR(10), 
@uniqWH AS CHAR(10)='', 
@location AS NVARCHAR(100) = '',   -- 03/02/2020 Rajendra K : Changed type VARCHAR to NVARCHAR
@isLocation BIT,
@isWHMap BIT=0, 
@startRecord int =1,
@endRecord int =100
--@out_TotalNumberOfRecord INT OUTPUT   -- 05/10/2019 Rajendra K : Removed @out_TotalNumberOfRecord parameter &  Remove ORDER BY  
)
AS 
BEGIN
	SET NOCOUNT ON;	
	
	DECLARE @nonNettable BIT,@sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX);    -- 03/12/2019  Rajendra K : Added @sqlQuery Variable

	-- 04/11/2019 Rajendra K : Removed the setting 
	---- Get Manufacturer default settings logic
	--SELECT SettingName
	--	   ,LTRIM(WM.SettingValue) SettingValue
	--INTO  #tempMfgrSettings
	--FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId  
	--WHERE SettingName IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation') 

 --   --Assign values to variables to hold values for Manufacturer  default settings	
	--SET @nonNettable= ISNULL((SELECT CONVERT(BIT, SettingValue) FROM #tempMfgrSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0) 

    -- 04/16/2018 Rajendra K : Get Transfered components
	SELECT MAX(DATE) TransDate,TOWKEY INTO #tempTransTable FROM INVTTRNS GROUP BY TOWKEY

	SELECT DISTINCT I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO
				   ,(CASE WHEN I.PART_CLASS IS NULL OR  I.PART_CLASS = '' THEN I.PART_CLASS ELSE RTRIM(I.PART_CLASS) +' / ' END ) + 
					(CASE WHEN I.PART_TYPE IS NULL OR I.PART_TYPE ='' THEN I.PART_TYPE ELSE RTRIM(I.PART_TYPE) + ' / '+RTRIM(I.DESCRIPT) END) AS Descript		
				   ,MM.PARTMFGR AS PartMfgr
				   ,MM.MFGR_PT_NO AS MfgrPtNo
				   ,WH.Warehouse 
				   ,IM.Location
				   ,IP.IPKEYUNIQUE AS SID
				   ,IM.UniqWH 
				   ,IM.W_KEY AS WKey
				   ,IL.UNIQ_LOT
				   ,IL.UNIQ_LOT AS UniqLot
				   ,IL.LotCode
				   ,IL.ExpDate
				   ,IL.Reference
				   ,COALESCE(IP.PkgBalance,IL.LotQty,IM.QTY_OH)-COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) AS QtyOh
				   ,ROW_NUMBER() OVER(ORDER BY MM.PARTMFGR ASC) AS RowNumber 
				   ,IM.UniqMfgrhd  
				   ,MM.AutoLocation AS MfgrAutoLocation
				   ,WH.AUTOLOCATION AS WHAutoLocation
				   ,RTRIM(wh.Warehouse)+ (CASE WHEN IM.Location IS NULL OR IM.Location =''  THEN RTRIM(IM.Location) ELSE ' / '+RTRIM(IM.Location) END) AS WarehouseLocation
				   ,I.UNIQ_KEY AS UniqKey
				   ,I.SERIALYES AS SerialYes
				   ,I.useipkey AS UseIpKey
				   ,IP.IPKEYUNIQUE AS IPKEYUnique
				   ,I.PART_NO AS PartNo
				   ,I.Revision AS Revision
				   ,I.Part_Class AS PartClass
				   ,I.Part_Type AS PartType
				   ,COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) AS Reserved
				   ,IT.TransDate -- 04/16/2018 Rajendra K : Added new column
				   ,IM.NETABLE AS Netable -- 04/11/2019 Rajendra K : Added new column "Netable"
				   ,RTRIM(I.CUSTPARTNO) + (CASE WHEN I.CUSTREV IS NULL OR I.CUSTREV = '' THEN I.CUSTREV ELSE '/'+ I.CUSTREV END) AS CustPartNo
				   ,I.CUSTNO   -- 05/20/2019 Rajendra K : Added two column "CustPartNo" and "CUSTNO" in select list
	INTO #tempComponents
	FROM INVENTOR I   INNER JOIN INVTMFGR IM ON I.UNIQ_KEY = IM.UNIQ_KEY --AND (@nonNettable = 1 OR IM.NETABLE = 1)     -- 03/02/2020 Rajendra K : Added the im.SFBL = 0 condition 
																	   AND IM.InStore = 0 AND IM.IS_DELETED = 0 AND IM.SFBL = 0
					  INNER JOIN InvtMpnLink IML ON IM.UNIQMFGRHD = IML.uniqmfgrhd
					  INNER JOIN MfgrMaster MM ON IML.MfgrMasterId = MM.MfgrMasterId
					  INNER JOIN WAREHOUS WH ON IM.UNIQWH = WH.UNIQWH
					  LEFT JOIN INVTLOT IL ON IM.W_KEY = IL.W_KEY
					  LEFT JOIN IPKEY IP ON I.UNIQ_KEY = IP.UNIQ_KEY 
											AND IM.W_KEY = IP.W_KEY
											AND COALESCE(IL.LOTCODE,IP.LOTCODE)= IP.LOTCODE
											AND ISNULL(IL.REFERENCE,IP.REFERENCE)= IP.REFERENCE
											AND ISNULL(IL.PONUM,IP.PONUM)= IP.PONUM
											AND 1 =(CASE WHEN IL.LOTCODE IS NULL OR IL.LOTCODE= '' THEN 1 
											        WHEN IL.EXPDATE = IP.EXPDATE THEN 1 ELSE 0 END)
					  LEFT JOIN #tempTransTable IT ON IM.W_KEY = IT.TOWKEY -- 04/16/2018 Rajendra K : added temp table #tempTransTable  in join section
	WHERE WH.WAREHOUSE NOT IN('WO-WIP','WIP') AND (@uniqKey IS NULL OR @uniqKey ='' OR I.UNIQ_KEY = @uniqKey) -- 11/22/2018 Mahesh B : Get the record on basis of the unique key  
		   AND COALESCE(IP.PkgBalance,IL.LotQty,IM.QTY_OH)-COALESCE(IP.qtyAllocatedTotal,IL.LotResQty,IM.Reserved) > 0 
		   AND (@uniqWH IS NULL OR @uniqWH= '' OR IM.UNIQWH = @uniqWH)
		   AND ((@isLocation = 0) OR((@isWHMap=1 AND IM.LOCATION LIKE '%'+@location+'%') OR  (@isWHMap=0 AND IM.LOCATION = @location))) 
		   AND IM.LOCATION NOT IN(SELECT inspHeaderId FROM inspectionHeader)  -- 05/10/2019 Rajendra K : Added Condition For Location

	-- 03/13/2019  Rajendra K : Added Dynamic Query 
	-- 05/17/2019 Rajendra K :  Get the row count after the filter and removed the filter from query and used fn_GetDataBySortAndFilters function to get rows
		SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempComponents','','','','WarehouseLocation',@startRecord,@endRecord))       
        EXEC sp_executesql @rowCount

		SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #tempComponents','','',N'Warehouse,Location,PartMfgr,MfgrPtNo','',@startRecord,@endRecord))  
	    EXEC sp_executesql @sqlQuery		 

	 -- 05/10/2019 Rajendra K : Removed @out_TotalNumberOfRecord parameter &  Remove ORDER BY  
	--ORDER BY	
	--	 IT.TransDate DESC -- 04/16/2018 Rajendra K : added column TransDate in order by section
	--    ,WH.Warehouse 
	--    ,IM.Location   
	--	,MM.PARTMFGR
	--    ,MM.MFGR_PT_NO
	--	OFFSET @startRecord -1 ROWS FETCH NEXT @endRecord ROWS ONLY;

   --SET @out_TotalNumberOfRecord = (SELECT COUNT(1) FROM #tempComponents) -- Set total count to Out parameter 

   -- 04/16/2018 Rajendra K : Removed use of funciton 'fn_GetDataBySortAndFilters'

   --Drop temp table
   --DROP TABLE #tempMfgrSettings
END