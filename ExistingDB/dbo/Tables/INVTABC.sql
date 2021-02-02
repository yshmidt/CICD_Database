CREATE TABLE [dbo].[INVTABC] (
    [ABC_TYPE]           CHAR (1)       CONSTRAINT [DF__INVTABC1__ABC_TY__6B06859F] DEFAULT ('') NOT NULL,
    [ABC_DESCR]          CHAR (15)      CONSTRAINT [DF__INVTABC1__ABC_DE__6BFAA9D8] DEFAULT ('') NOT NULL,
    [ABCSOURCE]          CHAR (4)       CONSTRAINT [DF__INVTABC1__ABCSOU__6CEECE11] DEFAULT ('') NOT NULL,
    [CC_DAYS]            NUMERIC (3)    CONSTRAINT [DF__INVTABC1__CC_DAY__6DE2F24A] DEFAULT ((0)) NOT NULL,
    [D_TO_S]             NUMERIC (3)    CONSTRAINT [DF__INVTABC1__D_TO_S__6ED71683] DEFAULT ((0)) NOT NULL,
    [CC_PCT]             NUMERIC (5, 2) CONSTRAINT [DF__INVTABC1__CC_PCT__6FCB3ABC] DEFAULT ((0)) NOT NULL,
    [CC_AMT]             NUMERIC (5)    CONSTRAINT [DF__INVTABC1__CC_AMT__70BF5EF5] DEFAULT ((0)) NOT NULL,
    [ABCPCT]             NUMERIC (3)    CONSTRAINT [DF__INVTABC1__ABCPCT__71B3832E] DEFAULT ((0)) NOT NULL,
    [ABCLT]              NUMERIC (4)    CONSTRAINT [DF__INVTABC1__ABCLT__72A7A767] DEFAULT ((0)) NOT NULL,
    [UNIQUENUM]          INT            IDENTITY (1, 1) NOT NULL,
    [IsSynchronizedFlag] BIT            CONSTRAINT [DF__INVTABC__IsSynch__37E86AFA] DEFAULT ((0)) NULL,
    CONSTRAINT [INVTABC_PK] PRIMARY KEY CLUSTERED ([UNIQUENUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ABC_TYPE]
    ON [dbo].[INVTABC]([ABC_TYPE] ASC);


GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 10/28/2015
-- Description:	Update trigger for IsSynchronization flag
-- 10/28/2015 : Sachin s -Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced
-- 11/24/2015 :Sachin s- does not update IsSynchronizedFlag update
-- =============================================
CREATE TRIGGER [dbo].[InvtAbc_UPDATE]
   ON  [dbo].[INVTABC]
   AFTER UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;
	UPDATE InvtAbc SET		
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1	
							   ---- 11/24/2015 :Sachin s- does not update IsSynchronizedFlag update
						ELSE 0 END						
	 FROM inserted I inner join deleted D on i.UNIQUENUM=d.UNIQUENUM	
	 	where I.UNIQUENUM =InvtAbc.UNIQUENUM  				
			 --Delete the records from SynchronizationMultiLocationLog table if any of the location is pending to be synced 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and  CONVERT(VARCHAR, CONVERT(VARCHAR(10), inserted.UNIQUENUM))=SynchronizationMultiLocationLog.Uniquenum);
			END									 
END

GO

-- =============================================
-- Author:		Sachins 
-- Create date:  10-30-2015
-- Description:	Insert the records in to the SynchronizationDeletedRecords tables
 --10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
-- =============================================
CREATE TRIGGER [dbo].[INVTABC_delete] 
   ON [dbo].[INVTABC]
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
           'INVTABC'
           ,'UNIQUENUM'
           ,Deleted.UNIQUENUM from Deleted	  	   
		   
END
