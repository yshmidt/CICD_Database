-- =============================================              
-- Author: Shivshankar Patil               
-- Create date: <03/15/16>              
-- Description: <Get Inventory Summary Grid Records>               
-- [dbo].[GetInventorDetail] '','InternalInvtStr'              
-- Shivshankar P :  25/04/17 Added Taxable column            
-- Shivshankar P :  14/06/17 POitem which are not LCANCEL =0             
-- Shivshankar P :  24/08/17 Used 'totalCount' to Take Row COUNT             
-- Shivshankar P :  26/09/17 Removed 'totalCount' to Taking to much Time to load data created Seprate Query to COUNT and added 'MAKE_BUY' column            
-- Shivshankar P :  10/03/17 Added Column for Custpartno,Custrev             
-- Shivshankar P :  10/11/17 When @inventoryType='Inactive Parts' get only Inactive parts and changed the resourceKey for 'Mfgr Part Number' to 'Manufacturer Part No'            
-- Shivshankar P :  10/11/17 Added Column AspnetBuyer            
-- Shivshankar P :  11/09/17 Added Column CustName ,CustomPartRev and implemented CONSG Part No Filter            
-- Shivshankar P :  01/10/17 Added filter and sort functionality            
-- Shivshankar P :  01/16/18 Added filter by @uniqKey for UDF            
-- Shivshankar P :  01/16/18 Added filter by @uniqKey for UDF             
-- Shivshankar P :  01/21/18 Added Where clause with @uniqKey            
-- Shivshankar P :  03/14/18 Added warehouse Location filter            
-- Shivshankar P :  04/03/18 Changed the filter by warehouse            
-- Shivshankar P :  05/15/18 Issue with lot code filter            
-- Rajendra K : 10/30/2018 Converted script to Dynamic SQL            
-- Mahesh B: 11/29/2018 added the InspectionQty column            
-- Mahesh B: 12/05/2018 Applied the filter           
-- Nitesh B : 12/06/2018 : Fixed the issue with offset for inactive parts and MPN search          
-- Nitesh B : 12/11/2018 : Fixed the issue for inactive and Mfgr search not working         
-- Nitesh B 1/14/2018 Removed the offset      
-- Nitesh B 1/22/2019 : Remove the search term condition for Distinct part      
-- Nitesh B 1/22/2019 : Remove join for Distinct part      
-- Nitesh B 1/22/2019 : get the part uniqKeys based on mfgr search      
-- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows      
-- Shivshankar P 1/28/2019 :   Removed Space from COALESCE      
-- Nitesh B 05/03/2019 : Change Length of Lastchangeinit 8 to 512      
-- Rajendra K : 05/06/2019 : Added condition when search type = "Manufacturer Part No" and @searchTerm Not Exists      
-- Nitesh B: 7/30/2019 added the BuyerActionQty column      
-- Rajendra K : 08/06/2019 : Changed @location datatype VARCHAR to NVARCHAR.      
-- 08/08/19 YS location is 200 characters in all the tables      
-- Nitesh B : 8/19/2019 : Remove repeated CASE for get "Manufacturer Part No"      
-- Rajendra K : 12/12/2019 : Get filtered data by both @warehouse,@Location and @LotCode and changed condition if @lotcode is empty or @warehouse, @Loctaion is empty      
-- Rajendra K : 01/09/2020 : Changes the join LEFT to INNER with invtlot table if lotcode is  provided and changed the condition      
-- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50    
-- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list  
-- Rajendra K : 02/14/2020 : Added ExtraKittedQty column in #tempData table  
-- 04/16/2020 Shivshankar P : To improve performance add @lFCInstalled = dbo.fn_IsFCInstalled() and remove from dynamic query    
-- 04/20/2020 Shivshankar P : Remove Insert Records into Temp table and modify dynamic SQL to get records    
-- 04/20/2020 Shivshankar P : Modify SP to improve performance and Created Dynamic query for @wareHouse, @location, @LotCode search    
-- 08/25/2020 Rajendra K : Added condition AllocatedQty > 0 when calculating the ExcessQty Qty
-- 08/27/2020 Dastan T: Added Revision check, if Revision is not null add / to CustPartNo column, if null, do not add 
-- 09/17/2020 Shivshankar P : Added StockAvail column in #tempData table and selection list
-- [dbo].[GetInventorDetail] @inventoryType ='Internal Inventory',@startRecord=1,@endRecord=100,@searchTerm='',@uniqKey ='_43G0KLGKW,_1LR0NALAI,_1EI0NK1ZM,_2DO0JNHGC,C3E8ARNEGU,_01F15SZA8,U1E0WSYUZF,_01F15SZY5,Y90R4FUYZ9'            
-- [dbo].[GetInventorDetail] @inventoryType ='Internal Inventory',@startRecord=1,@endRecord=150,@searchTerm='',@wareHouse ='main1', @uniqKey ='',@LotCode='',@location = ''           
-- =============================================              
CREATE PROCEDURE [dbo].[GetInventorDetail]             
 -- Add the parameters for the stored procedure here              
    @searchTerm NVARCHAR(200)  =null,              
    @inventoryType NVARCHAR(200) = null ,              
    @startRecord INT =1,              
    @endRecord INT =150,               
    @sortExpression NVARCHAR(1000) = null ,            
 @filter NVARCHAR(1000) = null,            
 @uniqKey NVARCHAR(MAX)  =' ',            
 @lotCode VARCHAR(45) =' ',            
 @wareHouse VARCHAR(45) =' ',            
 @location NVARCHAR(200) =' '    -- Rajendra K : 08/06/2019 : Changed @location datatype VARCHAR to NVARCHAR.        
