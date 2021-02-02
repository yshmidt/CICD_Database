-- =============================================
-- Author:	Sachin shevale
-- Create date: 11/2/15
-- Description:	get UNIT deleted records by location id
-- =============================================
CREATE PROCEDURE [dbo].[GetUNITDeletedRecordsByLocationId]  
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT DISTINCT TableKeyValue
	FROM SynchronizationDeletedRecords del
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON del.TableKeyValue = sml.UniqueNum
	WHERE del.TableName='UNIT' 
	 AND del.TableKeyValue NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 )	
			        			
END
	

	