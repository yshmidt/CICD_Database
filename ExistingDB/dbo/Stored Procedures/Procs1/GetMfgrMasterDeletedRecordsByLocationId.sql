-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get deleted records by location id from SynchronizationDeletedRecords
-- =============================================
CREATE PROCEDURE [dbo].[GetMfgrMasterDeletedRecordsByLocationId]   
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT DISTINCT TableKeyValue
	FROM SynchronizationDeletedRecords del
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON del.TableKeyValue = sml.UniqueNum
	WHERE del.TableName='MfgrMaster' AND  
	 del.TableKeyValue NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )
END
	