AS                  
  BEGIN              
   SET NOCOUNT ON;              
   DECLARE @lFCInstalled BIT, @sqlQuery NVARCHAR(MAX), @setFilter BIT =0 , @rowCount NVARCHAR(MAX);            
   IF OBJECT_ID ('tempdb.dbo.#tempData') IS NOT NULL            
                    DROP TABLE #tempData           
               
   SET @sortExpression = CASE WHEN @sortExpression IS NULL OR @sortExpression = '' THEN  'Part_No' ELSE @sortExpression END            
     
   -- Mahesh B: 11/29/2018 added the InspectionQty column    
   -- Nitesh B 05/03/2019 : Change Length of Lastchangeinit 8 to 512           
   -- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50    
   -- Shivshankar P :  25/04/17 Added Taxable column     
   -- 04/20/2020 Shivshankar P : Remove Insert Records into Temp table and modify dynamic SQL to get records     
   CREATE TABLE #tempData (Part_No CHAR(100),Revision CHAR(8),Part_Class CHAR(8),Part_Type CHAR(8),Descript varchar(100),U_Of_Meas CHAR(4),ITAR BIT,Part_Sourc CHAR(10)              
         ,LOTDETAIL BIT, OnHand NUMERIC(12,2), Allocated NUMERIC(12,2), Available NUMERIC(12,2), InspectionQty NUMERIC(10,2), ReceivingQty NUMERIC(10,2), BuyerActionQty NUMERIC(10,2)    
   ,Date smalldatetime, RemainingBalance NUMERIC(10,2),Serialyes BIT,useipkey BIT,Pur_Uofm  CHAR(4),Package CHAR(15) ,Matltype  CHAR(10) ,Eau NUMERIC (14,0)    
   ,Status CHAR(8), Scrap NUMERIC(6,2),Setupscrap  NUMERIC(4,0), Uniq_Key CHAR(10), Taxable BIT  ,Lastchangeinit CHAR(512), MakeBuy BIT            
         ,Custpartno  CHAR(35),Custrev CHAR(8),AspnetBuyer uniqueidentifier ,CustName CHAR(50), CustomPartRev CHAR(100), INT_UNIQ CHAR(10),  
   ExtraKittedQty NUMERIC(12,2), StockAvail NUMERIC(12,2));-- Rajendra K : 02/14/2020 : Added ExtraKittedQty column in #tempData table  
   -- 09/17/2020 Shivshankar P : Added StockAvail column in #tempData table and selection list
   
   -- Shivshankar P :  04/11/18 Get filtered data by both warehouse,Location and UDF search  and assigned empty to variable            
   SET @LotCode = ISNULL(@LotCode,'')            
   SET @wareHouse = ISNULL(@wareHouse,'')            
   SET @location = ISNULL(@location,'')            
   SET @searchTerm = ISNULL(@searchTerm,'')  -- Shivshankar P :  05/15/18 Checked the value is null            
       
   -- 04/16/2020 Shivshankar P : To improve performance add @lFCInstalled = dbo.fn_IsFCInstalled() and remove from dynamic query    
   SELECT @lFCInstalled = dbo.fn_IsFCInstalled();     
               
   IF(@inventoryType ='Internal Inventory'  OR  @inventoryType='CONSG Part No')              
    BEGIN                 
      -- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows       
      --SET @rowCount =( SELECT COUNT(1)  FROM INVENTOR  invt LEFT JOIN               
      --              PARTTYPE prt ON  invt.PART_TYPE = prt.PART_TYPE and invt.PART_CLASS  =prt.PART_CLASS               
      --               LEFT JOIN CUSTOMER  ON CUSTOMER.CUSTNO = invt.CUSTNO            
--              OUTER APPLY (SELECT SUM(Qty_Oh) AS OnHand,SUM(RESERVED) AS Allocated ,SUM(Qty_Oh) - SUM(RESERVED) AS Available  FROM INVTMFGR WHERE INVTMFGR.UNIQ_KEY = invt.UNIQ_KEY GROUP BY INVTMFGR.UNIQ_KEY) invtmf              
      --              OUTER APPLY (SELECT SUM(Qty_rec) AS ReceivingQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY              
      --              AND ((receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 0 AND receiverDetail.isinspCompleted = 0)             
      --              OR (receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted = 1))            
      --              GROUP BY receiverDetail.UNIQ_KEY) received   -- Mahesh B: 11/29/2018 added the InspectionQty column            
      --              OUTER APPLY (SELECT SUM(Qty_rec) AS InspectionQty FROM receiverDetail             
      --              WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY              
      --              and receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted=0            
      --              GROUP BY receiverDetail.UNIQ_KEY) inspection    -- Mahesh B: 11/29/2018 added the InspectionQty column            
      --              OUTER APPLY (SELECT TOP 1 DATE AS Date  FROM INVT_ISU WHERE INVT_ISU.UNIQ_KEY = invt.UNIQ_KEY  ORDER BY date) invtisu              
      --              OUTER APPLY (SELECT (SUM(poit.ORD_QTY) - SUM(poit.ACPT_QTY)) AS RemainingBalance            
      --                 FROM POITEMS poit JOIN  POMAIN PO ON poit.PONUM = PO.PONUM  WHERE             
      --                 poit.UNIQ_KEY = invt.UNIQ_KEY  AND PO.POSTATUS   = 'OPEN' AND poit.LCANCEL = 0             
      --                 GROUP BY poit.UNIQ_KEY) poitem   -- Shivshankar P :  14/06/17 POitem which are not POSTATUS (CLOSED,NEW)            
      --       WHERE  INVT.STATUS = 'Active'  AND ((@inventoryType ='Internal Inventory'  -- Shivshankar P :  01/21/18 Added Where clause with @uniqKey            
      --                    AND ((@searchTerm <> ' ' AND invt.PART_NO like '%' + @searchTerm + '%')             
      --                OR (@searchTerm = ' ' AND invt.PART_NO =invt.PART_NO))         
      --              AND  invt.PART_SOURC <> 'CONSG' )            
      --                    OR (@inventoryType ='CONSG Part No'             
      --              AND ((@searchTerm <> ' ' AND invt.custpartno like '%' + @searchTerm + '%')             
      --                 OR (@searchTerm = ' ' AND invt.custpartno =invt.custpartno))            
      --              AND invt.PART_SOURC  = 'CONSG' ))            
      --             AND ((@uniqKey <> ' ' AND  invt.UNIQ_KEY  IN             
      --             (SELECT id from dbo.[fn_simpleVarcharlistToTable](@uniqKey,','))) OR  (@uniqKey = ' '  AND invt.UNIQ_KEY =invt.UNIQ_KEY)))            
            
  -- 04/20/2020 Shivshankar P : Remove Insert Records into Temp table and modify dynamic SQL to get records    
        SET @sqlQuery = 'SELECT CASE WHEN invt.Revision <> '''' THEN  RTRIM(invt.Part_No)  + ''/''+ LTRIM(invt.REVISION) ELSE invt.Part_No END Part_No,'            
    +' invt.Revision, invt.Part_Class, invt.Part_Type, RTRIM(invt.PART_CLASS) +''/'' + RTRIM(invt.PART_TYPE) +''/'' + RTRIM(invt.DESCRIPT) Descript'            
             +',invt.U_Of_Meas, invt.ITAR, invt.Part_Sourc, prt.LOTDETAIL, invtmf.OnHand'  -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list  
			 -- 09/17/2020 Shivshankar P : Added StockAvail column in #tempData table and selection list
             +',invtmf.Allocated, (invtmf.Available + ISNULL(ExcessQty.addqty,0.00)) AS Available,ISNULL(invtmf.Available,0.00) AS StockAvail,ISNULL(ExcessQty.addqty,0.00) AS ExtraKittedQty, inspection.InspectionQty '  -- Mahesh B: 11/29/2018 added the InspectionQty column            
             +',received.ReceivingQty, BuyerAction.BuyerActionQty , invtisu.Date'      
             +',poitem.RemainingBalance, invt.Serialyes, invt.useipkey,  '            
             +' invt.Pur_Uofm, invt.Package, invt.Matltype, invt.Eau, invt.Status, invt.Scrap, invt.Setupscrap, invt.Uniq_Key, '            
             +' invt.Taxable  ,invt.Lastchangeinit  '-- Shivshankar P :  25/04/17 Added Taxable and LASTCHANGEINIT column '            
             +',MAKE_BUY  MakeBuy'-- Shivshankar P :  26/09/17 Removed 'totalCount' to Taking to much Time created Seprate Query to COUNT and added 'MAKE_BUY' column            
             +',Custpartno, Custrev,'-- Shivshankar P :  10/03/17 Added Column Custpartno,Custrev             
             +'AspnetBuyer,'-- Shivshankar P :  10/11/17 Added Column AspnetBuyer            
             +'CustName,'-- Shivshankar P :  11/07/17 Added Column CustName                         
             -- 08/27/2020 Dastan T:      Added Revision check, if Revision is not null add / to CustPartNo column, if null, do not add  
             +'CASE WHEN invt.CUSTPARTNO <> '''' THEN  CASE WHEN invt.CUSTPARTNO <> '''' AND RTRIM(ISNULL(invt.CUSTREV,''''))<>''''  THEN RTRIM(invt.CUSTPARTNO) + ''/''+ RTRIM(invt.CUSTREV) '   -- DastanT :  27/08/20 Added Revision check                      
             +' ELSE  invt.CUSTPARTNO END '            
             +' ELSE invt.CUSTREV END  CustomPartRev, '-- Shivshankar P :  151/09/17 Added Column CustName ,CustomPartRev          
             +'INT_UNIQ '            
             +'FROM INVENTOR  invt LEFT JOIN   '            
             +'PARTTYPE prt ON  invt.PART_TYPE = prt.PART_TYPE and invt.PART_CLASS  =prt.PART_CLASS   '            
             +'LEFT JOIN CUSTOMER  ON CUSTOMER.CUSTNO = invt.CUSTNO '            
             +'OUTER APPLY (SELECT SUM(Qty_Oh) AS OnHand,SUM(RESERVED) AS Allocated ,SUM(Qty_Oh) - SUM(RESERVED) AS Available,UNIQ_KEY  FROM INVTMFGR WHERE INVTMFGR.UNIQ_KEY = invt.UNIQ_KEY GROUP BY INVTMFGR.UNIQ_KEY) invtmf  '            
             +'OUTER APPLY (SELECT SUM(Qty_rec) AS ReceivingQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY              
                    AND ((receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 0 AND receiverDetail.isinspCompleted = 0)             
                    OR (receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted = 1))            
                    GROUP BY receiverDetail.UNIQ_KEY) received '  -- Mahesh B: 11/29/2018 added the InspectionQty column            
             +'OUTER APPLY (SELECT SUM(Qty_rec) AS InspectionQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY              
                   AND receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted=0 GROUP BY receiverDetail.UNIQ_KEY) inspection  '  -- Mahesh B: 11/29/2018 added the InspectionQty column            
             +'OUTER APPLY (SELECT (SUM(FailedQty) - SUM(ReturnQty) - SUM(Buyer_Accept)) AS BuyerActionQty FROM inspectionHeader       
                   WHERE receiverDetId IN (SELECT receiverDetId FROM receiverDetail WHERE UNIQ_KEY = invt.UNIQ_KEY GROUP BY receiverDetail.receiverDetId)) BuyerAction  '  -- Nitesh B: 7/30/2019 added the BuyerActionQty column      
             +'OUTER APPLY (SELECT TOP 1 DATE AS Date  FROM INVT_ISU WHERE INVT_ISU.UNIQ_KEY = invt.UNIQ_KEY  ORDER BY date) invtisu  '            
             +'OUTER APPLY (SELECT (SUM(poit.ORD_QTY) - SUM(poit.ACPT_QTY)) AS RemainingBalance '            
             +' FROM POITEMS poit JOIN  POMAIN PO ON poit.PONUM = PO.PONUM  WHERE '            
             +' poit.UNIQ_KEY = invt.UNIQ_KEY  AND PO.POSTATUS   = ''OPEN'' AND poit.LCANCEL = 0 '            
             +' GROUP BY poit.UNIQ_KEY) poitem   '-- Shivshankar P :  14/06/17 POitem which are not POSTATUS (CLOSED,NEW)    
       +' OUTER APPLY (  
    SELECT ABS(sum(shortqty)) as addqty   
    FROM kamain WHERE invtmf.UNIQ_KEY=kamain.UNIQ_KEY and invtmf.OnHand<>0  and SHORTQTY<0 and allocatedQty > 0 '
	-- 08/25/2020 Rajendra K : Added condition AllocatedQty > 0 when calculating the ExcessQty Qty
	+'and exists (SELECT 1 FROM woentry WHERE OPENCLOS not like '''+'C%'+''' and woentry.wono=kamain.wono)   
    ) ExcessQty ' -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list             
             +'WHERE  INVT.STATUS = ''Active'' AND (('''+@inventoryType+''' =''Internal Inventory'' AND '            
             +'('+ CASE WHEN  @searchTerm IS NULL OR @searchTerm = '' THEN ' 1=1 ' ELSE ' invt.Part_No like ''%' + @searchTerm + '%''' END +') AND invt.PART_SOURC <> ''CONSG'') '             
             +' OR ('''+@inventoryType+''' =''CONSG Part No'' AND ('+ CASE WHEN  @searchTerm IS NULL OR @searchTerm = '' THEN ' 1=1 ' ELSE ' invt.CUSTPARTNO like  ''%' + @searchTerm + '%''' END +') AND invt.PART_SOURC = ''CONSG'')) '            
             +' AND ('+ CASE WHEN  @uniqKey IS NULL OR @uniqKey = '' THEN ' 1=1) ' ELSE 'invt.UNIQ_KEY  IN (SELECT id from dbo.[fn_simpleVarcharlistToTable]('''+@uniqKey+''','','')))' END +''            
        
    --+'ORDER BY ' + @sortExpression +' '            
    -- Nitesh B 1/14/2018 Removed the offset      
    --+ 'OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  '            
    --+ 'FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'             
    END                    
   ELSE IF(@inventoryType ='Manufacturer Part No' OR @inventoryType ='Mfgr Part Number')   -- Shivshankar P :  10/11/17 Changed the resourceKey for 'Mfgr Part Number' to 'Manufacturer Part No'            
    BEGIN              
     -- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows      
  --SET @rowCount =(SELECT COUNT(1) FROM INVENTOR  invt LEFT JOIN               
  --          PARTTYPE prt ON  invt.PART_TYPE = prt.PART_TYPE and invt.PART_CLASS  =prt.PART_CLASS             
  --          LEFT JOIN InvtMPNLink  ON  InvtMPNLink.uniq_key = invt.UNIQ_KEY and InvtMPNLink.is_deleted  =0               
  --           LEFT JOIN CUSTOMER  ON CUSTOMER.CUSTNO = invt.CUSTNO            
  --          LEFT JOIN MfgrMaster  ON  MfgrMaster.MfgrMasterId = InvtMPNLink.MfgrMasterId              
  --          OUTER APPLY (SELECT SUM(Qty_Oh) AS OnHand,SUM(RESERVED) AS Allocated ,SUM(Qty_Oh) - SUM(RESERVED) AS Available             
  --                       FROM INVTMFGR WHERE INVTMFGR.UNIQ_KEY = invt.UNIQ_KEY GROUP BY INVTMFGR.UNIQ_KEY) invtmf              
  --          OUTER APPLY (SELECT SUM(Qty_rec) AS ReceivingQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY        
  -- AND ((receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 0 AND receiverDetail.isinspCompleted = 0)       
  -- OR (receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted = 1))             
  --          GROUP BY receiverDetail.UNIQ_KEY) received  -- Mahesh B: 11/29/2018 added the InspectionQty column            
  --          OUTER APPLY (SELECT SUM(Qty_rec) AS InspectionQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY  and receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1  AND receiverDetail.isinspCompleted=0            
  --          GROUP BY receiverDetail.UNIQ_KEY) inspection  -- Mahesh B: 11/29/2018 added the InspectionQty column                 
  --          OUTER APPLY (SELECT TOP 1 DATE AS Date  FROM INVT_ISU WHERE INVT_ISU.UNIQ_KEY = invt.UNIQ_KEY  ORDER BY date) invtisu              
  --          OUTER APPLY (SELECT (SUM(poit.ORD_QTY) - SUM(poit.ACPT_QTY)) AS RemainingBalance FROM POITEMS poit             
  --                       JOIN  POMAIN PO ON poit.PONUM = PO.PONUM  WHERE poit.UNIQ_KEY = invt.UNIQ_KEY             
  --              AND PO.POSTATUS   = 'OPEN' AND poit.LCANCEL = 0  GROUP BY poit.UNIQ_KEY) poitem   -- Shivshankar P :  14/06/17 POitem which are not POSTATUS (CLOSED,NEW)         
  --        WHERE  MfgrMaster.mfgr_pt_no  like  '%'+ @searchTerm + '%'  AND  invt.PART_SOURC <> 'CONSG'             
  --           AND ((@uniqKey <> ' ' AND  invt.UNIQ_KEY  IN             
  --                (SELECT id from dbo.[fn_simpleVarcharlistToTable](@uniqKey,','))) OR  (@uniqKey = ' '  AND invt.UNIQ_KEY =invt.UNIQ_KEY))              
  --             )           
    -- Nitesh B : 12/11/2018 : Fixed the issue for inactive and Mfgr search not working         
        
 IF @searchTerm <> ''         
     BEGIN        
      -- Nitesh B 1/22/2019 : get the part uniqKeys based on mfgr search      
       SELECT DISTINCT INVENTOR.UNIQ_KEY INTO #TempTable FROM INVENTOR      
       JOIN  InvtMPNLink ON INVENTOR.uniq_key = InvtMPNLink.uniq_key and InvtMPNLink.is_deleted = 0 AND INVENTOR.PART_SOURC <> 'CONSG'      
       JOIN MfgrMaster ON InvtMPNLink.MfgrMasterId = MfgrMaster.MfgrMasterId AND MfgrMaster.is_deleted = 0      
       WHERE MfgrMaster.mfgr_pt_no like '%' + @searchTerm + '%'      
      
     -- Shivshankar P 1/28/2019 :   Removed Space from COALESCE      
     SELECT @uniqKey = COALESCE(@uniqKey + ',', '') + uniq_key FROM #TempTable        
          
  -- 04/20/2020 Shivshankar P : Remove Insert Records into Temp table and modify dynamic SQL to get records        
  SET @sqlQuery = 'SELECT CASE WHEN invt.REVISION <> '''' THEN  RTRIM(invt.Part_No)  + ''/''+ LTRIM(invt.REVISION) ELSE invt.Part_No END Part_No           
         ,invt.Revision, invt.Part_Class, invt.Part_Type,             
          RTRIM(invt.PART_CLASS) +''/'' + RTRIM(invt.PART_TYPE) +''/'' + RTRIM(invt.DESCRIPT) Descript, invt.U_Of_Meas, invt.ITAR, invt.Part_Sourc, prt.LOTDETAIL, invtmf.OnHand               
         ,invtmf.Allocated, (invtmf.Available + ISNULL(ExcessQty.addqty,0.00)) AS Available,ISNULL(invtmf.Available,0.00) AS StockAvail,ISNULL(ExcessQty.addqty,0.00) AS ExtraKittedQty, inspection.InspectionQty ' -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list 
		 -- 09/17/2020 Shivshankar P : Added StockAvail column in #tempData table and selection list
		 -- Mahesh B: 11/29/2018 added the InspectionQty column              
         +',received.ReceivingQty,  BuyerAction.BuyerActionQty, invtisu.Date, poitem.RemainingBalance, invt.Serialyes, invt.useipkey         
          ,invt.Pur_Uofm, invt.Package, invt.Matltype, invt.Eau, invt.Status, invt.Scrap, invt.Setupscrap, invt.Uniq_Key, invt.Taxable, invt.Lastchangeinit '  -- Shivshankar P :  25/04/17 Added Taxable and LASTCHANGEINIT column            
         +',MAKE_BUY MakeBuy'  -- Shivshankar P :  26/09/17 Removed 'totalCount' to Taking to much Time created Seprate Query to COUNT and added 'MAKE_BUY' column            
         +',Custpartno,Custrev,   '-- Shivshankar P :  10/03/17 Added Column Custpartno,Custrev             
         +'AspnetBuyer,   '-- Shivshankar P :  10/11/17 Added Column AspnetBuyer            
         +'CustName,   '-- Shivshankar P :  11/07/17 Added Column CustName                         
         -- DastanT :  27/08/20 Added Revision check   
         ---+'CASE WHEN invt.CUSTPARTNO <> '''' THEN  CASE WHEN invt.CUSTPARTNO <> '''' THEN RTRIM(invt.CUSTPARTNO) + ''/''+ RTRIM(invt.CUSTREV) '              
          +'CASE WHEN invt.CUSTPARTNO <> '''' THEN  CASE WHEN invt.CUSTPARTNO <> '''' AND RTRIM(ISNULL(invt.CUSTREV,''''))<>'''' THEN RTRIM(invt.CUSTPARTNO) + ''/''+ RTRIM(invt.CUSTREV) '               
         +' ELSE  invt.CUSTPARTNO END '            
         +' ELSE invt.CUSTREV END CustomPartRev, '-- Shivshankar P :  11/09/17 Added Column CustName ,CustomPartRev     -- Nitesh B : 12/11/2018 : Fixed the issue for inactive and Mfgr search not working          
         +'INT_UNIQ '            
         +' FROM INVENTOR  invt LEFT JOIN               
          PARTTYPE prt ON  invt.PART_TYPE = prt.PART_TYPE and invt.PART_CLASS = prt.PART_CLASS             
          --  LEFT JOIN InvtMPNLink  ON  InvtMPNLink.uniq_key = invt.UNIQ_KEY and InvtMPNLink.is_deleted  =0               
          LEFT JOIN CUSTOMER  ON CUSTOMER.CUSTNO = invt.CUSTNO            
          --  LEFT JOIN MfgrMaster  ON  MfgrMaster.MfgrMasterId = InvtMPNLink.MfgrMasterId              
          OUTER APPLY (SELECT SUM(Qty_Oh) AS OnHand,SUM(RESERVED) AS Allocated ,SUM(Qty_Oh) - SUM(RESERVED) AS Available ,UNIQ_KEY            
             FROM INVTMFGR WHERE INVTMFGR.UNIQ_KEY = invt.UNIQ_KEY GROUP BY INVTMFGR.UNIQ_KEY) invtmf              
          OUTER APPLY (SELECT SUM(Qty_rec) AS ReceivingQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY  AND       
                       ((receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 0 AND receiverDetail.isinspCompleted = 0) OR       
                       (receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted = 1))) received '  -- Mahesh B: 11/29/2018 added the InspectionQty column            
         +'OUTER APPLY (SELECT (SUM(FailedQty) - SUM(ReturnQty) - SUM(Buyer_Accept)) AS BuyerActionQty FROM inspectionHeader       
                        WHERE receiverDetId IN (SELECT receiverDetId FROM receiverDetail WHERE UNIQ_KEY = invt.UNIQ_KEY GROUP BY receiverDetail.receiverDetId)) BuyerAction   '  -- Nitesh B: 7/30/2019 added the BuyerActionQty column      
         +'OUTER APPLY (SELECT SUM(Qty_rec) AS InspectionQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY        
                        AND receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted=0 GROUP       
                        BY receiverDetail.UNIQ_KEY) inspection             
          OUTER APPLY (SELECT TOP 1 DATE AS Date  FROM INVT_ISU WHERE INVT_ISU.UNIQ_KEY = invt.UNIQ_KEY  ORDER BY date) invtisu              
          OUTER APPLY (SELECT (SUM(poit.ORD_QTY) - SUM(poit.ACPT_QTY)) AS RemainingBalance FROM POITEMS poit             
                      JOIN  POMAIN PO ON poit.PONUM = PO.PONUM  WHERE poit.UNIQ_KEY = invt.UNIQ_KEY '            
         +'AND PO.POSTATUS   = ''OPEN'' AND poit.LCANCEL = 0  GROUP BY poit.UNIQ_KEY) poitem  ' -- Shivshankar P :  14/06/17 POitem which are not POSTATUS (CLOSED,NEW)            
   +' OUTER APPLY (  
    SELECT ABS(sum(shortqty)) as addqty   
    FROM kamain WHERE invtmf.UNIQ_KEY=kamain.UNIQ_KEY and invtmf.OnHand<>0  and SHORTQTY<0 AND allocatedQty > 0 '
	-- 08/25/2020 Rajendra K : Added condition AllocatedQty > 0 when calculating the ExcessQty Qty
	+'and exists (SELECT 1 FROM woentry WHERE OPENCLOS not like '''+'C%'+''' and woentry.wono=kamain.wono)   
    ) ExcessQty ' -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list             
         + ' WHERE  '            
                
   -- +'('+ CASE WHEN  @searchTerm IS NULL OR @searchTerm = '' THEN ' 1=1 ' ELSE ' MfgrMaster.mfgr_pt_no like ''%' + @searchTerm + '%''' END +') AND invt.PART_SOURC <> ''CONSG'' '             
            -- Nitesh B 1/22/2019 : Remove the search term condition for Distinct part      
            -- Nitesh B 1/22/2019 : Remove join for Distinct part      
            -- Nitesh B : 8/19/2019 : Remove repeated CASE for get "Manufacturer Part No"          
            -- Rajendra K : 05/06/2019 : Added condition when search type = "Manufacturer Part No" and @searchTerm Not Exists      
         +'('+ CASE WHEN  @uniqKey IS NULL OR @uniqKey = '' THEN CASE WHEN  @searchTerm IS NOT NULL OR @searchTerm != '' THEN ' 0=1) ' ELSE ' 1=1) ' END      
               ELSE 'invt.UNIQ_KEY  IN (SELECT id from dbo.[fn_simpleVarcharlistToTable]('''+@uniqKey+''','','')))' END +''            
            
          --+'ORDER BY ' + @sortExpression +' '            
          -- Nitesh B 1/14/2018 Removed the offset      
          --+ 'OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  '            
          --+ 'FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'            
          -- Nitesh B : 12/06/2018 : Fixed the issue with offset for inactive parts and MPN search          
     END        
    ELSE       
     BEGIN     
  -- 04/20/2020 Shivshankar P : Remove Insert Records into Temp table and modify dynamic SQL to get records       
        SET @sqlQuery = 'SELECT CASE WHEN invt.REVISION <> '''' THEN  RTRIM(invt.Part_No)  + ''/''+ LTRIM(invt.REVISION) ELSE invt.Part_No END Part_No            
         ,invt.Revision, invt.Part_Class, invt.Part_Type,             
          RTRIM(invt.PART_CLASS) +''/'' + RTRIM(invt.PART_TYPE) +''/'' + RTRIM(invt.DESCRIPT) Descript, invt.U_Of_Meas, invt.ITAR, invt.Part_Sourc, prt.LOTDETAIL, invtmf.OnHand               
         ,invtmf.Allocated, (invtmf.Available + ISNULL(ExcessQty.addqty,0.00)) AS Available,ISNULL(invtmf.Available,0.00) AS StockAvail,ISNULL(ExcessQty.addqty,0.00) AS ExtraKittedQty, inspection.InspectionQty '  -- Mahesh B: 11/29/2018 added the InspectionQty column            
         -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list  
		 -- 09/17/2020 Shivshankar P : Added StockAvail column in #tempData table and selection list
   +',received.ReceivingQty, BuyerAction.BuyerActionQty, invtisu.Date, poitem.RemainingBalance, invt.Serialyes, invt.useipkey               
          ,invt.Pur_Uofm, invt.Package, invt.Matltype, invt.Eau, invt.Status, invt.Scrap, invt.Setupscrap, invt.Uniq_Key, invt.Taxable, invt.Lastchangeinit'  -- Shivshankar P :  25/04/17 Added Taxable and LASTCHANGEINIT column            
         +',MAKE_BUY MakeBuy'  -- Shivshankar P :  26/09/17 Removed 'totalCount' to Taking to much Time created Seprate Query to COUNT and added 'MAKE_BUY' column            
         +',Custpartno,Custrev,' -- Shivshankar P :  10/03/17 Added Column Custpartno,Custrev             
         +'AspnetBuyer,   '-- Shivshankar P :  10/11/17 Added Column AspnetBuyer            
         +'CustName,   '-- Shivshankar P :  11/07/17 Added Column CustName                         
         --+'CASE WHEN invt.CUSTPARTNO <> '''' THEN  CASE WHEN invt.CUSTPARTNO <> '''' THEN RTRIM(invt.CUSTPARTNO) + ''/''+ RTRIM(invt.CUSTREV) '    
   -- 08/27/2020 Dastan T:      Added Revision check, if Revision is not null add / to CustPartNo column, if null, do not add  
   +'CASE WHEN invt.CUSTPARTNO <> '''' THEN  CASE WHEN invt.CUSTPARTNO <> '''' AND RTRIM(ISNULL(invt.CUSTREV,''''))<>'''' THEN RTRIM(invt.CUSTPARTNO) + ''/''+ RTRIM(invt.CUSTREV) '  -- DastanT :  27/08/20 Added Revision check        
         +' ELSE invt.CUSTPARTNO END '            
         +' ELSE invt.CUSTREV END CustomPartRev, '-- Shivshankar P :  11/09/17 Added Column CustName ,CustomPartRev     -- Nitesh B : 12/11/2018 : Fixed the issue for inactive and Mfgr search not working          
         +'INT_UNIQ '            
         +' FROM INVENTOR  invt LEFT JOIN               
            PARTTYPE prt ON  invt.PART_TYPE = prt.PART_TYPE and invt.PART_CLASS  =prt.PART_CLASS             
            LEFT JOIN CUSTOMER  ON CUSTOMER.CUSTNO = invt.CUSTNO            
            OUTER APPLY (SELECT SUM(Qty_Oh) AS OnHand,SUM(RESERVED) AS Allocated ,SUM(Qty_Oh) - SUM(RESERVED) AS Available,UNIQ_KEY             
                         FROM INVTMFGR WHERE INVTMFGR.UNIQ_KEY = invt.UNIQ_KEY GROUP BY INVTMFGR.UNIQ_KEY) invtmf              
            OUTER APPLY (SELECT SUM(Qty_rec) AS ReceivingQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY  AND      
                        ((receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 0 AND receiverDetail.isinspCompleted = 0) OR       
                        (receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted = 1))) received '  -- Mahesh B: 11/29/2018 added the InspectionQty column                 
         +'OUTER APPLY (SELECT (SUM(FailedQty) - SUM(ReturnQty) - SUM(Buyer_Accept)) AS BuyerActionQty FROM inspectionHeader       
                        WHERE receiverDetId IN (SELECT receiverDetId FROM receiverDetail WHERE UNIQ_KEY = invt.UNIQ_KEY GROUP BY receiverDetail.receiverDetId)) BuyerAction   ' -- Nitesh B: 7/30/2019 added the BuyerActionQty column      
         +'OUTER APPLY (SELECT SUM(Qty_rec) AS InspectionQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY       
                       AND receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted=0 GROUP BY      
                       receiverDetail.UNIQ_KEY) inspection             
           OUTER APPLY (SELECT TOP 1 DATE AS Date  FROM INVT_ISU WHERE INVT_ISU.UNIQ_KEY = invt.UNIQ_KEY  ORDER BY date) invtisu              
           OUTER APPLY (SELECT (SUM(poit.ORD_QTY) - SUM(poit.ACPT_QTY)) AS RemainingBalance FROM POITEMS poit             
                        JOIN  POMAIN PO ON poit.PONUM = PO.PONUM  WHERE poit.UNIQ_KEY = invt.UNIQ_KEY '            
                       +'AND PO.POSTATUS = ''OPEN'' AND poit.LCANCEL = 0  GROUP BY poit.UNIQ_KEY) poitem  ' -- Shivshankar P :  14/06/17 POitem which are not POSTATUS (CLOSED,NEW)            
   +' OUTER APPLY (  
    SELECT ABS(sum(shortqty)) as addqty   
    FROM kamain WHERE invtmf.UNIQ_KEY=kamain.UNIQ_KEY and invtmf.OnHand<>0  and SHORTQTY<0 and allocatedQty > 0 '
	-- 08/25/2020 Rajendra K : Added condition AllocatedQty > 0 when calculating the ExcessQty Qty
	+'and exists (SELECT 1 FROM woentry WHERE OPENCLOS not like '''+'C%'+''' and woentry.wono=kamain.wono)   
    ) ExcessQty ' -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list             
          + ' WHERE  '            
          +'(invt.PART_SOURC <> ''CONSG'' '             
          +'AND '+ CASE WHEN  @uniqKey IS NULL OR @uniqKey = '' THEN ' 1=1) ' ELSE 'invt.UNIQ_KEY  IN (SELECT id from dbo.[fn_simpleVarcharlistToTable]('''+@uniqKey+''','','')))' END +''            
              
    --+'ORDER BY ' + @sortExpression +' '            
          -- Nitesh B 1/14/2018 Removed the offset      
          --+ 'OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  '            
          --+ 'FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'            
          -- Nitesh B : 12/06/2018 : Fixed the issue with offset for inactive parts and MPN search          
      END        
     END                 
    ELSE IF(@inventoryType ='Inactive Parts')              
     BEGIN                    
  -- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows      
  --   SET @rowCount =(            
  --   SELECT COUNT(1) FROM INVENTOR  invt LEFT JOIN               
  --           PARTTYPE prt ON  invt.PART_TYPE = prt.PART_TYPE and invt.PART_CLASS  =prt.PART_CLASS                
  --            LEFT JOIN CUSTOMER  ON CUSTOMER.CUSTNO = invt.CUSTNO            
  --           OUTER APPLY (SELECT SUM(Qty_Oh)   AS OnHand,SUM(RESERVED) AS Allocated ,SUM(Qty_Oh) - SUM(RESERVED) AS Available  FROM INVTMFGR WHERE INVTMFGR.UNIQ_KEY = invt.UNIQ_KEY GROUP BY INVTMFGR.UNIQ_KEY) invtmf              
  --           OUTER APPLY (SELECT SUM(Qty_rec)   AS ReceivingQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY   AND ((receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 0 AND receiverDetail.isinspCompleted = 0)      
  --      OR (receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted = 1))             
  --           GROUP BY receiverDetail.UNIQ_KEY) received   -- Mahesh B: 11/29/2018 added the InspectionQty column            
  --           OUTER APPLY (SELECT SUM(Qty_rec) AS InspectionQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY  AND receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1            
  --            GROUP BY receiverDetail.UNIQ_KEY) inspection   -- Mahesh B: 11/29/2018 added the InspectionQty column            
  --           OUTER APPLY (SELECT TOP 1 DATE AS Date  FROM INVT_ISU WHERE INVT_ISU.UNIQ_KEY = invt.UNIQ_KEY  ORDER BY date) invtisu              
  --           OUTER APPLY (SELECT (SUM(poit.ORD_QTY) - SUM(poit.ACPT_QTY)) AS RemainingBalance FROM POITEMS poit JOIN  POMAIN PO ON poit.PONUM = PO.PONUM  WHERE poit.UNIQ_KEY = invt.UNIQ_KEY  AND PO.POSTATUS   = 'OPEN' AND poit.LCANCEL = 0              
  --            GROUP BY poit.UNIQ_KEY) poitem  -- Shivshankar P :  14/06/17 POitem which are not POSTATUS (CLOSED,NEW)            
  --        WHERE invt.PART_NO like '%' + @searchTerm + '%' AND  INVT.STATUS = 'Inactive'    -- Shivshankar P :  10/11/17 When @inventoryType='Inactive Parts' get only Inactive parts                          
  --          AND ((@uniqKey <> ' ' AND  invt.UNIQ_KEY  IN             
  --                   (SELECT id from dbo.[fn_simpleVarcharlistToTable](@uniqKey,','))) OR  (@uniqKey = ' '  AND invt.UNIQ_KEY =invt.UNIQ_KEY)))    
      
   -- 04/20/2020 Shivshankar P : Remove Insert Records into Temp table and modify dynamic SQL to get records              
      SET @sqlQuery = ' SELECT CASE WHEN invt.Revision <> '''' THEN  RTRIM(invt.Part_No)  + ''/''+ LTRIM(invt.REVISION) ELSE invt.Part_No END Part_No, invt.Revision, invt.Part_Class,            
                       invt.Part_Type,  RTRIM(invt.PART_CLASS) +''/'' + RTRIM(invt.PART_TYPE) +''/'' + RTRIM(invt.DESCRIPT) Descript, invt.U_Of_Meas, invt.ITAR, invt.Part_Sourc, prt.LOTDETAIL,            
                       invtmf.OnHand ,invtmf.Allocated   ,(invtmf.Available + ISNULL(ExcessQty.addqty,0.00)) AS Available,ISNULL(invtmf.Available,0.00) AS StockAvail,ISNULL(ExcessQty.addqty,0.00) AS ExtraKittedQty,inspection.InspectionQty '  -- Mahesh B: 11/29/2018 added the InspectionQty column            
                     -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list 
					 -- 09/17/2020 Shivshankar P : Added StockAvail column in #tempData table and selection list
       +', received.ReceivingQty, BuyerAction.BuyerActionQty, invtisu.Date, poitem.RemainingBalance,      
                       invt.Serialyes, invt.useipkey ,invt.Pur_Uofm ,invt.Package,invt.Matltype,invt.Eau,invt.Status,invt.Scrap,invt.Setupscrap ,             
                       invt.Uniq_Key  ,invt.Taxable ,invt.Lastchangeinit  '-- Shivshankar P :  25/04/17 Added Taxable and LASTCHANGEINIT column            
                      +',MAKE_BUY MakeBuy'-- Shivshankar P :  26/09/17 Removed 'totalCount' to Taking to much Time created Seprate Query to COUNT and added 'MAKE_BUY' column            
                      +',Custpartno,Custrev,   '-- Shivshankar P :  10/03/17 Added Column Custpartno,Custrev             
                      +'AspnetBuyer,   '-- Shivshankar P :  10/11/17 Added Column AspnetBuyer            
                      +'CustName,   '-- Shivshankar P :  11/07/17 Added Column CustName                         
                      -- DastanT :  27/08/20 Added Revision check   
      ---+'CASE WHEN invt.CUSTPARTNO <> '''' THEN  CASE WHEN invt.CUSTPARTNO <> '''' THEN RTRIM(invt.CUSTPARTNO) + ''/''+ RTRIM(invt.CUSTREV) '     
       +'CASE WHEN invt.CUSTPARTNO <> '''' THEN  CASE WHEN invt.CUSTPARTNO <> '''' AND RTRIM(ISNULL(invt.CUSTREV,''''))<>'''' THEN RTRIM(invt.CUSTPARTNO) + ''/''+ RTRIM(invt.CUSTREV) '               
                      +' ELSE invt.CUSTPARTNO END '            
                      +' ELSE invt.CUSTREV END CustomPartRev, '-- Shivshankar P :  11/09/17 Added Column CustName ,CustomPartRev    -- Nitesh B : 12/11/2018 : Fixed the issue for inactive and Mfgr search not working          
                      +'INT_UNIQ '            
                      +' FROM INVENTOR  invt LEFT JOIN               
                       PARTTYPE prt ON  invt.PART_TYPE = prt.PART_TYPE and invt.PART_CLASS = prt.PART_CLASS                
                       LEFT JOIN CUSTOMER  ON CUSTOMER.CUSTNO = invt.CUSTNO            
                       OUTER APPLY (SELECT SUM(Qty_Oh)   AS OnHand,SUM(RESERVED) AS Allocated ,SUM(Qty_Oh) - SUM(RESERVED) AS Available,UNIQ_KEY  FROM INVTMFGR WHERE INVTMFGR.UNIQ_KEY = invt.UNIQ_KEY GROUP BY INVTMFGR.UNIQ_KEY) invtmf            
                       OUTER APPLY (SELECT SUM(Qty_rec)   AS ReceivingQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY   AND ((receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 0 AND receiverDetail.isinspCompleted = 0)   
  
      
                                   OR (receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 AND receiverDetail.isinspCompleted = 1))) received '  -- Mahesh B: 11/29/2018 added the InspectionQty column                
                      +'OUTER APPLY (SELECT (SUM(FailedQty) - SUM(ReturnQty) - SUM(Buyer_Accept)) AS BuyerActionQty FROM inspectionHeader       
                                     WHERE receiverDetId IN (SELECT receiverDetId FROM receiverDetail WHERE UNIQ_KEY = invt.UNIQ_KEY GROUP BY receiverDetail.receiverDetId)) BuyerAction   ' -- Nitesh B: 7/30/2019 added the BuyerActionQty column      
                      +'OUTER APPLY (SELECT SUM(Qty_rec) AS InspectionQty FROM receiverDetail WHERE receiverDetail.UNIQ_KEY = invt.UNIQ_KEY  and receiverDetail.isCompleted = 0 AND receiverDetail.isinspReq = 1 GROUP BY receiverDetail.UNIQ_KEY) inspection  
  
       
                        OUTER APPLY (SELECT TOP 1 DATE AS Date  FROM INVT_ISU WHERE INVT_ISU.UNIQ_KEY = invt.UNIQ_KEY  ORDER BY date) invtisu              
                        OUTER APPLY (SELECT (SUM(poit.ORD_QTY) - SUM(poit.ACPT_QTY)) AS RemainingBalance FROM POITEMS poit JOIN  POMAIN PO ON poit.PONUM = PO.PONUM  WHERE poit.UNIQ_KEY = invt.UNIQ_KEY  AND PO.POSTATUS   = ''OPEN'' AND poit.LCANCEL = 0    
  
          
                        GROUP BY poit.UNIQ_KEY) poitem ' -- Shivshankar P :  14/06/17 POitem which are not POSTATUS (CLOSED,NEW)    
      +' OUTER APPLY (  
       SELECT ABS(sum(shortqty)) as addqty   
       FROM kamain WHERE invtmf.UNIQ_KEY=kamain.UNIQ_KEY and invtmf.OnHand<>0  and SHORTQTY<0 and allocatedQty > 0 '
	   -- 08/25/2020 Rajendra K : Added condition AllocatedQty > 0 when calculating the ExcessQty Qty
	   +'and exists (SELECT 1 FROM woentry WHERE OPENCLOS not like '''+'C%'+''' and woentry.wono=kamain.wono)   
       ) ExcessQty ' -- Rajendra K : 02/14/2020 : Added outer apply 'ExcessQty' and changed the Available Qty calculation, ExtraKittedQty column in selection list                     
                      +' WHERE  INVT.STATUS = ''Inactive'' AND '            
                      +'('+ CASE WHEN  @searchTerm IS NULL OR @searchTerm = '' THEN ' 1=1 ' ELSE ' invt.Part_No like ''%' + @searchTerm + '%''' END +') AND invt.PART_SOURC <> ''CONSG'' '             
                      +'AND ('+ CASE WHEN  @uniqKey IS NULL OR @uniqKey = '' THEN ' 1=1) ' ELSE 'invt.UNIQ_KEY  IN (SELECT id from dbo.[fn_simpleVarcharlistToTable]('''+@uniqKey+''','','')))' END +''            
                
     --+'ORDER BY ' + @sortExpression +' '            
              -- Nitesh B 1/14/2018 Removed the offset          
              --+ 'OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  '            
              --+ 'FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'        
              -- Nitesh B : 12/06/2018 : Fixed the issue with offset for inactive parts and MPN search          
     END              
    
  -- 04/20/2020 Shivshankar P : Remove Insert Records into Temp table and modify dynamic SQL to get records    
     --INSERT INTO #tempData EXEC sp_executesql @sqlQuery      
           
    -- Rajendra K : 12/12/2019 : Get filtered data by both @warehouse,@Location and @LotCode and changed condition if @lotcode is empty or @warehouse, @Loctaion is empty      
    IF ((@wareHouse <> '' OR  @location <>'') AND @LotCode <> '')              
     BEGIN      
  -- 04/20/2020 Shivshankar P : Modify SP to improve performance and Created Dynamic query for @wareHouse, @location, @LotCode search    
  SET @sqlQuery = 'SELECT DISTINCT INM.UNIQ_KEY as uniq, Result.* FROM (' + @sqlQuery + ')Result    
      INNER JOIN INVTMPNLINK L  ON Result.Uniq_Key = L.uniq_key              
      INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID                
      INNER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0                
      INNER JOIN WAREHOUS  ON INM.UNIQWH=WAREHOUS.UNIQWH        
      INNER JOIN INVTLOT  ON INVTLOT.W_KEY=INM.W_KEY      
                        WHERE L.IS_DELETED = 0  AND M.IS_DELETED = 0    
      AND LOTCODE LIKE ''%' +@LotCode+'%''     
      AND (('''+ @wareHouse +'''<> ''''' + ' AND ''' + @location +''' = '''' AND  WAREHOUS.WAREHOUSE LIKE ''%' +@wareHouse+'%'')            
                        OR ('''+ @wareHouse +'''<> ''''' + ' AND ''' + @location  +'''<> ''''' +' AND  WAREHOUS.WAREHOUSE LIKE ''%' +@wareHouse+'%''  AND LOCATION LIKE ''%' +@location+'%'')            
                        OR ('''+ @wareHouse +'''= ''''' +' AND ''' + @location  +'''<> ''''' +' AND LOCATION LIKE ''%' +@location+'%'')            
                        OR ('''+ @wareHouse  +'''<> ''''' +' AND ''' + @location  +'''= '''''  +' AND  WAREHOUS.WAREHOUSE LIKE ''%' +@wareHouse+'%''))'      
      
              
    --;WITH warehouseLocLot AS (SELECT DISTINCT INM.UNIQ_KEY as uniq, #tempData.* FROM #tempData     
    -- INNER JOIN INVTMPNLINK L  ON #tempData.Uniq_Key = L.uniq_key              
    --    INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID                
    --    INNER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0                
    --    INNER JOIN WAREHOUS  ON INM.UNIQWH=WAREHOUS.UNIQWH        
    --    INNER JOIN INVTLOT  ON INVTLOT.W_KEY=INM.W_KEY  -- Rajendra K : 01/09/2020 : Changes the join LEFT to INNER with invtlot table if lotcode is  provided and changed the condition      
    --    WHERE LOTCODE LIKE '%' +@LotCode+'%' AND       
    --      ((@wareHouse <> '' AND @location = '' AND  WAREHOUS.WAREHOUSE LIKE '%' +@wareHouse+'%')         
    --     OR (@wareHouse <> '' AND @location  <> '' AND  WAREHOUS.WAREHOUSE LIKE '%' +@wareHouse+'%'  AND LOCATION LIKE '%' +@location+'%')              
    --     OR (@wareHouse = '' AND @location  <> ''  AND LOCATION LIKE '%' +@location+'%')              
    --     OR (@wareHouse  <>  '' AND @location  = ''  AND  WAREHOUS.WAREHOUSE LIKE '%' +@wareHouse+'%'))              
    --     AND L.IS_DELETED = 0  AND M.IS_DELETED = 0)                
                             
    --SELECT * INTO #warehouseLotData FROM warehouseLocLot              
                   
        -- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows      
   SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM (' + @sqlQuery +')a',@filter,@sortExpression,'','Part_No',@startRecord,@endRecord))             
   EXEC sp_executesql @rowCount            
             
    --04/16/2020 Shivshankar P : To improve performance add @lFCInstalled = dbo.fn_IsFCInstalled() and remove from dynamic query    
   IF @lFCInstalled =  1     
   BEGIN        
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 1 AS IsFcInstall FROM (' + @sqlQuery +')a',@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
    EXEC sp_executesql @sqlQuery    
   END    
   ELSE    
   BEGIN    
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 0 AS IsFcInstall FROM (' + @sqlQuery +')a' ,@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
    EXEC sp_executesql @sqlQuery    
   END            
    END       
       
   -- Shivshankar P :  04/11/18 Get filtered data by both warehouse,Location and UDF search  and assigned empty to variable            
   IF ((@wareHouse <> '' OR  @location <>'') AND @LotCode = '')              
    BEGIN    -- Rajendra K : 12/12/2019 : Get filtered data by both @warehouse,@Location and @LotCode and changed condition if @lotcode is empty or @warehouse, @Loctaion is empty          
       -- 04/20/2020 Shivshankar P : Modify SP to improve performance and Created Dynamic query for @wareHouse, @location, @LotCode search    
  SET @sqlQuery = 'SELECT DISTINCT INM.UNIQ_KEY as uniq, Result.* FROM (' + @sqlQuery + ')Result    
                   INNER JOIN INVTMPNLINK L  ON Result.Uniq_Key = L.uniq_key            
                        INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID              
                        INNER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0              
                        INNER JOIN WAREHOUS  ON INM.UNIQWH=WAREHOUS.UNIQWH      
                        WHERE L.IS_DELETED = 0  AND M.IS_DELETED = 0     
      AND ('''+ @wareHouse +'''<> ''''' + ' AND ''' + @location +''' = '''' AND  WAREHOUS.WAREHOUSE LIKE ''%' +@wareHouse+'%'')            
                        OR ('''+ @wareHouse +'''<> ''''' + ' AND ''' + @location  +'''<> ''''' +' AND  WAREHOUS.WAREHOUSE LIKE ''%' +@wareHouse+'%''  AND LOCATION LIKE ''%' +@location+'%'')            
                        OR ('''+ @wareHouse +'''= ''''' +' AND ''' + @location  +'''<> ''''' +' AND LOCATION LIKE ''%' +@location+'%'')            
                        OR ('''+ @LotCode  +'''= '''''  +' AND ''' + @wareHouse  +'''<> ''''' +' AND ''' + @location  +'''= '''''  +' AND  WAREHOUS.WAREHOUSE LIKE ''%' +@wareHouse+'%'')'    
    
     --;WITH warehouseLoc AS (SELECT DISTINCT INM.UNIQ_KEY as uniq, #tempData.* FROM #tempData     
     --    INNER JOIN INVTMPNLINK L  ON #tempData.Uniq_Key = L.uniq_key            
     --       INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID            
     --       INNER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0              
     --       INNER JOIN WAREHOUS  ON INM.UNIQWH=WAREHOUS.UNIQWH             
     --       WHERE               
     --         (@wareHouse <> '' AND @location = '' AND  WAREHOUS.WAREHOUSE LIKE '%' +@wareHouse+'%')    
     --              OR (@wareHouse <> '' AND @location  <> '' AND  WAREHOUS.WAREHOUSE LIKE '%' +@wareHouse+'%'  AND LOCATION LIKE '%' +@location+'%')            
     --        OR (@wareHouse = '' AND @location  <> ''  AND LOCATION LIKE '%' +@location+'%')            
     --        OR (@LotCode  = ''  AND @wareHouse  <>  '' AND @location  = ''  AND  WAREHOUS.WAREHOUSE LIKE '%' +@wareHouse+'%')            
     --                          AND L.IS_DELETED = 0  AND M.IS_DELETED = 0)            
                           
     --SELECT * INTO #warehouseData FROM warehouseLoc            
                 
        -- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows      
   SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM (' + @sqlQuery +')a',@filter,@sortExpression,'','Part_No',@startRecord,@endRecord))             
   EXEC sp_executesql @rowCount            
             
    --04/16/2020 Shivshankar P : To improve performance add @lFCInstalled = dbo.fn_IsFCInstalled() and remove from dynamic query    
   IF @lFCInstalled =  1     
   BEGIN        
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 1 AS IsFcInstall FROM (' + @sqlQuery +')a',@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
    EXEC sp_executesql @sqlQuery    
   END    
   ELSE    
   BEGIN    
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 0 AS IsFcInstall FROM (' + @sqlQuery +')a' ,@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
    EXEC sp_executesql @sqlQuery    
   END          
   END     
                          
    -- Shivshankar P :  04/11/18 Get filtered data by both warehouse,Location and UDF search  and assigned empty to variable            
   IF (@LotCode <> '' AND @wareHouse = '' AND  @location = '')              
     BEGIN  -- Rajendra K : 12/12/2019 : Get filtered data by both @warehouse,@Location and @LotCode and changed condition if @lotcode is empty or @warehouse, @Loctaion is empty            
       -- 04/20/2020 Shivshankar P : Modify SP to improve performance and Created Dynamic query for @wareHouse, @location, @LotCode search    
    SET @sqlQuery = 'SELECT DISTINCT INM.UNIQ_KEY as uniq, Result.* FROM (' + @sqlQuery + ')Result    
      INNER JOIN INVTMPNLINK L  ON Result.Uniq_Key = L.uniq_key            
      INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID              
      INNER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0              
      INNER JOIN INVTLOT  ON INVTLOT.W_KEY=INM.W_KEY      
                        WHERE L.IS_DELETED = 0  AND M.IS_DELETED = 0     
      AND LOTCODE LIKE ''%' +@LotCode+'%'''    
      
    --;WITH lotDetail AS (SELECT DISTINCT INM.UNIQ_KEY as uniq, #tempData.* FROM #tempData     
    --         INNER JOIN INVTMPNLINK L  ON #tempData.Uniq_Key = L.uniq_key            
    --            INNER JOIN MFGRMASTER M ON L.MFGRMASTERID=M.MFGRMASTERID              
    --            INNER JOIN INVTMFGR INM ON L.UNIQMFGRHD=INM.UNIQMFGRHD AND INM.IS_DELETED=0              
    --            INNER JOIN INVTLOT  ON INVTLOT.W_KEY=INM.W_KEY  -- Rajendra K : 01/09/2020 : Changes the join LEFT to INNER with invtlot table if lotcode is  provided and changed the condition      
    --                     WHERE LOTCODE LIKE '%' +@LotCode+'%' AND L.IS_DELETED = 0  AND M.IS_DELETED = 0)            
                           
    --          -- Shivshankar P :  05/15/18 Issue with lot code filter            
    --     SELECT * INTO #lotDetailData FROM lotDetail            
                 
       -- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows         
   SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM (' + @sqlQuery +')a',@filter,@sortExpression,'','Part_No',@startRecord,@endRecord))             
   EXEC sp_executesql @rowCount            
             
    --04/16/2020 Shivshankar P : To improve performance add @lFCInstalled = dbo.fn_IsFCInstalled() and remove from dynamic query    
   IF @lFCInstalled =  1     
   BEGIN        
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 1 AS IsFcInstall FROM (' + @sqlQuery +')a',@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
    EXEC sp_executesql @sqlQuery    
   END    
   ELSE    
   BEGIN    
    SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 0 AS IsFcInstall FROM (' + @sqlQuery +')a' ,@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
    EXEC sp_executesql @sqlQuery    
   END                
   END              
            
   IF (@LotCode = '' AND @wareHouse = '' AND  @location = '')            
     BEGIN            
     -- Shivshankar P 1/25/2019 :  Get the row count after the filter  abd removed the filter from query and used fn_GetDataBySortAndFilters function to get rows      
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM (' + @sqlQuery +')a',@filter,@sortExpression,'','Part_No',@startRecord,@endRecord))             
     EXEC sp_executesql @rowCount            
             
   --04/16/2020 Shivshankar P : To improve performance add @lFCInstalled = dbo.fn_IsFCInstalled() and remove from dynamic query    
  IF @lFCInstalled =  1     
  BEGIN        
   SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 1 AS IsFcInstall FROM (' + @sqlQuery +')a',@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
   EXEC sp_executesql @sqlQuery    
  END    
  ELSE    
     BEGIN    
   SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT *, 0 AS IsFcInstall FROM (' + @sqlQuery +')a' ,@filter,@sortExpression,'Part_No','',@startRecord,@endRecord))            
   EXEC sp_executesql @sqlQuery    
  END            
    END            
 END 