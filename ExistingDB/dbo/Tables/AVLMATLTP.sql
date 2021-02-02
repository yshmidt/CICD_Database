CREATE TABLE [dbo].[AVLMATLTP] (
    [UQAVLMATTP]         CHAR (10) CONSTRAINT [DF__AVLMATLTP__UQAVL__2882FE7D] DEFAULT ('') NOT NULL,
    [AVLMATLTYPE]        CHAR (10) CONSTRAINT [DF__AVLMATLTP__AVLMA__297722B6] DEFAULT ('') NOT NULL,
    [AVLMATLTYPEDESC]    CHAR (30) CONSTRAINT [DF__AVLMATLTP__AVLMA__2A6B46EF] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT       CONSTRAINT [DF__AVLMATLTP__IsSyn__36F446C1] DEFAULT ((0)) NULL,
    CONSTRAINT [AVLMATLTP_PK] PRIMARY KEY CLUSTERED ([UQAVLMATTP] ASC)
);


GO
CREATE NONCLUSTERED INDEX [AVLMATLTP]
    ON [dbo].[AVLMATLTP]([AVLMATLTYPE] ASC);


GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 10/28/2015
-- Description:	Update trigger for IsSynchronization flag
-- =============================================
CREATE TRIGGER [dbo].[AVLMATLTP_UPDATE]
   ON  [dbo].[AVLMATLTP]
   AFTER UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;
	UPDATE AVLMATLTP SET		
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END						
	 FROM inserted I inner join deleted D on i.UQAVLMATTP=d.UQAVLMATTP
			where I.UQAVLMATTP =AVLMATLTP.UQAVLMATTP  				     
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UQAVLMATTP=SynchronizationMultiLocationLog.Uniquenum);
			END									 
END
GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/09/2009
-- Description:	Run after AvlMatlTp record is deleted
--10/30/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
-- =============================================
CREATE TRIGGER [dbo].[AvlMatlTp_Delete]
   ON  [dbo].[AVLMATLTP]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRANSACTION 
	DELETE FROM MatTpLogic WHERE UqAvlMatTp IN (SELECT UqAvlMatTp FROM DELETED)
	COMMIT

	 --10/30/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'AVLMATLTP'
           ,'UQAVLMATTP'
           ,Deleted.UQAVLMATTP from Deleted
END