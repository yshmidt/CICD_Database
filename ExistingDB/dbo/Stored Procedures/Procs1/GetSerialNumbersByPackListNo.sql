-- =============================================
-- Author:Sachin s
-- Create date: 06/15/2016
-- Description:	Get serial numbers based on uniqKey,warehouse key packlist no
-- Satish B- 12-28-2016 Added four more parameters
-- Satish B- 12-28-2016 create alise of Expdate as EXPDATE
-- GetSerialNumbersByPackListNo '_1EP0Q018H','_1EP0Q1442','0000000538'
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[GetSerialNumbersByPackListNo]
	@uniqKey AS char(10),--'_01F15SZ9N'
	@wKey AS char(10), --'_01F15T1ZB'
	@packListno AS char(10), --'_01F15T1ZB'
	--Satish B- 12-28-2016 Added four more parameters
	@ponum AS CHAR(15),
	@reference AS CHAR(12)='',
	--02/09/18 YS changed size of the lotcode column to 25 char
	@lotCode AS nvarCHAR(25) ='',
	@expDt AS smalldateTime=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT DISTINCT
		invtser.Actvkey ,
		--Satish B- 12-28-2016 create alise of Expdate as EXPDATE
		 invtser.Expdate as EXPDATE,
		 invtser.Id_Key ,
		 invtser.Id_Value,
		 invtser.IpKeyUnique,
		 invtser.Lotcode ,
		 invtser.Oldwono ,
		 invtser.Ponum ,
		 invtser.Reference ,
		 invtser.Reservedflag ,
		 invtser.Reservedno ,
		 invtser.Savedttm,
		 invtser.Saveinit,
		 invtser.SerialUniq ,
		 invtser.SerialNo ,
		 invtser.Uniq_Key ,
		 invtser.Uniq_Lot ,
		 invtser.Uniqmfgrhd ,
		 invtser.Wono 
	  --,invtser.SerialUniq
	  --,invtser.UNIQ_KEY
	  from invtser invtser      	
	  LEFT OUTER JOIN inventor i on i.UNIQ_KEY = invtser.UNIQ_KEY
	  INNER JOIN PACKLSER packlser on packlser.PACKLISTNO = @packListno
	  INNER JOIN PKALLOC pkaloc on pkaloc.PACKLISTNO = @packListno AND pkaloc.W_KEY = @wKey
	  --Satish B- 12-28-2016 Check condition with four more parameters @ponum,@reference,@lotCode,@expDt
	  where (((LOTCODE IS NULL OR LOTCODE ='') AND invtser.ID_KEY='PACKLISTNO'  AND invtser.ID_VALUE=@packListno AND invtser.UNIQ_KEY=@uniqKey) OR 
	  (invtser.ID_KEY='PACKLISTNO'  AND invtser.ID_VALUE=@packListno AND invtser.UNIQ_KEY=@uniqKey
	  AND invtser.LOTCODE=@lotCode AND   invtser.Reference=@reference and 
	  invtser.Expdate=@expDt and   invtser.Ponum=@ponum))
END
