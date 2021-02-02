CREATE TABLE [dbo].[SYSPKG] (
    [PKG]                VARCHAR (15) CONSTRAINT [DF__SYSPKG__PKG__1ACAA75A] DEFAULT ('') NOT NULL,
    [DESCRIPT]           VARCHAR (30) CONSTRAINT [DF__SYSPKG__DESCRIPT__1BBECB93] DEFAULT ('') NOT NULL,
    [UNIQPKG]            CHAR (10)    CONSTRAINT [DF__SYSPKG__UNIQPKG__1CB2EFCC] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT          CONSTRAINT [DF__SYSPKG__IsSynchr__3CAD2017] DEFAULT ((0)) NULL,
    CONSTRAINT [SYSPKG_PK] PRIMARY KEY CLUSTERED ([UNIQPKG] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PKG]
    ON [dbo].[SYSPKG]([PKG] ASC);


GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 10/28/2015
-- Description:	Update trigger for IsSynchronization flag
-- 10/28/2015 : Sachin s -Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced
-- =============================================
CREATE TRIGGER [dbo].[SYSPKG_UPDATE]
   ON  [dbo].[SYSPKG]
   AFTER UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;
	UPDATE SYSPKG SET		
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END						
	 FROM inserted I inner join deleted D on i.UNIQPKG=d.UNIQPKG	
	 WHERE i.UNIQPKG=SYSPKG.UNIQPKG	
			 --Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNIQPKG=SynchronizationMultiLocationLog.Uniquenum);
			END									 
END
GO

-- =============================================
-- Author:		Sachins 
-- Create date:  10-30-2015
-- Description:	Insert the records in to the SynchronizationDeletedRecords tables
 --10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
-- =============================================
CREATE TRIGGER [dbo].[SYSPKG_delete] 
   ON [dbo].[SYSPKG]
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
           'SYSPKG'
           ,'UNIQPKG'
           ,Deleted.UNIQPKG from Deleted	  	   
		   
END