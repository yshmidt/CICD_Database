-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/23/08
-- Description:	Function to check if location can be removed when qty_oh=0
-- Modified : 10/08/14 YS replace invtmfhd table with 2 new tables
--- 09/22/16 YS changed the code to always remove an empty location for MRB and WO-WIP
-- =============================================
CREATE FUNCTION [dbo].[fRemoveLocation] 
(
	-- Add the parameters for the function here
	@lcUniqWh char(10),@lcUniqMfgrHd char(10)
)
RETURNS bit
AS
BEGIN
	-- Declare the return variable here
	DECLARE @lReturn bit;
	DECLARE @lcWarehouse char(6),@lAutolocation bit,@lremovewhenzero bit
	SET @lReturn = 0;
	-- Add the T-SQL statements to compute the return value here
	SELECT  @lcWarehouse = Warehouse,@lAutolocation =Autolocation,@lremovewhenzero=lremovewhenzero from Warehous where uniqwh=@lcUniqWh;
	IF ((@lcWarehouse='WO-WIP') OR (@lcWarehouse='MRB')) 
	BEGIN
	--- 09/22/16 YS changed the code to always remove an empty location for MRB and WO-WIP
		SELECT @lReturn=1
	END
	ELSE
	IF (@lcWarehouse<>'WIP' and @lAutoLocation=1 and @lRemoveWhenZero=1)
		BEGIN
			--10/08/14 YS replace invtmfhd table with 2 new tables
			--SELECT @lReturn = AutoLocation From Invtmfhd where UniqMfgrhd=@lcUniqMfgrhd
			SELECT @lReturn = m.AutoLocation From mfgrmaster M inner join InvtMPNLink L on m.MfgrMasterId=l.mfgrMasterId 
				where l.UniqMfgrhd=@lcUniqMfgrhd
		END
	

	-- Return the result of the function
	RETURN @lReturn

END