-- =============================================    
-- Author:Shrikant B  
-- Create date: 11/22/2018    
-- Description: Get SID detail based on unique key and ware house key if item is Used in SID and is Serialized and lotted    
--  01/25/2019 Shrikant modify AllocatedQty same as pkgbalance for sfbl type warehouse sid
--  01/28/2019 Shrikant Added sfbl column for getting available qty same as shipping qty of only of sfbl type warehouse 
--  01/28/2019 Shrikant Added Join for getting sfbl column of invtmfgr
--  07/30/2019  Sachin B Fixed the issue of sid not getting data for null expression date
-- 	08/08/2019 Sachin B Added Join pldtlipkey and pldetail to get shipped sid information
--  08/08/2019 Sachin B modify the where condition to get Shipped SID information
--  09/08/2019 Sachin B Add where condition to SID: In the SFBL warehouse MTC show only those MTC which are shipped in PL No
-- 	08/09/2019 Sachin B Added Join pldtlipkeyConsignWh and  pldetailConsign to get shipped sid information of sfbl warehouse
-- 	08/09/2019 Sachin B filter sfbl warehouse by PACKLISTNO
--  08/12/2019  Sachin B Modify the package balance to showing only specific packing list sid  
--  08/29/2019 Sachin B Added column originalPkgQty for reverse qty validation  
-- GetSIDDetailByUniqKey '_1ED0O2FS5', '_1ED0O2FSC', '0000000842', '_57W058RFV' 
-- GetSIDDetailByUniqKey 'LY7H9JTNQR', '69WJEB2HVN', '', '_5P40XB4MM'
/* used for SID ,serialized and lotted*/    
-- =============================================    
CREATE PROCEDURE GetSIDDetailByUniqKey      
 @uniqKey AS char(10),    
 @wKey AS CHAR(10),     
 @packnumber AS CHAR(10)='',     
 @uniqueLnNo AS CHAR(10)=''     
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON 

  DECLARE @isSFBLWh BIT=0;
  SET  @isSFBLWh = (SELECT SFBL FROM INVTMFGR WHERE W_KEY=@wKey)

;WITH SIDData AS( SELECT DISTINCT    
	   ipkey.IpKeyUnique      
--  08/12/2019  Sachin B Modify the package balance to showing only specific packing list sid   
    --,(ipkey.pkgbalance-ipkey.qtyAllocatedTotal) As pkgbalance     
     ,CASE WHEN (@isSFBLWh = 1) THEN pldtlipkeyConsignWh.NSHPQTY   ELSE   (ipkey.pkgbalance-ipkey.qtyAllocatedTotal) END AS pkgbalance        
	   ,ipkey.pkgbalance AS OldPkgBalance  
	   ,0 As AllocatedQty    
	   ,0 As OldAllocatedQty    
	   ,(ipkey.pkgbalance-ipkey.qtyAllocatedTotal) As TotalPkgBalance     
	   ,ipkey.UNIQ_KEY    
	   ,ipkey.W_KEY    
	   ,i.SERIALYES    
	   ,ipkey.LOTCODE     
	   ,ipkey.REFERENCE     
	   ,ipkey.EXPDATE    
	   ,ipkey.PONUM      
	   , uniqLot=ISNULL( 
	   (
			SELECT TOP 1  UNIQ_LOT from INVTLOT 
			--  07/30/2019  Sachin B Fixed the issue of sid not getting data for null expression date
			WHERE LOTCODE=ipkey.LOTCODE AND REFERENCE=ipkey.REFERENCE AND ISNULL(EXPDATE,'')=ISNULL(ipkey.EXPDATE,'')      
			AND PONUM=Ipkey.PONUM AND W_KEY= @wKey ),Space(10)
	   )    
	   -- ,pldetailConsign.PACKLISTNO AS PackListNo 
	   ,CASE WHEN @packnumber = '' THEN 0 ELSE  pldetailConsign.PACKLISTNO END  AS PackListNo    
	   ,'' AS UNIQUELN
	   --  01/28/2019 Shrikant Added sfbl column for getting available qty same as shipping qty of only of sfbl type warehouse 
	   , invtmfgr.SFBL
	   --  08/29/2019 Sachin B Added column originalPkgQty for reverse qty validation  
	   ,ipkey.originalPkgQty   
	   FROM IPKEY ipkey        
	   INNER JOIN inventor i ON i.UNIQ_KEY = ipkey.UNIQ_KEY
	   --  01/28/2019 Shrikant Added Join for getting sfbl column of invtmfgr 
	   INNER JOIN INVTMFGR invtmfgr ON invtmfgr.W_KEY = ipkey.W_KEY    
		-- 	08/08/2019 Sachin B Added Join pldtlipkey and pldetail to get shipped sid information
		LEFT JOIN PLDTLIPKEY pldtlipkey ON ipKey.IPKEYUNIQUE = pldtlipkey.FK_IPKEYUNIQUE 
		LEFT JOIN PLDETAIL pldetail ON (pldtlipkey.FK_INV_LINK =  pldetail.INV_LINK)
		-- 	08/09/2019 Sachin B Added Join pldtlipkeyConsignWh and  pldetailConsign to get shipped sid information of sfbl warehouse
		LEFT JOIN PLDTLIPKEY pldtlipkeyConsignWh ON ipKey.originalIpkeyUnique = pldtlipkeyConsignWh.FK_IPKEYUNIQUE 
		LEFT JOIN PLDETAIL pldetailConsign ON (pldtlipkeyConsignWh.FK_INV_LINK =  pldetailConsign.INV_LINK)
		WHERE ipKey.W_KEY=@wKey AND ipkey.UNIQ_KEY=@uniqKey  
		--  08/08/2019 Sachin B modify the where condition to get Shipped SID information
	   	AND (
					(ipkey.pkgbalance - ipkey.qtyAllocatedTotal) >0  
				OR	(pldtlipkey.NSHPQTY>0 AND pldtlipkey.FK_IPKEYUNIQUE is not null AND pldetail.PACKLISTNO =@packnumber)
			)
		-- 	08/09/2019 Sachin B filter sfbl warehouse by PACKLISTNO
		AND ISNULL
		(
			  pldetailConsign.PACKLISTNO, '') = CASE WHEN (@isSFBLWh = 1)     
              THEN CASE WHEN (pldetailConsign.PACKLISTNO IS NOT NULL ) THEN @packnumber ELSE NULL END     
              ELSE ISNULL(pldetailConsign.PACKLISTNO, '') END       
	    ) 

