CREATE TABLE [dbo].[BOM_ALT] (
    [BOMPARENT]          CHAR (10) CONSTRAINT [DF__BOM_ALT__BOMPARE__02284B6B] DEFAULT ('') NOT NULL,
    [ALT_FOR]            CHAR (10) CONSTRAINT [DF__BOM_ALT__ALT_FOR__031C6FA4] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]           CHAR (10) CONSTRAINT [DF__BOM_ALT__UNIQ_KE__041093DD] DEFAULT ('') NOT NULL,
    [BOMALTUNIQ]         CHAR (10) CONSTRAINT [DF__BOM_ALT__BOMALTU__0504B816] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT       CONSTRAINT [DF__BOM_ALT__IsSynch__70D6043C] DEFAULT ((0)) NULL,
    CONSTRAINT [BOM_ALT_PK] PRIMARY KEY CLUSTERED ([BOMALTUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ALT_FOR]
    ON [dbo].[BOM_ALT]([ALT_FOR] ASC);


GO
CREATE NONCLUSTERED INDEX [BOMPARENT]
    ON [dbo].[BOM_ALT]([BOMPARENT] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[BOM_ALT]([UNIQ_KEY] ASC);


GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 09/14/2014
-- Description:	Update trigger for  table
-- =============================================
CREATE TRIGGER [dbo].[BOM_ALT_UPDATE]
   ON  [dbo].[BOM_ALT]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE BOM_ALT SET 
    -- Insert statements for trigger here
	 IsSynchronizedFlag= 
						CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
					    WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END					
					FROM inserted I inner join deleted D on i.BOMALTUNIQ=d.BOMALTUNIQ
					where I.BOMALTUNIQ =BOM_ALT.BOMALTUNIQ  
		--09-24-2015 Delete the Uniquenum from SynchronizationMultiLocationLog table if exists with same UNIQ_KEY so all location pick again
		IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
				BEGIN
				DELETE FROM SynchronizationMultiLocationLog 
					where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.BOMALTUNIQ=SynchronizationMultiLocationLog.Uniquenum);
				END		
END
GO
-- =============================================
-- Author:Sachin shevale
-- Create date: <09/14/2015>
-- Description:	<Delete trigger for sync the records>
CREATE TRIGGER [dbo].[BOM_ALT_DELETE] 
   ON  [dbo].[BOM_ALT]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
	BEGIN TRANSACTION		
 -- DELETE FROM BOM_ALT WHERE BOMALTUNIQ in (SELECT BOMALTUNIQ FROM Deleted)
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'BOM_ALT'
           ,'BOMALTUNIQ'
           ,Deleted.BOMALTUNIQ from Deleted
	COMMIT
END