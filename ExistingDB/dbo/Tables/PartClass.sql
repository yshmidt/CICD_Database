CREATE TABLE [dbo].[PartClass] (
    [part_class]         NVARCHAR (8)     CONSTRAINT [DF_PartClass_part_class] DEFAULT ('') NOT NULL,
    [classDescription]   NVARCHAR (50)    CONSTRAINT [DF_PartClass_classDescription] DEFAULT ('') NOT NULL,
    [useIpkey]           BIT              CONSTRAINT [DF_PartClass_useIpkey] DEFAULT ((1)) NOT NULL,
    [classUnique]        CHAR (10)        CONSTRAINT [DF_PartClass_classUnique] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [uniqwh]             CHAR (10)        CONSTRAINT [DF_PartClass_uniqwh] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT              CONSTRAINT [DF_PartClass_IsSynchronizedFlag] DEFAULT ((0)) NOT NULL,
    [aspnetBuyer]        UNIQUEIDENTIFIER NULL,
    [AllowAutokit]       BIT              CONSTRAINT [DF_PartClass_AllowAutokit] DEFAULT ((1)) NOT NULL,
    [classPrefix]        NCHAR (3)        CONSTRAINT [DF_PartClass_classPrefix] DEFAULT ('') NOT NULL,
    [numberGenerator]    NVARCHAR (20)    CONSTRAINT [DF_PartClass_numberGenerator] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_PartClass] PRIMARY KEY NONCLUSTERED ([classUnique] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX_PartClass]
    ON [dbo].[PartClass]([part_class] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PartClass_1]
    ON [dbo].[PartClass]([IsSynchronizedFlag] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/01/17
-- Description:	update sync flag
-- =============================================
CREATE TRIGGER partClass_update
   ON  partClass
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   
	UPDATE partClass SET		
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END						
	 FROM inserted I inner join deleted D on i.classUnique=d.classUnique
	
	 --Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced 
	IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
	BEGIN
	DELETE FROM SynchronizationMultiLocationLog 
		where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.classUnique=SynchronizationMultiLocationLog.Uniquenum);
	END									 




END
GO

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/01/2017
-- Description: trigger used in sync for the new partclass table
-- =============================================
CREATE TRIGGER [dbo].[partClass_Delete] 
   ON [dbo].[partClass]
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
	

	
		

	
	--check if part class
	IF EXISTS (SELECT Part_type FROM Deleted JOIN Parttype ON PartType.Part_class=Deleted.Part_class)
		BEGIN
			BEGIN TRANSACTION
			BEGIN TRY
				DELETE FROM PartType WHERE Part_class IN (SELECT part_class FROM DELETED)
				if @@TRANCOUNT<>0
				COMMIT
			END TRY
			BEGIN CATCH
			if @@TRANCOUNT<>0
				ROLLBACK
				RaisError('Support_deleted trigger failed to update PartType. This operation will be cancelled',11,1)
			END CATCH
		
	END --EXISTS (SELECT Part_type FROM Deleted JOIN Parttype ON PartType.Part_class=RTRIM(LTRIM(Deleted.Text2)) WHERE deleted.FIELDNAME='PART_CLASS')
	--10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'PartClass'
           ,'classUnique'
           ,Deleted.classUnique from Deleted
		  

END