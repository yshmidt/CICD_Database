
-- =============================================
-- Author:		Mahesh B.	
-- Create date: 09/10/2018 
-- Description:	Get On Dock Information.
-- 03/14/2019 Mahesh B:- Specified the datatype
-- 03/14/2019 Mahesh B:- Added the column As UniqueId 
-- 03/15/2019 Mahesh B:-Get the result from kamain table  
-- exec GetProductionOnDock '0000000550', 1,150        
-- =============================================
CREATE PROCEDURE [dbo].[GetProductionOnDock]  
(  
@woNo AS CHAR(10) = ' ',  
@startRecord int,
@endRecord int 
)  
AS  
BEGIN  
  
  DECLARE @kitStaus CHAR(10),@isKitPull BIT; 

                              --03/14/2019 Mahesh B:- Specified the datatype  
  DECLARE @kitNotPull TABLE (Dept_id CHAR(4), Uniq_key CHAR(10),Bomparent CHAR(10),Qty NUMERIC(12,2),Shortqty NUMERIC(12,2),Used_inKit CHAR(1),
					        Part_sourc CHAR(10),PART_NO CHAR(35),Revision CHAR(8),Descript CHAR(45),Part_class CHAR(8),  
                            Part_type CHAR(8),U_of_meas CHAR(4),Scrap NUMERIC(6,2),SetupScrap NUMERIC(4,0),CustPartNo CHAR(35),Serialyes BIT,
					        Qty_Each NUMERIC(10,2),UniqueId VARCHAR(10))  --03/14/2019 Mahesh B:- Added the column As UniqueId  

 							--03/14/2019 Mahesh B:- Specified the datatype  
  DECLARE @assemblyComponent TABLE (PartNoWithRev VARCHAR(MAX),DESCRIPTION NVARCHAR(MAX),WONO CHAR(10),DEPT_ID CHAR(4),UNIQ_KEY CHAR(10),BOMPARENT CHAR(10),
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


       SELECT  assc.DEPT_ID AS WorkCenter,assc.PartNoWithRev,assc.Description,assc.SHORTQTY AS Shortage, Status = 'On Dock',rdet.Qty_rec AS Balance,hd.dockDate As 'SchdWithDock', Supinfo.supname AS Supplier, ap.Initials AS Buyer, 
	           REPLACE(LTRIM(REPLACE(Pomain.ponum ,'0',' ')),' ','0') AS PONumber,Poitems.Itemno AS Item,rdet.Partmfgr AS MFGR,
			   rdet.Mfgr_pt_no AS MFGRPartNo, hd.recPklNo AS SupplierPL, COUNT(1) OVER() AS TotalCount
			   FROM receiverHeader hd JOIN receiverDetail rdet ON rdet.receiverHdrId=hd.receiverHdrId
				   JOIN POITEMS ON  rdet.uniqlnno =  POITEMS.UNIQLNNO
				   JOIN POITSCHD ON POITSCHD.uniqlnno =  POITEMS.UNIQLNNO
				   JOIN pomain  ON Pomain.ponum = Poitems.ponum 
				   JOIN supinfo ON Supinfo.uniqsupno = Pomain.uniqsupno  
				   LEFT JOIN aspnet_profile ap ON pomain.aspnetBuyer = ap.userid
				   INNER JOIN @assemblyComponent assc ON assc.UNIQ_KEY = rdet.uniq_key
				   WHERE (((rdet.isinspReq = 0 AND rdet.isinspCompleted = 0) OR 
						  (rdet.isinspReq = 1 AND rdet.isinspCompleted = 1)) AND isCompleted=0)
                        ORDER BY assc.PartNoWithRev OFFSET @startRecord -1 ROWS FETCH NEXT @endRecord ROWS ONLY;
END 





