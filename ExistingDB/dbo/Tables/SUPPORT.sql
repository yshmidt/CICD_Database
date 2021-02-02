CREATE TABLE [dbo].[SUPPORT] (
    [DEL_FLAG]           CHAR (10)   CONSTRAINT [DF__SUPPORT__DEL_FLA__04DB663B] DEFAULT ('') NOT NULL,
    [PRIORITY]           CHAR (8)    CONSTRAINT [DF__SUPPORT__PRIORIT__05CF8A74] DEFAULT ('') NOT NULL,
    [TEXT4]              CHAR (10)   CONSTRAINT [DF__SUPPORT__TEXT4__06C3AEAD] DEFAULT ('') NOT NULL,
    [TEXT5]              CHAR (25)   CONSTRAINT [DF__SUPPORT__TEXT5__07B7D2E6] DEFAULT ('') NOT NULL,
    [FIELDNAME]          CHAR (10)   CONSTRAINT [DF__SUPPORT__FIELDNA__09A01B58] DEFAULT ('') NOT NULL,
    [TEXT]               CHAR (35)   CONSTRAINT [DF__SUPPORT__TEXT__0A943F91] DEFAULT ('') NOT NULL,
    [TEXT2]              CHAR (20)   CONSTRAINT [DF__SUPPORT__TEXT2__0B8863CA] DEFAULT ('') NOT NULL,
    [TEXT3]              CHAR (20)   CONSTRAINT [DF__SUPPORT__TEXT3__0C7C8803] DEFAULT ('') NOT NULL,
    [NUMBER]             NUMERIC (4) CONSTRAINT [DF__SUPPORT__NUMBER__0D70AC3C] DEFAULT ((0)) NOT NULL,
    [PREFIX]             CHAR (20)   CONSTRAINT [DF__SUPPORT__PREFIX__0E64D075] DEFAULT ('') NOT NULL,
    [LOGIC1]             BIT         CONSTRAINT [DF__SUPPORT__LOGIC1__0F58F4AE] DEFAULT ((0)) NOT NULL,
    [UNIQFIELD]          CHAR (10)   CONSTRAINT [DF__SUPPORT__UNIQFIE__104D18E7] DEFAULT ('') NOT NULL,
    [LOGIC2]             BIT         CONSTRAINT [DF__SUPPORT__LOGIC2__11413D20] DEFAULT ((0)) NOT NULL,
    [IsSynchronizedFlag] BIT         CONSTRAINT [DF__SUPPORT__IsSynch__3BB8FBDE] DEFAULT ((0)) NULL,
    CONSTRAINT [SUPPORT_PK] PRIMARY KEY CLUSTERED ([UNIQFIELD] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FIELDNAME]
    ON [dbo].[SUPPORT]([FIELDNAME] ASC, [TEXT] ASC);


GO
CREATE NONCLUSTERED INDEX [FIELDTXT2]
    ON [dbo].[SUPPORT]([FIELDNAME] ASC, [TEXT2] ASC);


GO
CREATE NONCLUSTERED INDEX [NUMBER]
    ON [dbo].[SUPPORT]([NUMBER] ASC);


GO
CREATE NONCLUSTERED INDEX [PRIORITY]
    ON [dbo].[SUPPORT]([PRIORITY] ASC);


GO
CREATE NONCLUSTERED INDEX [TEXT]
    ON [dbo].[SUPPORT]([TEXT] ASC);


GO
CREATE NONCLUSTERED INDEX [TEXT2]
    ON [dbo].[SUPPORT]([TEXT2] ASC);


GO
CREATE NONCLUSTERED INDEX [TEXT3]
    ON [dbo].[SUPPORT]([TEXT3] ASC);


GO
CREATE NONCLUSTERED INDEX [TEXT4]
    ON [dbo].[SUPPORT]([TEXT4] ASC);


GO
CREATE NONCLUSTERED INDEX [TEXT5]
    ON [dbo].[SUPPORT]([TEXT5] ASC);


GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- modified 10/16/14 YS re-named the trigger from DefCodeORPartClass_Delete to support_delete
-- to make it more general and add code for removing PRTMFGR 
-- Added begin transaction and TRY/CATCH block 
-- 11/02/15 YS change to use Invtmfhd table 
--10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
--- 08/01/17 part class setup is removed from support table and moved to partClass table
-- 05/05/2020 Sachin B add the condition to the Partmfgr linked with part but not deleted then only raise error
-- =============================================
CREATE TRIGGER [dbo].[Support_delete] 
   ON [dbo].[SUPPORT]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 11/02/15 YS declare error variables
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    -- Insert statements for trigger here
	-- check if deleted record was for the defect code
	

	IF EXISTS (SELECT CuDefDet.Def_code FROM Deleted INNER JOIN CuDefDet ON Deleted.Text2=CudefDet.Def_code WHERE deleted.FIELDNAME='DEF_CODE')
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			DELETE FROM CudefDet WHERE Def_code IN (SELECT rtrim(Text2) FROM DELETED where deleted.FIELDNAME='DEF_CODE')
			if @@TRANCOUNT<>0
			COMMIT

		END TRY
		BEGIN CATCH
			if @@TRANCOUNT<>0
				ROLLBACK
			RaisError('Support_deleted trigger failed to update CudefDet. This operation will be cancelled',11,1)
		END CATCH
		
		
	END -- IF EXISTS (SELECT CuDefDet.Def_code ...
	--- 08/01/17 part class setup is removed from support table and moved to partClass table
	----check if part class
	--IF EXISTS (SELECT Part_type FROM Deleted JOIN Parttype ON PartType.Part_class=RTRIM(LTRIM(Deleted.Text2)) WHERE deleted.FIELDNAME='PART_CLASS')
	--	BEGIN
	--		BEGIN TRANSACTION
	--		BEGIN TRY
	--			DELETE FROM PartType WHERE Part_class IN (SELECT Text2 FROM DELETED)
	--			if @@TRANCOUNT<>0
	--			COMMIT
	--		END TRY
	--		BEGIN CATCH
	--		if @@TRANCOUNT<>0
	--			ROLLBACK
	--			RaisError('Support_deleted trigger failed to update PartType. This operation will be cancelled',11,1)
	--		END CATCH
		
	--END --EXISTS (SELECT Part_type FROM Deleted JOIN Parttype ON PartType.Part_class=RTRIM(LTRIM(Deleted.Text2)) WHERE deleted.FIELDNAME='PART_CLASS')
	IF EXISTS (SELECT 1 FROM DELETED WHERE Deleted.FIELDNAME='PARTMFGR')
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
		-- 05/05/2020 Sachin B add the condition to the Partmfgr linked with part but not deleted then only raise error
			IF EXISTS(SELECT 1 from Invtmpnlink INNER JOIN MfgrMaster ON Invtmpnlink.mfgrMasterId=mfgrMaster.MfgrMasterId AND Invtmpnlink.is_deleted=0
						INNER JOIN Deleted ON MfgrMaster.PartMfgr=LEFT(Deleted.Text2,8))
				RaisError('Cannot remove manufacturer, that has already been used by system.',11,1)
			ELSE -- IF EXISTS(SELECT 1 from Invtmpnlink INNER 
				-- remove from MfgrMaster if exists
			Delete FROM mfgrmaster WHERE EXISTS (select 1 from Deleted where LEFT(Deleted.Text2,8)=MfgrMaster.PartMfgr)

			IF @@TRANCOUNT<>0
			COMMIT	
		end try
		begin catch
			if @@TRANCOUNT<>0
				ROLLBACK
				--11/02/15 YS create more informative error
				SELECT @ErrorMessage = ERROR_MESSAGE(),
				 @ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();
				RAISERROR (@ErrorMessage, -- Message text.
				@ErrorSeverity, -- Severity.
				 @ErrorState -- State.
				 );
			--RaisError('Support_deleted trigger failed. This operation will be cancelled',11,1)
		end catch
	END -- IF EXISTS (SELECT 1 FROM DELETED WHERE Deleted.FIELDNAME='PARTMFGR')
	--11/02/15 YS added remmoving records from unit table if U_of_meas is removed
	
	IF EXISTS (SELECT 1 FROM DELETED WHERE Deleted.FIELDNAME='U_OF_MEAS') and exists (select 1 from unit inner join deleted on [from]=ltrim(deleted.text) or [to]=ltrim(deleted.text))
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				DELETE FROM unit WHERE exists (select 1 from deleted where ltrim(deleted.text)=unit.[from] or ltrim(deleted.text)=unit.[to])
				if @@TRANCOUNT<>0
				COMMIT
			END TRY
			BEGIN CATCH
			if @@TRANCOUNT<>0
				ROLLBACK
				RaisError('Support_deleted trigger failed to update Unit table. This operation will be cancelled',11,1)
			END CATCH
		
	END --EXISTS (SELECT Part_type FROM Deleted JOIN Parttype ON PartType.Part_class=RTRIM(LTRIM(Deleted.Text2)) WHERE deleted.FIELDNAME='PART_CLASS')
	--10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
	--- 08/01/17 part class setup is removed from support table and moved to partClass table
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'SUPPORT'
           ,'UNIQFIELD'
           ,Deleted.UNIQFIELD from Deleted
		   WHERE (Deleted.FIELDNAME = 'TERRITORY'
			OR Deleted.FIELDNAME = 'CREDITOK'
			OR Deleted.FIELDNAME ='FOB'
			OR Deleted.FIELDNAME = 'SHIPVIA'
			OR Deleted.FIELDNAME='SHIPCHARGE'
			OR Deleted.FIELDNAME = 'SUPPL_STAT'
			--OR Deleted.FIELDNAME ='PART_CLASS'
			OR Deleted.FIELDNAME ='U_OF_MEAS'
			OR Deleted.FIELDNAME ='PART_PKG'
			OR Deleted.FIELDNAME='MRC' 
			OR Deleted.FIELDNAME='PARTMFGR')
			

END
GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 10/28/2015
-- Description:	Update trigger for IsSynchronization flag
-- 10/28/2015 : Sachin s -Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced
--08/01/2017 : YS move the code for the part-class to update trigger for partClass table
-- =============================================
CREATE TRIGGER [dbo].[SUPPORT_UPDATE]
   ON  [dbo].[SUPPORT]
   AFTER UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;
	UPDATE SUPPORT SET		
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END						
	 FROM inserted I inner join deleted D on i.UNIQFIELD=d.UNIQFIELD
			where I.UNIQFIELD =SUPPORT.UNIQFIELD  
			AND (
			I.FIELDNAME = 'TERRITORY'
			OR I.FIELDNAME = 'CREDITOK'
			OR I.FIELDNAME ='FOB' 
			OR I.FIELDNAME = 'SHIPVIA'
			OR I.FIELDNAME='SHIPCHARGE'
			OR I.FIELDNAME = 'SUPPL_STAT'
			--08/01/2017 : YS move the code for the part-class to update trigger for partClass table
			--OR I.FIELDNAME ='PART_CLASS'
			OR I.FIELDNAME ='U_OF_MEAS' 
			OR I.FIELDNAME ='PART_PKG' 
			OR I.FIELDNAME='MRC' 
			OR I.FIELDNAME='PARTMFGR'			
			)
			 --Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNIQFIELD=SynchronizationMultiLocationLog.Uniquenum);
			END									 
END

GO
-- =============================================  
-- Author:  Sachin B  
-- Create date: 12/24/2019  
-- Description: insert trigger for insert data into support table 
-- =============================================  
CREATE TRIGGER [dbo].[Support_Insert] ON [dbo].[SUPPORT]  
FOR INSERT 

AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 SET NOCOUNT ON;

	UPDATE SUPPORT  SET TEXT2 = I.TEXT FROM inserted I 
	INNER JOIN SUPPORT s ON s.UNIQFIELD = I.UNIQFIELD
	WHERE s.UNIQFIELD = I.UNIQFIELD  AND  I.FIELDNAME = 'SUP_TYPE'  		
END 