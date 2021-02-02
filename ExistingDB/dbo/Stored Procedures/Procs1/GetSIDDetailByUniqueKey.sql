-- =============================================
-- Author:Sachin s
-- Create date: 05/31/2016
-- Description:	Get SID detail based on unique key and ware house key if item is Used in SID and is Serialized and lotted
-- Modified	  :	Sachin s : 08-19-2016 Get uniqLot values for sid
--			  : Sachin s : 08-19-2016 Get sid with pack list number
--			  :	Sachin s : 08-19-2016 Get uniq data from both temp tables
--			  :	Sachin s : 08-19-2016 Get uniqLot values for sid
--			  :	Satish B  : 12-28-2016 Add LotCode,reference,ExpDate and Ponum
--			  :	Satish B  : 12-29-2016 get the total pkg balance
--			  :	Satish B  : 09-18-2017 : Select pkgbalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment selection of ipkey.pkgbalance
--			  :	Satish B  : 09-18-2017 : Select TotalPkgBalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment (ipkey.pkgbalance) As TotalPkgBalance
--			  :	Satish B  : 09-18-2017 : Check condition (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) >0 instade of ipkey.pkgbalance > 0
--            : Satish B- 04-05-2018 : Added the parameter @uniqueLnNo 
--			  :	Satish B- 04-05-2018 : Added the filter of @uniqueLnNo while editing packing list
-- GetSIDDetailByUniqueKey 'OYU5NKB5DO','JBRN1TT6MO','0000000688','_52M00ISQX'
/* used for SID ,serialized and lotted*/
-- =============================================
CREATE PROCEDURE GetSIDDetailByUniqueKey
	@uniqKey AS char(10),
	@wKey AS char(10), 
	 --Sachin s : 08-19-2016 Get sid with pack list number
	@packnumber AS char(10)='', 
	--Satish B- 04-05-2018 : Added the parameter @uniqueLnNo 
	@uniqueLnNo char(10)='' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--Sachin s : 08-19-2016 Get uniq data from both temp tables
	;WITH SIDData as(
	SELECT DISTINCT
	  ipkey.IpKeyUnique  
	   --Satish B  : 09-18-2017 : Select pkgbalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment selection of ipkey.pkgbalance
	  ,(ipkey.pkgbalance-ipkey.qtyAllocatedTotal) As pkgbalance 
	  --,ipkey.pkgbalance pkgbalance
	  ,ipkey.pkgbalance AS OldPkgBalance
	  ,0 As AllocatedQty
	  ,0 As OldAllocatedQty
	  --Satish B  : 09-18-2017 : Select TotalPkgBalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment (ipkey.pkgbalance) As TotalPkgBalance
	  ,(ipkey.pkgbalance-ipkey.qtyAllocatedTotal) As TotalPkgBalance 
		--,(ipkey.pkgbalance) As TotalPkgBalance --Satish B  : 12-29-2016 get the total pkg balance
	  ,ipkey.UNIQ_KEY
	  ,ipkey.W_KEY
      ,i.SERIALYES
	  --Satish B  : 12-28-2016 Add LotCode,reference,ExpDate and Ponum
	  ,ipkey.LOTCODE 
	  ,ipkey.REFERENCE 
	  ,ipkey.EXPDATE
	  ,ipkey.PONUM		
	  --Sachin s : 08-19-2016 Get uniqLot values for sid
	  , uniqLot=ISNULL( (SELECT top 1  UNIQ_LOT from INVTLOT where LOTCODE=ipkey.LOTCODE AND REFERENCE=ipkey.REFERENCE AND EXPDATE=ipkey.EXPDATE
	   AND PONUM=Ipkey.PONUM AND W_KEY= @wKey),Space(10))
	  ,0 AS PackListNo
	  ,'' AS UNIQUELN
	  from IPKEY ipkey    
	  INNER JOIN inventor i on i.UNIQ_KEY = ipkey.UNIQ_KEY
	  where 
	  ipKey.W_KEY=@wKey  AND
	  ipkey.UNIQ_KEY=@uniqKey  AND
	  --Satish B  : 09-18-2017 : Check condition (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) >0 instade of ipkey.pkgbalance > 0
	  (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) >0
	  --ipkey.pkgbalance > 0  

	    UNION 	  
		SELECT  DISTINCT
		ipkey.IpKeyUnique  	  
		 --Satish B  : 09-18-2017 : Select pkgbalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment selection of ipkey.pkgbalance
		 ,(ipkey.pkgbalance-ipkey.qtyAllocatedTotal) As pkgbalance 
		--,ipkey.pkgbalance
		,ipkey.pkgbalance OldPkgBalance
		,pldtlIpKey.NSHPQTY  As AllocatedQty
		,pldtlIpKey.NSHPQTY As OldAllocatedQty
		,(ipkey.pkgbalance + pldtlIpKey.NSHPQTY) As TotalPkgBalance --Satish B  : 12-29-2016 get the total pkg balance
		,i.UNIQ_KEY		
	 	,@wKey AS W_KEY
		,i.SERIALYES
		--Satish B  : 12-28-2016 Add LotCode,reference,ExpDate and Ponum
		,ipkey.LOTCODE 
		,ipkey.REFERENCE 
		,ipkey.EXPDATE
		,ipkey.PONUM			 		   
		, uniqLot=ISNULL( (SELECT top 1  UNIQ_LOT from INVTLOT where LOTCODE=ipkey.LOTCODE AND REFERENCE=ipkey.REFERENCE AND EXPDATE=ipkey.EXPDATE 
		AND PONUM=Ipkey.PONUM AND W_KEY= @wKey),Space(10))
		,PackListNo	
		,pldtl.UNIQUELN
		from PLDETAIL  pldtl 
		INNER JOIN PLDTLIPKEY pldtlIpKey On  pldtl.INV_LINK=pldtlIpKey.FK_INV_LINK
		INNER JOIN issueipkey issueipkey ON issueipkey.ipkeyunique=pldtlIpKey.FK_IPKEYUNIQUE
		INNER JOIN ipkey ipkey ON ipkey.ipkeyunique=issueipkey.IpKeyUnique AND ipkey.W_KEY=@wKey
		INNER JOIN inventor i on i.UNIQ_KEY = ipkey.UNIQ_KEY
		where PACKLISTNO=@packnumber AND issueipkey.qtyissued > 0 
		--Satish B- 04-05-2018 : Added the filter of @uniqueLnNo while editing packing list
		AND pldtl.UNIQUELN=@uniqueLnNo
		)
		select * from SIDData
END