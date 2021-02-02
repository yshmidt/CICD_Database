CREATE TABLE [dbo].[INVTMFSP] (
    [UNIQMFGRHD]         CHAR (10) CONSTRAINT [DF__INVTMFSP__UNIQMF__5DE0C954] DEFAULT ('') NOT NULL,
    [UNIQMFSP]           CHAR (10) CONSTRAINT [DF__INVTMFSP__UNIQMF__5ED4ED8D] DEFAULT ('') NOT NULL,
    [uniqsupno]          CHAR (10) CONSTRAINT [DF_INVTMFSP_uniqsupno] DEFAULT ('') NOT NULL,
    [SUPLPARTNO]         CHAR (30) CONSTRAINT [DF__INVTMFSP__SUPLPA__60BD35FF] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]           CHAR (10) CONSTRAINT [DF__INVTMFSP__UNIQ_K__61B15A38] DEFAULT ('') NOT NULL,
    [PFDSUPL]            BIT       CONSTRAINT [DF__INVTMFSP__PFDSUP__62A57E71] DEFAULT ((0)) NOT NULL,
    [IS_DELETED]         BIT       CONSTRAINT [DF__INVTMFSP__IS_DEL__6399A2AA] DEFAULT ((0)) NOT NULL,
    [IsSynchronizedFlag] BIT       CONSTRAINT [DF__INVTMFSP__IsSync__5796207D] DEFAULT ((0)) NULL,
    CONSTRAINT [INVTMFSP_PK] PRIMARY KEY CLUSTERED ([UNIQMFSP] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SUPLPARTNO]
    ON [dbo].[INVTMFSP]([SUPLPARTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[INVTMFSP]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFGRHD]
    ON [dbo].[INVTMFSP]([UNIQMFGRHD] ASC);


GO
CREATE NONCLUSTERED INDEX [uniqsupno]
    ON [dbo].[INVTMFSP]([uniqsupno] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);


GO
-- =============================================
-- Author:		Sachin S
-- Create date: 10/03/2015
-- Description:	Sachins S -update IsSynchronizedFlag to 0,WHEN update the from web service		
-- =============================================
CREATE TRIGGER [dbo].[INVTMFSP_Update]
   ON  [dbo].[INVTMFSP] 
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	
	-- 10/03/15  Sachins S -update IsSynchronizedFlag to 0,WHEN update the from web service		
	update INVTMFSP set IsSynchronizedFlag=
						  CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END
			FROM inserted I inner join deleted D on i.UNIQMFSP=d.UNIQMFSP
			where I.UNIQMFSP =INVTMFSP.UNIQMFSP 
	-- 10/03/15  Sachins S -delete the record from SynchronizationMultiLocationLog while upadte the records  
	--if one location already synchronized and other location not getting synchronized
		IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			    DELETE FROM SynchronizationMultiLocationLog 
				WHERE EXISTS (SELECT 1 FROM Inserted where IsSynchronizedFlag=0 and Inserted.UNIQMFSP=SynchronizationMultiLocationLog.Uniquenum);
			END 

	COMMIT
    -- Insert statements for trigger here

END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/27/2013
-- Description:	When record is removed then Insert the record in to the SynchronizationDeletedRecords for synchronization
-- =============================================
CREATE TRIGGER [dbo].[INVTMFSP_Delete] 
   ON  [dbo].[INVTMFSP] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	--10/03/15 sachins-Insert the record in to the SynchronizationDeletedRecords
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'INVTMFSP'
           ,'UNIQMFSP'
           ,Deleted.UNIQMFSP
		    from Deleted
	COMMIT
    -- Insert statements for trigger here

END
