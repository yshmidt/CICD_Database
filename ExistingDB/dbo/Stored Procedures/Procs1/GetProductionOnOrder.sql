
-- =============================================
-- Author:		Mahesh B.	
-- Create date: 09/10/2018 
-- Description:	Get the Production Control On Order Details.
-- 03/14/2019 Mahesh B:-Specified the datatype
-- 03/14/2019 Mahesh B:-Added the column As UniqueId 
-- 03/15/2019 Mahesh B:-Get the result from kamain table
-- 03/22/2019 Mahesh B:-Applied the pagination        
-- exec GetProductionOnOrder '0000000550', 1,150   
 --=============================================
CREATE PROCEDURE [dbo].[GetProductionOnOrder]  
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
					        Part_sourc CHAR(10),PART_NO CHAR(35),Revision CHAR(8),Descript NVARCHAR(MAX),Part_class CHAR(8),  
                            Part_type CHAR(8),U_of_meas CHAR(4),Scrap NUMERIC(6,2),SetupScrap NUMERIC(4,0),CustPartNo CHAR(35),Serialyes BIT,
					        Qty_Each NUMERIC(10,2),UniqueId VARCHAR(10))  --03/14/2019 Mahesh B:- Added the column As UniqueId  

							--03/14/2019 Mahesh B:- Specified the datatype  
  DECLARE @assemblyComponent TABLE (PartNoWithRev VARCHAR(MAX),DESCRIPTION NVARCHAR(MAX),WONO CHAR(10),DEPT_ID CHAR(4),UNIQ_KEY  CHAR(10),BOMPARENT CHAR(10),
									SHORTQTY NUMERIC(12,2),QTY NUMERIC(12,2)) 

  SELECT @kitStaus = KitStatus FROM WOENTRY we WHERE we.WONO=@woNo;  

  IF(@kitStaus ='') 
        SET @isKitPull = 0
  ELSE IF(@kitStaus !='KIT ClOSED' And @kitStaus <>'')
        SET @isKitPull = 1

  IF (@isKitPull = 1)
     BEGIN
     
	      INSERT INTO @assemblyComponent(PartNoWithRev, DESCRIPTION,WONO,DEPT_ID,UNIQ_KEY,BOMPARENT ,SHORTQTY ,QTY )
		  EXEC GetKmainInfo @woNo -- 03/15/2019 Mahesh B:-Get the result from kamain table  
						
      END
	  ELSE IF(@kitStaus = 0)
	      BEGIN
                  INSERT INTO @kitNotPull EXEC KitBomInfoView @woNo

				  Insert INTO @assemblyComponent(PartNoWithRev, DESCRIPTION,WONO,DEPT_ID,UNIQ_KEY,BOMPARENT ,SHORTQTY ,QTY) 
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


          SELECT  assc.DEPT_ID AS WorkCenter,assc.PartNoWithRev,assc.Description,assc.SHORTQTY AS Shortage, Status = 'On Order',
		          Poitschd.balance AS Balance,Poitschd.schd_date As 'SchdWithDock', Supinfo.supname AS Supplier, ap.Initials AS Buyer,
				  REPLACE(LTRIM(REPLACE(Pomain.ponum ,'0',' ')),' ','0') AS PONumber,
				  Poitems.Itemno AS Item,Poitems.partmfgr AS MFGR,
				  Poitems.Mfgr_pt_no AS MFGRPartNo, SupplierPL='', COUNT(1) OVER() AS TotalCount
				  FROM  POITEMS Join POITSCHD on POITSCHD.uniqlnno =  POITEMS.UNIQLNNO
					    JOIN pomain  on Pomain.ponum = Poitems.ponum 
					    JOIN supinfo on Supinfo.uniqsupno = Pomain.uniqsupno  
					    LEFT JOIN aspnet_profile ap on pomain.aspnetBuyer = ap.userid
					    INNER JOIN @assemblyComponent assc ON assc.UNIQ_KEY = Poitems.uniq_key
					    WHERE Poitems.lcancel = 0  
							  AND  Pomain.postatus <> 'CANCEL'  
							  AND  Pomain.postatus <>  'CLOSED'  
							  AND  Poitschd.balance >  0 
							  Order by assc.PartNoWithRev OFFSET
							  @startRecord -1 ROWS FETCH NEXT @endRecord ROWS ONLY; -- 03/22/2019 Mahesh B:-Applied the pagination   
  
END 

