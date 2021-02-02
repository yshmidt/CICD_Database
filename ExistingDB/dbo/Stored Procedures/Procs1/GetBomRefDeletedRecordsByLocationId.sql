-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get bom references deleted records by location id
-- 09-29-2015  sachin s-check if this location is already synchronized
--and ( (sml.LocationId is not null and sml.IsSynchronizationFlag=0) or sml.LocationId is null)
-- =============================================
CREATE PROCEDURE [dbo].[GetBomRefDeletedRecordsByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	--SELECT DISTINCT TableKeyValue
	--FROM SynchronizationDeletedRecords del
	--LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	--ON del.TableKeyValue = sml.UniqueNum
	--WHERE del.TableName='BOM_REF' 
	-- AND del.TableKeyValue NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	-- AND sml.IsSynchronizationFlag=1 )		
	
	--- YS This code will do the same as your code above w/o sub select. 
	SELECT DISTINCT TableKeyValue
	FROM SynchronizationDeletedRecords del
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON del.TableKeyValue = sml.UniqueNum and sml.LocationId = @LocationId  
	WHERE del.TableName='BOM_REF' 
	--Sachin s 09-29-2015 Here our locationid will never be null and we dont need those records for which IsSynchronizationFlag=1 
	-- 09-29-2015  sachin s-check if this location is already synchronized
	--and ( (sml.LocationId is not null and sml.IsSynchronizationFlag=0) or sml.LocationId is null)
	 AND del.TableKeyValue NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )	
			        			
END
	

	