-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get InvtMPNLink sync record count by sync location id
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtMPNLinkCountByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT COUNT(DISTINCT uniqmfgrhd)
	FROM INVTMPNLINK cc
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON cc.uniqmfgrhd = sml.UniqueNum
	WHERE cc.IsSynchronizedFlag=0 
	 AND cc.uniqmfgrhd NOT IN (SELECT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )		
			        			
END
	