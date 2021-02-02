-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/16/2014
-- Description:	create a procedure to add new part mfgr/mpn record
-- we have desktop applications like SF and RMA that will try to find a location for the make part 
-- and if not found will check for 'GENR' mfgr w/o mpn and if not found insert new 'GENR' mpn
-- I am trying to avoid bringing all the records in mfgrMaster into the module. Will just 
-- check for the 'GENR' and if not found will call this [procedure to insert the record 
-- just in case will make it general and allow to add partmfgr and mfgr_pt_no
--04/03/18 YS mfgrmasterid is an int
-- =============================================
CREATE PROCEDURE [dbo].[MfgrMasterAdd]
	-- Add the parameters for the stored procedure here
	@partmfgr varchar(8)='',@mfgr_pt_no varchar(30)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	If (@partmfgr<>'' )
	BEGIN	
		DECLARE @t table (mfgrMasterId int)

		-- cannot add empty partmfgr
		BEGIN TRANSACTION
		BEGIN TRY
			--check first
			IF NOT EXISTS (SELECT 1 from MfgrMaster WHERE PartMfgr =@partmfgr 
					and mfgr_pt_no=@mfgr_pt_no)
				--add new record
				INSERT INTO MfgrMaster (partmfgr,mfgr_pt_no,MATLTYPE) 
				OUTPUT Inserted.MfgrMasterId INTO @t
				VALUES 
					(@partmfgr,@mfgr_pt_no,'Unk')
			ELSE
				-- exists
				UPDATE mfgrMaster SET is_deleted=0 
				OUTPUT Inserted.MfgrMasterId INTO @t
					WHERE PartMfgr =@partmfgr 
					and mfgr_pt_no=@mfgr_pt_no 
					
			
			--INSERT INTO @t (mfgrMasterId) 
			--SELECT MfgrMasterId from MfgrMaster WHERE PartMfgr =@partmfgr 
			--	and mfgr_pt_no=@mfgr_pt_no 
									  
		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT<>0
			ROLLBACK
			
		END CATCH
	END -- if (@partmfgr<>'')
	IF @@TRANCOUNT<>0
		COMMIT
	SELECT * from @t
END