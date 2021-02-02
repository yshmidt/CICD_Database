CREATE TABLE [dbo].[SHIPTAX] (
    [UNQSHIPTAX]         CHAR (10)      CONSTRAINT [DF__SHIPTAX__UNQSHIP__5C4364FC] DEFAULT ('') NOT NULL,
    [LINKADD]            CHAR (10)      CONSTRAINT [DF__SHIPTAX__LINKADD__5D378935] DEFAULT ('') NOT NULL,
    [CUSTNO]             CHAR (10)      CONSTRAINT [DF__SHIPTAX__CUSTNO__5E2BAD6E] DEFAULT ('') NOT NULL,
    [ADDRESS1]           CHAR (35)      CONSTRAINT [DF__SHIPTAX__ADDRESS__5F1FD1A7] DEFAULT ('') NOT NULL,
    [TAXDESC]            CHAR (25)      CONSTRAINT [DF__SHIPTAX__TAXDESC__6013F5E0] DEFAULT ('') NOT NULL,
    [TAXTYPE]            CHAR (1)       CONSTRAINT [DF__SHIPTAX__TAXTYPE__61081A19] DEFAULT ('') NOT NULL,
    [TAX_RATE]           NUMERIC (8, 4) CONSTRAINT [DF__SHIPTAX__TAX_RAT__61FC3E52] DEFAULT ((0)) NOT NULL,
    [TAX_ID]             CHAR (8)       CONSTRAINT [DF__SHIPTAX__TAX_ID__62F0628B] DEFAULT ('') NOT NULL,
    [RECORDTYPE]         CHAR (1)       CONSTRAINT [DF__SHIPTAX__RECORDT__63E486C4] DEFAULT ('') NOT NULL,
    [PTPROD]             BIT            CONSTRAINT [DF__SHIPTAX__PTPROD__64D8AAFD] DEFAULT ((0)) NOT NULL,
    [PTFRT]              BIT            CONSTRAINT [DF__SHIPTAX__PTFRT__65CCCF36] DEFAULT ((0)) NOT NULL,
    [STPROD]             BIT            CONSTRAINT [DF__SHIPTAX__STPROD__66C0F36F] DEFAULT ((0)) NOT NULL,
    [STFRT]              BIT            CONSTRAINT [DF__SHIPTAX__STFRT__67B517A8] DEFAULT ((0)) NOT NULL,
    [STTX]               BIT            CONSTRAINT [DF__SHIPTAX__STTX__68A93BE1] DEFAULT ((0)) NOT NULL,
    [modifiedDate]       DATETIME       NULL,
    [DefaultTax]         BIT            CONSTRAINT [DF__SHIPTAX__Default__78EB5BF9] DEFAULT ((0)) NOT NULL,
    [IsSynchronizedFlag] BIT            CONSTRAINT [DF__SHIPTAX__IsSynch__61C8CAD6] DEFAULT ((0)) NULL,
    [TAXUNIQUE]          VARCHAR (20)   CONSTRAINT [DF__SHIPTAX__TAXUNIQ__3E0CEF52] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [SHIPTAX_PK] PRIMARY KEY CLUSTERED ([UNQSHIPTAX] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LINKCUSTTX]
    ON [dbo].[SHIPTAX]([LINKADD] ASC, [CUSTNO] ASC, [TAXTYPE] ASC, [TAX_ID] ASC, [RECORDTYPE] ASC);


GO
CREATE NONCLUSTERED INDEX [SHIPTAX]
    ON [dbo].[SHIPTAX]([CUSTNO] ASC, [ADDRESS1] ASC, [TAXDESC] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/24/2014
-- Description:	Update trigger to save date/tiem when record was updated
--Sachin s 10-30-2015 Set the isSynchronized flag 0 when change the something
-- =============================================
CREATE TRIGGER [dbo].[SHIPTAX_UPDATE]
   ON  [dbo].[SHIPTAX]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--UPDATE SHIPTAX SET modifiedDate =GETDATE() where SHIPTAX.UNQSHIPTAX  IN (SELECT UNQSHIPTAX from inserted)
    -- Insert statements for trigger here

	UPDATE SHIPTAX SET		
			modifiedDate =GETDATE(),
	--Sachin s 10-30-2015 Set the isSynchronized flag 0 when change the something
			IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END									
	 FROM inserted I inner join deleted D on i.UNQSHIPTAX=d.UNQSHIPTAX
	 	where  i.UNQSHIPTAX=SHIPTAX.UNQSHIPTAX	
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNQSHIPTAX=SynchronizationMultiLocationLog.Uniquenum);
			END					


END
GO

-- =============================================
-- Author:		Sachins 
-- Create date:  10-30-2015
-- Description:	Insert the records in to the SynchronizationDeletedRecords tables
 --10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
-- =============================================
CREATE TRIGGER [dbo].[ShipTax_delete] 
   ON [dbo].[ShipTax]
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
           'SHIPTAX'
           ,'UNQSHIPTAX'
           ,Deleted.UNQSHIPTAX from Deleted	  	   
		   
END
