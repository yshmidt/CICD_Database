-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get MfgrMaster sync record count by sync location id
-- =============================================
CREATE PROCEDURE [dbo].[GetMfgrMasterCountByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT COUNT(DISTINCT MfgrMasterId)
	FROM MfgrMaster cc
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON cc.MfgrMasterId = sml.UniqueNum
	WHERE cc.IsSynchronizedFlag=0 
	 AND cc.MfgrMasterId NOT IN (SELECT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )		
			        			
END
	