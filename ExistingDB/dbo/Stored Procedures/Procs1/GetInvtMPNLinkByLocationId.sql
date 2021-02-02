-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get InvtMPNLink for sync records by sync location id
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtMPNLinkByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT *
	FROM INVTMPNLINK cc
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON cc.UNIQMFGRHD = sml.UniqueNum
	WHERE cc.IsSynchronizedFlag=0 
	 AND cc.UNIQMFGRHD NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 ) 
			        			
END	