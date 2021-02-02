CREATE TABLE [dbo].[TAXTABL] (
    [TAX_ID]             CHAR (8)       CONSTRAINT [DF__TAXTABL__TAX_ID__1F8F5C77] DEFAULT ('') NOT NULL,
    [TAXDESC]            CHAR (25)      CONSTRAINT [DF__TAXTABL__TAXDESC__208380B0] DEFAULT ('') NOT NULL,
    [GL_NBR_IN]          CHAR (13)      CONSTRAINT [DF__TAXTABL__GL_NBR___2177A4E9] DEFAULT ('') NOT NULL,
    [GL_NBR_OUT]         CHAR (13)      CONSTRAINT [DF__TAXTABL__GL_NBR___226BC922] DEFAULT ('') NOT NULL,
    [TAX_RATE]           NUMERIC (8, 4) CONSTRAINT [DF__TAXTABL__TAX_RAT__235FED5B] DEFAULT ((0)) NOT NULL,
    [TAXTYPE]            CHAR (15)      CONSTRAINT [DF__TAXTABL__TAXTYPE__24541194] DEFAULT ('') NULL,
    [FOREIGNTAX]         BIT            CONSTRAINT [DF__TAXTABL__FOREIGN__2918C6B1] DEFAULT ((0)) NOT NULL,
    [FOREIGNTP]          CHAR (10)      CONSTRAINT [DF__TAXTABL__FOREIGN__2A0CEAEA] DEFAULT ('') NOT NULL,
    [PTPROD]             BIT            CONSTRAINT [DF__TAXTABL__PTPROD__2B010F23] DEFAULT ((0)) NOT NULL,
    [PTFRT]              BIT            CONSTRAINT [DF__TAXTABL__PTFRT__2BF5335C] DEFAULT ((0)) NOT NULL,
    [STPROD]             BIT            CONSTRAINT [DF__TAXTABL__STPROD__2CE95795] DEFAULT ((0)) NOT NULL,
    [STFRT]              BIT            CONSTRAINT [DF__TAXTABL__STFRT__2DDD7BCE] DEFAULT ((0)) NOT NULL,
    [STTX]               BIT            CONSTRAINT [DF__TAXTABL__STTX__2ED1A007] DEFAULT ((0)) NOT NULL,
    [TAXUNIQUE]          CHAR (10)      CONSTRAINT [DF__TAXTABL__TAXUNIQ__2FC5C440] DEFAULT ('') NOT NULL,
    [IsQbSync]           BIT            CONSTRAINT [DF__TAXTABL__IsQbSyn__7061CE47] DEFAULT ((0)) NULL,
    [IsSynchronizedFlag] BIT            CONSTRAINT [DF__TAXTABL__IsSynch__3DA14450] DEFAULT ((0)) NULL,
    [IsProductTotal]     BIT            CONSTRAINT [DF__TAXTABL__IsProdu__6D66FCB9] DEFAULT ((0)) NULL,
    [IsFreightTotals]    BIT            CONSTRAINT [DF__TAXTABL__IsFreig__6E5B20F2] DEFAULT ((0)) NULL,
    [TaxApplicableTo]    CHAR (10)      CONSTRAINT [DF__TAXTABL__TaxAppl__70436964] DEFAULT ('') NULL,
    CONSTRAINT [TAXTABL_PK] PRIMARY KEY CLUSTERED ([TAXUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [TAX_ID]
    ON [dbo].[TAXTABL]([TAX_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [TAXDESC]
    ON [dbo].[TAXTABL]([TAXDESC] ASC);


GO

-- =============================================
-- Author:		Sachins 
-- Create date:  10-30-2015
-- Description:	Insert the records in to the SynchronizationDeletedRecords tables
 --10/28/15 sachins s-Insert the records in to the SynchronizationDeletedRecords tables
-- =============================================
CREATE TRIGGER [dbo].[TaxTabl_delete] 
   ON [dbo].[TaxTabl]
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
           'TAXTABL'
           ,'TAXUNIQUE'
           ,Deleted.TAXUNIQUE from Deleted	  	   
		   
END
GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 10/28/2015
-- Description:	Update trigger for IsSynchronization flag
--Sachin s 10-30-2015 Set the isSynchronized flag 0 when change the something
--Anuj K 01-13-2016 Modified the isqbsync flag
-- =============================================
CREATE TRIGGER [dbo].[TaxTabl_Update]
   ON  [dbo].[TAXTABL]
   AFTER UPDATE
AS 
BEGIN	
	SET NOCOUNT ON;
	--Anuj K 01-13-2016 Modified the isqbsync flag
	UPDATE TAXTABL SET		
	  IsQbSync= CASE WHEN (I.IsQbSync = 1 and D.IsQbSync = 1) THEN 0
					WHEN (I.IsQbSync = 1 and D.IsQbSync = 0) THEN 1					 
					ELSE 0 END,
	--Sachin s 10-30-2015 Set the isSynchronized flag 0 when change the something
			IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) 		
								THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1					 
						ELSE 0 END									
	 FROM inserted I inner join deleted D on i.TAXUNIQUE=d.TAXUNIQUE
	  WHERE i.TAXUNIQUE=TAXTABL.TAXUNIQUE	
			IF EXISTS (SELECT 1 FROM inserted where IsQbSync=0 OR IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where (IsQbSync=0 OR IsSynchronizedFlag=0) and Inserted.TAXUNIQUE=SynchronizationMultiLocationLog.Uniquenum);
			END									 
END
