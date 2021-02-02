-- =============================================
-- Author:Sachin s
-- Create date: 05/31/2016
-- Description:	Get SID detail based on unique key and ware house key if item is Used in SID and is Serialized and lotted
/* used for SID with serialized and lotted*/
--sachin s 08-10-2016 Get ipkeys from uniqLot based on lot details
--Sachin s : 08-27-2016  Find uniqLot by w_key	
--Sachin s : 08-27-2016  Get Sid details while packing list 
--Satish B  : 12-29-2016 get the total pkg balance
--Satish B  : 09-18-2017 : Select pkgbalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment selection of ipkey.pkgbalance
--Satish B  : 09-18-2017 : Select TotalPkgBalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment (ipkey.pkgbalance) As TotalPkgBalance
--Satish B  : 09-18-2017 : Check condition (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) >0 instade of ipkey.pkgbalance > 0
--GetSIDValuesByUniqueKeyAndWareHouse '_1EP0Q018H','_1EP0Q1442',''
-- =============================================
CREATE PROCEDURE GetSIDValuesByUniqueKeyAndWareHouse
	@uniqKey AS char(10),--'_01F15SZ9N'
	@wKey AS char(10), --'_1ED0O2FSC'
	--sachin s 08-10-2016 Get ipkeys by packing list number
	@packnumber AS char(10)= ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT DISTINCT
	   ipkey.IpKeyUnique  	  
	    --Satish B  : 09-18-2017 : Select pkgbalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment selection of ipkey.pkgbalance
	   ,(ipkey.pkgbalance - ipkey.qtyAllocatedTotal) As pkgbalance 
	  --,ipkey.pkgbalance
	  ,ipkey.pkgbalance OldPkgBalance
	  ,0 As AllocatedQty
	  ,0 As OldAllocatedQty
	  --Satish B  : 09-18-2017 : Select TotalPkgBalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment (ipkey.pkgbalance) As TotalPkgBalance
	  ,(ipkey.pkgbalance - ipkey.qtyAllocatedTotal) As TotalPkgBalance 
	  --,(ipkey.pkgbalance) As TotalPkgBalance --Satish B  : 12-29-2016 get the total pkg balance
	  ,ipkey.UNIQ_KEY,
	   ipkey.W_KEY
	  --Satish B  : 12-28-2016 Add LotCode,reference,ExpDate and Ponum
	  ,ipkey.LOTCODE 
	  ,ipkey.REFERENCE 
	  ,ipkey.EXPDATE
	  ,ipkey.PONUM			
    --sachin s 08-10-2016 Get ipkeys from uniqLot based on lot details  
	  --Sachin s : 08-27-2016  Find uniqLot by w_key	  
	  , uniqLot=ISNULL( (SELECT top 1  UNIQ_LOT from INVTLOT where LOTCODE=ipkey.LOTCODE AND REFERENCE=ipkey.REFERENCE AND EXPDATE=ipkey.EXPDATE AND PONUM=Ipkey.PONUM AND W_KEY= @wKey),Space(10))
	  --Sachin s : 08-27-2016  Get Sid details while packing list 
	  ,0 AS PackListNo
	  from IPKEY ipkey    	  
	  INNER  JOIN invtser invtser ON ipkey.UNIQ_KEY=invtser.UNIQ_KEY 
	  where invtser.ID_key='w_key'
	   and invtser.id_value=@wKey
	   AND invtser.UNIQ_KEY=@uniqKey
	   AND ipkey.W_key=@wKey
	   AND ipkey.UNIQ_KEY=@uniqKey
	   --Satish B  : 09-18-2017 : Check condition (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) >0 instade of ipkey.pkgbalance > 0
	   --AND ipkey.pkgbalance > 0
	   AND (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) >0
	   UNION 

	   --sachin s 08-10-2016 Get ipkeys by packing list number
	   --Get Packing list SID Values
	   SELECT  DISTINCT
	    ipkey.IpKeyUnique  	  
		 --Satish B  : 09-18-2017 : Select pkgbalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment selection of ipkey.pkgbalance
		,(ipkey.pkgbalance - ipkey.qtyAllocatedTotal) As pkgbalance 
	   --,ipkey.pkgbalance
	   ,ipkey.pkgbalance OldPkgBalance
	   ,0  As AllocatedQty
	   ,0 As OldAllocatedQty
	   --Satish B  : 09-18-2017 : Select TotalPkgBalance as (ipkey.pkgbalance - ipkey.qtyAllocatedTotal) and comment (ipkey.pkgbalance) As TotalPkgBalance
	   ,(ipkey.pkgbalance - ipkey.qtyAllocatedTotal) As TotalPkgBalance 
		--,(ipkey.pkgbalance) As TotalPkgBalance --Satish B  : 12-29-2016 get the total pkg balance
			   ,invtser.UNIQ_KEY
	   ,@wKey AS W_KEY	 
	   --Satish B  : 12-28-2016 Add LotCode,reference,ExpDate and Ponum
	   ,ipkey.LOTCODE 
	   ,ipkey.REFERENCE 
	   ,ipkey.EXPDATE
	   ,ipkey.PONUM	
	   --Sachin s : 08-27-2016  Find uniqLot by w_key	  
	   , uniqLot=ISNULL( (SELECT top 1  UNIQ_LOT from INVTLOT where LOTCODE=ipkey.LOTCODE AND REFERENCE=ipkey.REFERENCE AND EXPDATE=ipkey.EXPDATE AND PONUM=Ipkey.PONUM AND W_KEY= @wKey),Space(10))
		--Sachin s : 08-27-2016  Get Sid details while packing list 
	   ,@packnumber AS PackListNo
     	from INVTSER  invtser  
		INNER JOIN issueipkey issueipkey ON issueipkey.ipkeyunique=invtser.ipkeyunique
		INNER JOIN ipkey ipkey ON ipkey.ipkeyunique=invtser.IpKeyUnique AND ipkey.W_KEY=@wKey
		where ID_KEY='PACKLISTNO' AND ID_VALUE=@packnumber 
		
END


 
 