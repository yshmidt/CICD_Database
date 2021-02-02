CREATE TABLE [dbo].[ANTIAVL] (
    [BOMPARENT]          CHAR (10) CONSTRAINT [DF__ANTIAVL__BOMPARE__6EF57B66] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]           CHAR (10) CONSTRAINT [DF__ANTIAVL__UNIQ_KE__6FE99F9F] DEFAULT ('') NOT NULL,
    [PARTMFGR]           CHAR (8)  CONSTRAINT [DF__ANTIAVL__PARTMFG__70DDC3D8] DEFAULT ('') NOT NULL,
    [MFGR_PT_NO]         CHAR (30) CONSTRAINT [DF__ANTIAVL__MFGR_PT__71D1E811] DEFAULT ('') NOT NULL,
    [UNIQANTI]           CHAR (10) CONSTRAINT [DF__ANTIAVL__UNIQANT__72C60C4A] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT       CONSTRAINT [DF__ANTIAVL__IsSynch__6FE1E003] DEFAULT ((0)) NULL,
    CONSTRAINT [ANTIAVL_PK] PRIMARY KEY CLUSTERED ([UNIQANTI] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BOMPARENT]
    ON [dbo].[ANTIAVL]([BOMPARENT] ASC);


GO
CREATE NONCLUSTERED INDEX [BOMPARTMFG]
    ON [dbo].[ANTIAVL]([BOMPARENT] ASC, [UNIQ_KEY] ASC, [PARTMFGR] ASC, [MFGR_PT_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [PARTMFGR]
    ON [dbo].[ANTIAVL]([PARTMFGR] ASC);


GO
CREATE NONCLUSTERED INDEX [UKEYPTMFGR]
    ON [dbo].[ANTIAVL]([UNIQ_KEY] ASC, [PARTMFGR] ASC, [MFGR_PT_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[ANTIAVL]([UNIQ_KEY] ASC);


GO
-- =============================================
-- Author:Sachin shevale
-- Create date: <09/14/2015>
-- Description:	<Delete trigger for sync the records>
CREATE TRIGGER [dbo].[ANTIAVL_DELETE] 
   ON  [dbo].[ANTIAVL]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
	BEGIN TRANSACTION		
	--DELETE FROM ANTIAVL WHERE UNIQANTI in (SELECT UNIQANTI FROM Deleted)
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'ANTIAVL'
           ,'UNIQANTI'
           ,Deleted.UNIQANTI from Deleted
	COMMIT
END
GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 09/14/2014
-- Description:	Update trigger for sync the records
-- =============================================
CREATE TRIGGER [dbo].[ANTIAVL_UPDATE]
   ON  [dbo].[ANTIAVL]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE ANTIAVL SET 
    -- Insert statements for trigger here
	 IsSynchronizedFlag= 
						CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
					    WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END					
					FROM inserted I inner join deleted D on i.UNIQANTI=d.UNIQANTI
					where I.UNIQANTI =ANTIAVL.UNIQANTI  		
		 --09-24-2015 Delete the Uniquenum from SynchronizationMultiLocationLog table if exists with same UNIQ_KEY so all location pick again
		IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
				BEGIN
				DELETE FROM SynchronizationMultiLocationLog 
					where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNIQANTI=SynchronizationMultiLocationLog.Uniquenum);
				END		
END