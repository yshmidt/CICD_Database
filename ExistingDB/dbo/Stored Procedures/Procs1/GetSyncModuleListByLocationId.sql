-- =============================================
-- Author:	Sachin shevale
-- Create date: 07/29/15
-- Description:	get sync module list from item table or SynchronizationModules if exists 
 --08-29-2015- rename the column name and change the table name and drop table MnxListOfSyncItems and use mnxSynchronizedItems
 --09-25-2015 -Get the UniqueNum from mnxSynchronizedItems table for bom sync
 --09-26-2015 -modify the column Name  UniqueNum to SyncItemNumber in SynchronizationModules
-- =============================================
CREATE PROCEDURE [dbo].[GetSyncModuleListByLocationId]   
			-- parameters for the stored procedure here
			@LocationId INT
			AS	
			-- interfering with SELECT statements if exists 
			IF EXISTS(SELECT 1 FROM  SynchronizationModules  WHERE LocationId = @LocationId)
			 BEGIN
			 --then select the module details from  SynchronizationModules table
		  SELECT sit.SynModuleName As SyncModuleName, sit.SyncModuleDesc  AS SyncModuleDesc, sit.SyncItemNumber AS SyncItemNumber, 
			    sm.ModuleSyncEnabled AS ModuleSyncEnabled,sit.UniqueNum  FROM mnxSynchronizedItems sit
				--09-25-2015 -Get the UniqueNum from mnxSynchronizedItems table for bom sync
				--09-26-2015 -modify the column Name  UniqueNum to SyncItemNumber in SynchronizationModules
				INNER JOIN  SynchronizationModules sm ON sm.SyncItemNumber=sit.SyncItemNumber
				WHERE sm.LocationId = @LocationId
			END
				ELSE 
				 --Other wise get all details from base from items tables default  IsSyncronizable flag as false
				BEGIN
				--Get the data from new table from SynchronizedItems and remove from Items
		   SELECT   sit.SynModuleName As SyncModuleName, sit.SyncModuleDesc AS SyncModuleDesc, sit.SyncItemNumber AS SyncItemNumber ,
		   --09-25-2015 -Get the UniqueNum from mnxSynchronizedItems table for bom sync
		   CAST('FALSE' as bit) AS ModuleSyncEnabled,sit.UniqueNum FROM mnxSynchronizedItems  sit WHERE  sit.IsSynchronizedItem=1           			
	END
	
	