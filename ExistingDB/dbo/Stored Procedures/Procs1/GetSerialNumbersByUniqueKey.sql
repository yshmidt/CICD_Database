-- =============================================
-- Author:Sachin s
-- Create date: 05/31/2016
-- Description:	Get SID detail based on unique key and ware house key if item is Used in SID and is Serialized and lotted
--GetSerialNumbersByUniqueKey '_1ED0O2FS5','_1ED0O2FSC'
--Sachin S  10 -08-2016 Remove leading zeros of serial number
--Sachin s  10 -08-2016 Get invtser details
/* used for SID ,serialized and lotted*/
-- =============================================
CREATE PROCEDURE GetSerialNumbersByUniqueKey 
	@uniqKey AS char(10),--'_01F15SZ9N'
	@wKey AS char(10) --'_01F15T1ZB'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT DISTINCT
	  --invtser.serialno
	  --,invtser.SerialUniq
	  --,invtser.UNIQ_KEY
	     invtser.SerialUniq
		 --Sachin S  10 -08-2016 Remove leading zeros of serial number
		,dbo.fRemoveLeadingZeros(invtser.SerialNo) SerialNo
		--,invtser.SerialNo
		,invtser.UNIQ_KEY
		--Sachin s  10 -08-2016 Get invtser details
		,invtser.UNIQMFGRHD
		,invtser.UNIQ_LOT
		,invtser.ID_KEY
		,invtser.ID_VALUE
		,invtser.SAVEDTTM
		,invtser.SAVEINIT
		,invtser.LOTCODE
		,invtser.EXPDATE
		,invtser.REFERENCE
		,invtser.PONUM
		,invtser.ISRESERVED
		,invtser.ACTVKEY
		,invtser.OLDWONO
		,invtser.WONO
		,invtser.RESERVEDFLAG
		,invtser.RESERVEDNO
		,invtser.IpKeyUnique		
	    ,ipkey.pkgbalance,
	     '0'As AllocatedQty
	    ,ipkey.UNIQ_KEY,
	  ipkey.W_KEY
	  from invtser invtser      	
	  INNER JOIN inventor i on i.UNIQ_KEY = invtser.UNIQ_KEY
	  LEFT OUTER JOIN IPKEY ipkey ON ipkey.UNIQ_KEY = invtser.UNIQ_KEY	   
	  where invtser.ID_KEY='W_Key' 
	  AND invtser.ID_VALUE=@wKey
	  AND invtser.UNIQ_KEY=@uniqKey 
	  --AND ( @wKey is null or ipkey.W_key= @wKey) 
END