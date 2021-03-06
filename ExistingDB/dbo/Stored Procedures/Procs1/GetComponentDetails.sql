﻿  
-- =============================================  
-- Author:  Mahesh B.   
-- Create date: 09/10/2018   
-- Description: Get the Shoratage information.    
-- 03/14/2019 Mahesh B:- Added the column As UniqueId     
-- 03/14/2019 Mahesh B:- Specified the datatype   
-- Exec GetComponentDetails '0000000847', 1,150  
--07/25/2020 Sachin B Removed unused join with POITSCHD which is duplication records
--07/28/2020 Sachin B Getting those Parts Shortages which are not present on any of the above three Types
-- =============================================  
  
CREATE PROCEDURE [dbo].[GetComponentDetails]  
(  
@woNo AS CHAR(10) = ' ',    
@startRecord int,  
@endRecord int   
)  
AS  
BEGIN  
  
 DECLARE @kitStaus CHAR(10), @isKitPull BIT;  
  
                             --03/14/2019 Mahesh B:- Specified the datatype    
 DECLARE @kitNotPull TABLE (Dept_id CHAR(4), Uniq_key CHAR(10),Bomparent CHAR(10),Qty NUMERIC(12,2),Shortqty NUMERIC(12,2),Used_inKit CHAR(1),  
							Part_sourc CHAR(10),PART_NO CHAR(35),Revision CHAR(8),Descript CHAR(45),Part_class CHAR(8),    
                            Part_type CHAR(8),U_of_meas CHAR(4),Scrap NUMERIC(6,2),SetupScrap NUMERIC(4,0),CustPartNo CHAR(35),Serialyes BIT,  
							Qty_Each NUMERIC(10,2),UniqueId VARCHAR(10))  --03/14/2019 Mahesh B:- Added the column As UniqueId    
  
       --03/14/2019 Mahesh B:- Specified the datatype    
 DECLARE @componentInfo TABLE (WorkCenter VARCHAR(MAX),PartNoWithRev VARCHAR(MAX), DESCRIPTION varchar(MAX),Shortage NUMERIC(12,2),  
                               Status VARCHAR(MAX),Balance NUMERIC(10,2),SchdWithDock smalldatetime,Supplier VARCHAR(MAX),SupplierPL VARCHAR(MAX),   
							   Buyer VARCHAR(MAX),PONumber VARCHAR(MAX), Item VARCHAR(MAX), MFGR VARCHAR(MAX), MFGRPartNo VARCHAR(MAX))   
  
       --03/14/2019 Mahesh B:- Specified the datatype   
 DECLARE @assemblyComponent TABLE (PartNoWithRev VARCHAR(MAX),DESCRIPTION NVARCHAR(MAX),WONO CHAR(10),DEPT_ID CHAR(4),UNIQ_KEY  CHAR(10),BOMPARENT CHAR(10),  
								   SHORTQTY NUMERIC(12,2),QTY NUMERIC(12,2))   
  
        SELECT @kitStaus = KitStatus FROM WOENTRY we WHERE we.WONO=@woNo;    
  
		IF(@kitStaus ='') 
		BEGIN  
			SET @isKitPull = 0 
		END 
		ELSE IF(@kitStaus !='KIT ClOSED' And @kitStaus <>'')  
		BEGIN
			SET @isKitPull = 1  
		END 
  
		IF (@isKitPull = 1)  
		BEGIN  
			INSERT INTO @assemblyComponent(PartNoWithRev, DESCRIPTION,WONO,DEPT_ID,UNIQ_KEY,BOMPARENT ,SHORTQTY ,QTY )  
			EXEC GetKmainInfo @woNo -- 03/15/2019 Mahesh B:-Get the result from kamain table    
		END  
		ELSE IF(@kitStaus = 0)  
		BEGIN  
			INSERT INTO @kitNotPull 
			EXEC KitBomInfoView @woNo 
			 
			INSERT INTO @assemblyComponent(PartNoWithRev, DESCRIPTION,WONO,DEPT_ID,UNIQ_KEY,BOMPARENT ,SHORTQTY ,QTY)     
			SELECT CASE COALESCE(NULLIF(knp.REVISION,''), '')  
			WHEN '' THEN  LTRIM(RTRIM(knp.PART_NO))   
			ELSE LTRIM(RTRIM(knp.PART_NO)) + '/' + knp.REVISION   
			END AS PartNoWithRev,  
			CASE   
			WHEN knp.PART_CLASS IS NOT NULL AND knp.PART_TYPE IS NOT NULL  THEN  LTRIM(RTRIM(knp.PART_CLASS)) + '/' + LTRIM(RTRIM(knp.PART_TYPE)) + '/' +knp.DESCRIPT  
			WHEN knp.PART_CLASS IS NULL AND knp.PART_TYPE IS NOT NULL  THEN  LTRIM(RTRIM(knp.PART_TYPE)) + knp.DESCRIPT  
			WHEN knp.PART_CLASS IS NOT NULL AND knp.PART_TYPE IS NULL  THEN  LTRIM(RTRIM(knp.PART_CLASS)) + knp.DESCRIPT  
			ELSE LTRIM(RTRIM(knp.DESCRIPT))   
				END AS DESCRIPTION,  
			WONO = @woNo,  
			knp.Dept_id,  
			knp.Uniq_key,  
			knp.BomParent,  
			knp.ShortQty,  
			knp.Qty  
			from @kitNotPull knp  
		END  
  
		INSERT INTO  @componentInfo(WorkCenter,PartNoWithRev, DESCRIPTION,Shortage,Status ,Balance,SchdWithDock ,Supplier, SupplierPL,Buyer,  
								PONumber, Item , MFGR , MFGRPartNo)  
		SELECT assc.DEPT_ID AS WorkCenter,assc.PartNoWithRev,assc.Description,assc.SHORTQTY AS Shortage, Status = 'On Dock',  
			rdet.Qty_rec AS Balance,hd.dockDate As 'SchdWithDock', Supinfo.supname AS Supplier, hd.recPklNo AS SupplierPL,  ap.Initials AS Buyer,   
		REPLACE(LTRIM(REPLACE(Pomain.ponum ,'0',' ')),' ','0') AS PONumber,  
		Poitems.Itemno AS Item,rdet.Partmfgr AS MFGR,rdet.Mfgr_pt_no AS MFGRPartNo   
		FROM receiverHeader hd 
		JOIN receiverDetail rdet ON rdet.receiverHdrId=hd.receiverHdrId  
		JOIN POITEMS ON  rdet.uniqlnno =  POITEMS.UNIQLNNO  
		--07/25/2020 Sachin B Removed unused join with POITSCHD which is duplication records
		--JOIN POITSCHD ON POITSCHD.uniqlnno =  POITEMS.UNIQLNNO  
		JOIN pomain  ON Pomain.ponum = Poitems.ponum   
		JOIN supinfo ON Supinfo.uniqsupno = Pomain.uniqsupno    
		LEFT JOIN aspnet_profile ap ON pomain.aspnetBuyer = ap.userid  
		INNER JOIN @assemblyComponent assc ON assc.UNIQ_KEY = rdet.uniq_key  
		WHERE (((rdet.isinspReq = 0 AND rdet.isinspCompleted = 0) OR (rdet.isinspReq = 1 AND rdet.isinspCompleted = 1)) AND isCompleted=0)  
  
        --Insert inspection data
		INSERT INTO  @componentInfo(WorkCenter,PartNoWithRev, DESCRIPTION,Shortage,Status ,Balance,SchdWithDock ,Supplier,SupplierPL,Buyer,  
									PONumber, Item , MFGR , MFGRPartNo)  
		SELECT assc.DEPT_ID AS WorkCenter,assc.PartNoWithRev,assc.Description,assc.SHORTQTY AS Shortage, Status = 'In Inspection',  
		rdet.Qty_rec AS Balance,hd.dockDate As 'SchdWithDock', Supinfo.supname AS Supplier , hd.recPklNo AS SupplierPL ,ap.Initials AS Buyer,  
		REPLACE(LTRIM(REPLACE(Pomain.ponum ,'0',' ')),' ','0') AS PONumber,  
		Poitems.Itemno AS Item,rdet.Partmfgr AS MFGR,rdet.Mfgr_pt_no AS MFGRPartNo   
		FROM receiverHeader hd 
		JOIN receiverDetail rdet on rdet.receiverHdrId=hd.receiverHdrId  
		JOIN POITEMS ON  rdet.uniqlnno =  POITEMS.UNIQLNNO  
		--07/25/2020 Sachin B Removed unused join with POITSCHD which is duplication records
		--JOIN POITSCHD ON POITSCHD.uniqlnno =  POITEMS.UNIQLNNO  
		JOIN pomain  ON Pomain.ponum = Poitems.ponum   
		JOIN supinfo ON Supinfo.uniqsupno = Pomain.uniqsupno    
		LEFT JOIN aspnet_profile ap ON pomain.aspnetBuyer = ap.userid  
		INNER JOIN @assemblyComponent assc ON assc.UNIQ_KEY = rdet.uniq_key  
		WHERE rdet.isinspReq = 1 AND rdet.isinspCompleted = 0   
        
		--Insert On Order Data         
		INSERT INTO  @componentInfo(WorkCenter,PartNoWithRev, DESCRIPTION,Shortage,Status ,Balance,SchdWithDock ,Supplier,SupplierPL,Buyer,  
								PONumber, Item , MFGR , MFGRPartNo)  
		SELECT  assc.DEPT_ID AS WorkCenter,assc.PartNoWithRev,assc.Description,assc.SHORTQTY AS Shortage, Status = 'On Order',  
		Poitschd.balance AS Balance,Poitschd.schd_date AS 'SchdWithDock', Supinfo.supname AS Supplier,SupplierPL='',   
		ap.Initials AS Buyer, REPLACE(LTRIM(REPLACE(Pomain.ponum ,'0',' ')),' ','0') AS PONumber,  
		Poitems.Itemno AS Item,Poitems.partmfgr AS MFGR,Poitems.Mfgr_pt_no AS MFGRPartNo   
		FROM  POITEMS 
		Join POITSCHD ON POITSCHD.uniqlnno =  POITEMS.UNIQLNNO  
		JOIN pomain  ON Pomain.ponum = Poitems.ponum   
		JOIN supinfo ON Supinfo.uniqsupno = Pomain.uniqsupno    
		LEFT JOIN aspnet_profile ap ON pomain.aspnetBuyer = ap.userid  
		INNER JOIN @assemblyComponent assc ON assc.UNIQ_KEY = Poitems.uniq_key  
		WHERE Poitems.lcancel = 0    
		AND  Pomain.postatus <> 'CANCEL'    
		AND  Pomain.postatus <>  'CLOSED'    
		AND  Poitschd.balance >  0  
		
		--07/28/2020 Sachin B Getting those Parts Shortages which are not present on any of the above three Types
		INSERT INTO  @componentInfo(WorkCenter,PartNoWithRev, DESCRIPTION,Shortage,Status ,Balance,SchdWithDock ,Supplier,SupplierPL,Buyer,  
								PONumber, Item , MFGR , MFGRPartNo)  
		SELECT  assc.DEPT_ID AS WorkCenter,assc.PartNoWithRev,assc.Description,assc.SHORTQTY AS Shortage, Status = '',  
	    0 AS Balance,NULL AS 'SchdWithDock', '' AS Supplier,SupplierPL='','' AS Buyer, '' AS PONumber,0 AS Item,'' AS MFGR,'' AS MFGRPartNo   
		FROM  @assemblyComponent assc 
		WHERE assc.PartNoWithRev NOT IN (SELECT PartNoWithRev FROM @componentInfo) 		 
     
     SELECT *, COUNT(1) OVER() AS TotalCount  
	 FROM @componentInfo t  
	 ORDER BY t.PartNoWithRev OFFSET @startRecord -1 ROWS FETCH NEXT @endRecord ROWS ONLY;  
END   
  
  