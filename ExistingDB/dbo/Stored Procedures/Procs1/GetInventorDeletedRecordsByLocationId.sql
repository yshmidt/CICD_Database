-- =============================================
-- Author:	Sachin shevale
-- Create date: 08/27/15
-- Description:	get inventor deleted records by location id
--Sachin s 09-29-2015 Here our locationid will never be null and we dont need those records for which IsSynchronizationFlag=1 
-- =============================================
CREATE PROCEDURE [dbo].[GetInventorDeletedRecordsByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT DISTINCT TableKeyValue
	FROM SynchronizationDeletedRecords del
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON del.TableKeyValue = sml.UniqueNum
	WHERE del.TableName='Inventor' 
	 AND del.TableKeyValue NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )
	 -- 09-29-2015  sachin s-check if this location is already synchronized
	 --Sachin s 09-29-2015 Here our locationid will never be null and we dont need those records for which IsSynchronizationFlag=1 
	--and ( (sml.LocationId is not null and sml.IsSynchronizationFlag=0) or sml.LocationId is null)		
			        			
END
	

	