,TransferData AS(

SELECT  DISTINCT    
   ipkey.IpKeyUnique         
  ,(ipkey.pkgbalance-ipkey.qtyAllocatedTotal) AS pkgbalance     
  ,ipkey.pkgbalance OldPkgBalance    
  ,(ISNULL(SUM(i1.qtyTransfer),0)) - ISNULL(SUM(i2.qtyTransfer),0)  AS AllocatedQty    
  ,( ISNULL(SUM(i1.qtyTransfer),0) - ISNULL(SUM(i2.qtyTransfer),0)) AS OldAllocatedQty    
  ,(ipkey.pkgbalance + pldtlIpKey.NSHPQTY) AS TotalPkgBalance   
  ,i.UNIQ_KEY      
   ,@wKey AS W_KEY    
  ,i.SERIALYES    
  ,ipkey.LOTCODE     
  ,ipkey.REFERENCE     
  ,ipkey.EXPDATE    
  ,ipkey.PONUM             
  , uniqLot=ISNULL( (SELECT TOP 1  UNIQ_LOT FROM INVTLOT WHERE LOTCODE=ipkey.LOTCODE AND REFERENCE=ipkey.REFERENCE AND EXPDATE=ipkey.EXPDATE AND PONUM=Ipkey.PONUM AND W_KEY= @wKey),SPACE(10))    
  ,PackListNo     
  ,pldtl.UNIQUELN
  ,pldtlIpKey.NSHPQTY
  ,ipkey.originalPkgQty       
  FROM PLDETAIL  pldtl     
  INNER JOIN PLDTLIPKEY pldtlIpKey ON  pldtl.INV_LINK=pldtlIpKey.FK_INV_LINK    
  LEFT JOIN iTransferipkey i1 ON i1.fromIpkeyunique=pldtlIpKey.FK_IPKEYUNIQUE 
  LEFT JOIN iTransferipkey i2 ON i2.toIpkeyunique=pldtlIpKey.FK_IPKEYUNIQUE    
  INNER JOIN ipkey ipkey ON ipkey.ipkeyunique=i1.fromIpkeyunique AND ipkey.W_KEY=@wKey  
  INNER JOIN INVTMFGR mf ON ipkey.W_KEY=mf.W_KEY 
  --AND mf.SFBL =0
  INNER JOIN inventor i ON i.UNIQ_KEY = ipkey.UNIQ_KEY  
  Group BY  ipkey.IpKeyUnique,ipkey.pkgbalance ,ipkey.qtyAllocatedTotal,pldtlIpKey.NSHPQTY,i.UNIQ_KEY ,i.SERIALYES,ipkey.LOTCODE ,ipkey.REFERENCE
  ,ipkey.EXPDATE,ipkey.PONUM  ,PackListNo  ,pldtl.UNIQUELN, ipkey.originalPkgQty      
  Having PACKLISTNO=@packnumber  AND (ISNULL(SUM(i1.qtyTransfer),0) -(ISNULL(SUM(i2.qtyTransfer),0))) > 0 AND pldtl.UNIQUELN=@uniqueLnNo

  )

  --select * from TransferData

  --,XferData AS(
  SELECT s1.IpKeyUnique      
		,s1.pkgbalance     
		,s1.pkgbalance AS OldPkgBalance    
		--,ISNULL(t1.AllocatedQty,0 )AS AllocatedQty    
		--  01/25/2019 Shrikant modify AllocatedQty same as pkgbalance for sfbl type warehouse sid   
		,CASE WHEN (s1.SFBL = 0) 
			  --THEN (SELECT ISNULL((SUM(pkgBalance)),0 )FROM IPKEY WHERE originalIpkeyUnique=s1.IpKeyUnique   ) --s1.pkgbalance --ISNULL(t1.AllocatedQty,0 ) 
			  THEN ISNULL((t1.NSHPQTY),0 )
			  ELSE s1.pkgbalance  
		END AS AllocatedQty 		
		,ISNULL(t1.AllocatedQty,0 ) AS OldAllocatedQty    
		,s1.TotalPkgBalance     
		,s1.UNIQ_KEY    
		,s1.W_KEY    
		,s1.SERIALYES    
		,s1.LOTCODE     
		,s1.REFERENCE     
		,s1.EXPDATE    
		,s1.PONUM      
		, s1.uniqLot
		--,ISNULL(t1.PACKLISTNO,0 ) AS PackListNo   
		,ISNULL(s1.PACKLISTNO,0 ) AS PackListNo     
		,ISNULL(t1.UNIQUELN,'' ) AS UNIQUELN
		--  08/29/2019 Sachin B Added column originalPkgQty for reverse qty validation  
		,s1.originalPkgQty   
		      FROM SIDData s1 
  LEFT JOIN TransferData t1 ON s1.IPKEYUNIQUE =t1.IPKEYUNIQUE
  --)

  END 