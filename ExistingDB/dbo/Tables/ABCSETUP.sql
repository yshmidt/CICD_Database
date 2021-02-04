CREATE TABLE [dbo].[ABCSETUP] (
    [UNIQABC]            CHAR (10)     CONSTRAINT [DF__ABCSETUP__UNIQAB__7C8480AE] DEFAULT ('') NOT NULL,
    [EAUEXCLDAY]         NUMERIC (5)   CONSTRAINT [DF__ABCSETUP__EAUEXC__7D78A4E7] DEFAULT ((0)) NOT NULL,
    [abcbase]            NUMERIC (1)   CONSTRAINT [DF_ABCSETUP_ABCBASE] DEFAULT ((0)) NOT NULL,
    [eaufactor]          NUMERIC (3)   CONSTRAINT [DF_ABCSETUP_eaufactor] DEFAULT ((0)) NOT NULL,
    [LASTEAU]            SMALLDATETIME NULL,
    [notinstore]         BIT           CONSTRAINT [DF_ABCSETUP_notinstore] DEFAULT ((0)) NULL,
    [IsSynchronizedFlag] BIT           CONSTRAINT [DF__ABCSETUP__IsSync__36002288] DEFAULT ((0)) NULL,
    CONSTRAINT [ABCSETUP_PK] PRIMARY KEY CLUSTERED ([UNIQABC] ASC)
);


GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 10/28/2015
-- Description:	Update trigger for IsSynchronization flag
-- 10/28/2015 : Sachin s -Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced
-- =============================================
CREATE TRIGGER [dbo].[ABCSETUP_UPDATE]
   ON  [dbo].[ABCSETUP]
   AFTER UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;
	UPDATE ABCSETUP SET		
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END						
	 FROM inserted I inner join deleted D on i.UNIQABC=d.UNIQABC
	 	where I.UNIQABC = ABCSETUP.UNIQABC
			 --Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNIQABC=SynchronizationMultiLocationLog.Uniquenum);
			END									 
END
GO

-- =============================================
-- Author:		Sachins 
-- Create date:  10-30-2015
-- Description:	Insert the records in to the SynchronizationDeletedRecords tables
 --10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
-- =============================================
CREATE TRIGGER [dbo].[ABCSETUP_delete] 
   ON [dbo].[ABCSETUP]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 --10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'ABCSETUP'
           ,'UNIQABC'
           ,Deleted.UNIQABC from Deleted	  	   
		   
END