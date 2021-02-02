-- =============================================
-- Author:		Vicky Lu
-- Create date: 10/17/2013
-- Description:	Mark MRB location with 0 qty_oh as deleted in Invtmfgr
-- 03/02/17 YS  Some data took too long, modified to process in batches. Also remove MRB empty location, not just "PO" locations
-- =============================================

CREATE PROCEDURE [dbo].[sp_Clear0MRB]
AS
BEGIN

SET NOCOUNT ON;

BEGIN TRY;		
	-- 03/02/17 YS  Some data took too long, modified to process in batches. Also remove MRB empty location, not just "PO" locations
	declare @numOfRecords int,@counter int ,@batchsize int;
	SELECT @numOfRecords =  
		(SELECT COUNT(*) AS NumberOfRecords 
		FROM Invtmfgr with(nolock)
		WHERE is_deleted=0 
		--LEFT(Location,2) = 'PO' 
		AND Qty_oh = 0 
		AND UniqWh IN 
		(SELECT UniqWh 
			FROM Warehous 
			WHERE Warehouse = 'MRB'));

	set @counter = 0 
	set @batchsize = 2500
	-- for the big data break it ito batches
	set transaction isolation level read uncommitted
	set rowcount @batchsize
	while @counter < (@numOfRecords/@batchsize) +1
	begin 
	set @counter = @counter + 1 
	begin transaction
		UPDATE Invtmfgr 
			SET Is_Deleted = 1 
			WHERE is_deleted=0 
			--LEFT(Location,2) = 'PO' 
			AND Qty_oh = 0 
			AND UniqWh IN 
			(SELECT UniqWh 
			FROM Warehous 
			WHERE Warehouse = 'MRB')
		commit
	end 
	set rowcount 0
	set transaction isolation level read committed
	-- 10/17/2013 using new procedure / table to log scripts
   exec [spMntUpdLogScript] 'sp_Clear0MRB','Stored Procedure';

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in clearing MRB locations with zero quantity OH. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH


END	