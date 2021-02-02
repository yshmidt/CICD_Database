CREATE TABLE [dbo].[UNIT] (
    [FROM]               CHAR (4)        CONSTRAINT [DF_UNIT_FROM] DEFAULT ('') NOT NULL,
    [TO]                 CHAR (4)        CONSTRAINT [DF_UNIT_TO] DEFAULT ('') NOT NULL,
    [FORMULA]            NUMERIC (12, 5) CONSTRAINT [DF_UNIT_FORMULA] DEFAULT ((0)) NOT NULL,
    [UNIQUENUM]          INT             IDENTITY (1, 1) NOT NULL,
    [IsSynchronizedFlag] BIT             CONSTRAINT [DF__UNIT__IsSynchron__3E956889] DEFAULT ((0)) NULL,
    CONSTRAINT [UNIT_PK] PRIMARY KEY CLUSTERED ([UNIQUENUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FROM]
    ON [dbo].[UNIT]([FROM] ASC);


GO
CREATE NONCLUSTERED INDEX [TO]
    ON [dbo].[UNIT]([TO] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/07/2020
-- Description:	Make sure no duplicate conversion is entered
-- =============================================
CREATE TRIGGER [dbo].[UNIT_INSERT]
   ON  [dbo].[UNIT]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	-- Insert statements for trigger here
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRY
	BEGIN TRANSACTION
	/*Test
		select * from unit inner join inserted i on unit.[from]=i.[FROM] and unit.[to] = i.[to]
		select * from unit inner join inserted i on unit.[from]=i.[to] and unit.[to] = i.[FROM]
	*/
	-- sinse inserted is goign to show in the UNIT table already 
	-- the condition should include both FROM=FROM and FROM=TO
		if exists (select 1 from unit inner join inserted i on unit.[from]=i.[FROM] and unit.[to] = i.[to]) and exists (select 1 from unit inner join inserted i on unit.[from]=i.[to] and unit.[to] = i.[FROM])
		BEGIN
			--- error will be raised in the catch block
			RAISERROR ('Cannot enter conversion for the same units more than once.', -- Message text.  
			16, -- Severity.  
			1 -- State.  
			);  
		END
	IF @@TRANCOUNT>0  
		COMMIT    
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage = ERROR_MESSAGE(),  
	    @ErrorSeverity = ERROR_SEVERITY(),  
		@ErrorState = ERROR_STATE();  

		IF @@TRANCOUNT>0  
		ROLLBACK    
		RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  
	
	END CATCH

END
GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 11/2/2015
-- Description:	Update trigger for IsSynchronization flag
-- =============================================
CREATE TRIGGER [dbo].[UNIT_UPDATE]
   ON  [dbo].[UNIT]
   AFTER UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;
	UPDATE UNIT SET		
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END						
	 FROM inserted I inner join deleted D on i.UNIQUENUM=d.UNIQUENUM
	 where I.UNIQUENUM = UNIT.UNIQUENUM
				     
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and  CONVERT(VARCHAR, CONVERT(VARCHAR(10), inserted.UNIQUENUM)) =SynchronizationMultiLocationLog.Uniquenum);
			END									 
END

GO

-- =============================================
-- Author:	sachin s
-- Create date: 10-30-2015
-- Description:	Insert the records in to the SynchronizationDeletedRecords tables for synchronization 
-- =============================================
CREATE TRIGGER [dbo].[UNIT_delete] 
   ON [dbo].[UNIT]
   AFTER DELETE
AS 
BEGIN
	 --Sachins s-Insert the records in to the SynchronizationDeletedRecords tables
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'UNIT'
           ,'UNIQUENUM'
           ,Deleted.UNIQUENUM from Deleted
		    
		   
END


