CREATE TABLE [dbo].[PMTTERMS] (
    [NUMBER]             NUMERIC (3)    CONSTRAINT [DF__PMTTERMS2__NUMBE__70F4691F] DEFAULT ((0)) NOT NULL,
    [DESCRIPT]           CHAR (15)      CONSTRAINT [DF__PMTTERMS2__DESCR__71E88D58] DEFAULT ('') NOT NULL,
    [PMT_DAYS]           NUMERIC (3)    CONSTRAINT [DF__PMTTERMS2__PMT_D__72DCB191] DEFAULT ((0)) NOT NULL,
    [DISC_DAYS]          NUMERIC (3)    CONSTRAINT [DF__PMTTERMS2__DISC___73D0D5CA] DEFAULT ((0)) NOT NULL,
    [DISC_PCT]           NUMERIC (4, 1) CONSTRAINT [DF__PMTTERMS2__DISC___74C4FA03] DEFAULT ((0)) NOT NULL,
    [UNIQUENUM]          INT            IDENTITY (1, 1) NOT NULL,
    [isQBSync]           BIT            CONSTRAINT [DF_PMTTERMS_isQBSync] DEFAULT ((0)) NOT NULL,
    [IsSynchronizedFlag] BIT            CONSTRAINT [DF__PMTTERMS__IsSync__39D0B36C] DEFAULT ((0)) NULL,
    CONSTRAINT [PMTTERMS_PK] PRIMARY KEY CLUSTERED ([UNIQUENUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [DESCRIPT]
    ON [dbo].[PMTTERMS]([DESCRIPT] ASC);


GO
CREATE NONCLUSTERED INDEX [isQBSync]
    ON [dbo].[PMTTERMS]([isQBSync] ASC);


GO
CREATE NONCLUSTERED INDEX [NUMBER]
    ON [dbo].[PMTTERMS]([NUMBER] ASC);


GO

-- =============================================
-- Author:		Sachins 
-- Create date:  10-30-2015
-- Description:	Insert the records in to the SynchronizationDeletedRecords tables
 --10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
-- =============================================
CREATE TRIGGER [dbo].[PmtTerms_delete] 
   ON [dbo].[PmtTerms]
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
           'PMTTERMS'
           ,'UNIQUENUM'
           ,Deleted.UNIQUENUM from Deleted	  	   
		   
END

GO
-- =============================================
-- Author:Anuj
-- Create date: 09/23/2015 
-- Description:	Update trigger for PmtTerms table and set IsQbSync flag to zero
--Sachin s 10-30-2015 Set the isSynchronized flag 0 when change the something
-- =============================================
CREATE TRIGGER [dbo].[PmtTerms_Update] 
   ON  [dbo].[PMTTERMS] 
   AFTER UPDATE
AS 
BEGIN	
	  Update PMTTERMS SET isQBSync= 
						     CASE WHEN (I.isQBSync = 1 and D.isQBSync = 1) THEN 0
						       WHEN (I.isQBSync = 1 and D.isQBSync = 0) THEN 1
						ELSE 0 END,
						--Sachin s 10-30-2015 Set the isSynchronized flag 0 when change the something
			IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END							
							FROM inserted I inner join deleted D on i.UNIQUENUM=d.UNIQUENUM
					where I.UNIQUENUM = PMTTERMS.UNIQUENUM

	IF EXISTS (SELECT 1 FROM inserted where IsQbSync=0 OR IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where (IsQbSync=0 OR IsSynchronizedFlag=0) and  CONVERT(VARCHAR, CONVERT(VARCHAR(10), Inserted.UNIQUENUM)) = SynchronizationMultiLocationLog.Uniquenum);
			END		
END