-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/12/2017
-- Description:	Single SP to get deleted records (Synchronization module) This SP should replace all
--		get<table>DeletedRecordsByLocation  ---e.g.  [GetAbcSetupDeletedRecordsByLocationId]
-- parameteres 
-- @locationId - id for the location 
-- @TableName - name of the table with deleted records
-- =============================================
CREATE PROCEDURE getDeletedRecordsByLocation 
	-- Add the parameters for the stored procedure here
	@locationId int = 1, 
	@Tablename varchar(50) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  TableKeyValue
    FROM SynchronizationDeletedRecords del
    LEFT OUTER JOIN SynchronizationMultiLocationLog sml
    ON del.TableKeyValue = sml.UniqueNum and  OperationName like '%delete%'  
    WHERE del.TableName=@Tablename
	--- in some cases (coudnot duplicate), the records were in SynchronizationDeletedRecords, but not in SynchronizationMultiLocationLog
	-- Bom_det, Antiavl, BomRef
    and ((sml.LocationId is not null and sml.IsSynchronizationFlag=0 and sml.LocationId=@locationid) or sml.LocationId is null)     
END