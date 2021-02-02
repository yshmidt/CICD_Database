
CREATE FUNCTION [dbo].[fn_GetWKey]
(
@UniqKey CHAR(10),
@WKey CHAR(10),
@Warehouse CHAR(10),
@Location VARCHAR(200)
)

RETURNS char(10)

AS 
BEGIN
   --DECLARE VARIABLES
   DECLARE @ToWkey CHAR(10)
   DECLARE @UniqMfgrHd CHAR(10) = (SELECT UNIQMFGRHD FROM Invtmfgr WHERE W_Key = @WKey)

   --SET VARIABLES VALUE
   SET @ToWkey = (SELECT W_Key 
				  FROM Invtmfgr IM 
					   INNER JOIN Warehous W ON IM.UNIQWH = W.UNIQWH 
				  WHERE W.Warehouse = @Warehouse 
				        AND IM.UNIQMFGRHD = @UniqMfgrHd 
						AND IM.UNIQ_KEY = @UniqKey
						AND IM.LOCATION = @Location)
    RETURN @ToWkey
END