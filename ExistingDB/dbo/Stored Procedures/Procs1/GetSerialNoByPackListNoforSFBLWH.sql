-- =============================================
-- Author:Shrikant B
-- Create date: 03/06/2019
-- Description:	Get serial numbers based on uniqKey, warehouse key packlist no
-- 07/24/2019 Sachin added ID_KEY and ID_VALUE condition to avoid serial number confusion in same packing list based on warehouse uniq key     	
-- GetSerialNoByPackListNoforSFBLWH '_3SX0TLY16','_3SX0TLY3G','0000000727', ''
-- =============================================
CREATE PROCEDURE GetSerialNoByPackListNoforSFBLWH
	@uniqKey AS char(10),
	@wKey AS char(10), 
	@packListno AS char(10),
	@ponum AS CHAR(15),
	@reference AS CHAR(12)='',
	@lotCode AS nvarCHAR(25) ='',
	@expDt AS smalldateTime=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT DISTINCT
		invtser.Actvkey ,
		 invtser.Expdate as EXPDATE,
		 invtser.Id_Key ,
		 invtser.Id_Value,
		 packlser.IpKeyUnique,
		 invtser.Lotcode ,
		 invtser.Oldwono ,
		 invtser.Ponum ,
		 invtser.Reference ,
		 invtser.Reservedflag ,
		 invtser.Reservedno ,
		 invtser.Savedttm,
		 invtser.Saveinit,
		 invtser.SerialUniq ,
		dbo.fRemoveLeadingZeros(invtser.SerialNo) SerialNo,
		 invtser.Uniq_Key ,
		 invtser.Uniq_Lot ,
		 invtser.Uniqmfgrhd ,
		 invtser.Wono 
	  FROM INVTSER invtser     
-- 07/24/2019 Sachin added ID_KEY and ID_VALUE condition to avoid serial number confusion in same packing list based on warehouse uniq key     	
	  INNER JOIN PACKLSER packlser ON invtser.SERIALUNIQ =  packlser.SERIALUNIQ  
	  WHERE packlser.PACKLISTNO=@packListno
	 
END
