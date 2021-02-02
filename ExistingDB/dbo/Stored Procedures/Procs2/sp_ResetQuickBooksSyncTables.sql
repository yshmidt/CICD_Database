-- =============================================
-- Author:		Anuj Kumar
-- Create date: <01/08/2015>
-- Description:	Resets all the tables to previous state
-- =============================================
Create Procedure sp_ResetQuickBooksSyncTables
As
BEGIN
	
	--delete the existing mappings and log
	Delete from ManexQbMapping
	Delete from ManexItemAccountMapping
	Delete from SynchronizationMasterLog where SyncLogFor='Quickbooks'

	--Update the flag for the tables need to sync to quickbooks
	update GL_NBRS set IsQbSync=0
	update SALETYPE set IsQbSync=0
	update CUSTOMER set IsQbSync=0
	update TAXTABL set IsQbSync=0
	update PMTTERMS set IsQbSync=0
	update SUPINFO set IsQbSync=0

END