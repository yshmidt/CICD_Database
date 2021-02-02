-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get bom Details deleted records by location id
 -- 09-29-2015  sachin s-check if this location is already synchronized
-- =============================================
CREATE PROCEDURE [dbo].[GetBomDetailsDeletedRecordsByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT DISTINCT TableKeyValue
	FROM SynchronizationDeletedRecords del
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON del.TableKeyValue = sml.UniqueNum
	WHERE del.TableName='BOM_DET' 
	 AND del.TableKeyValue NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )	

	--SELECT DISTINCT TableKeyValue
	--FROM SynchronizationDeletedRecords del
	--LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	--ON del.TableKeyValue = sml.UniqueNum
	--WHERE del.TableName='BOM_DET' 
	-- -- 09-29-2015  sachin s-check if this location is already synchronized
	--and ( (sml.LocationId is not null and sml.IsSynchronizationFlag=0) or sml.LocationId is null)		
			        			
END
	

	