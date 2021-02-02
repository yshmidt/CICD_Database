-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get ANTIAVL deleted records by location id
-- =============================================
CREATE PROCEDURE [dbo].[GetAntiAvlDeletedRecordsByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT DISTINCT TableKeyValue
	FROM SynchronizationDeletedRecords del
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON del.TableKeyValue = sml.UniqueNum
	WHERE del.TableName='ANTIAVL' 
	 AND del.TableKeyValue NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )		
	 --and ( (sml.LocationId is not null and sml.IsSynchronizationFlag=0) or sml.LocationId is null)
			        			
END
	

	