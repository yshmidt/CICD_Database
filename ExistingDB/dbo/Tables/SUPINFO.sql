CREATE TABLE [dbo].[SUPINFO] (
    [UNIQSUPNO]          CHAR (10)       CONSTRAINT [DF__SUPINFO__UNIQSUP__683F278D] DEFAULT ('') NOT NULL,
    [SUPID]              CHAR (10)       CONSTRAINT [DF__SUPINFO__SUPID__69334BC6] DEFAULT ('') NOT NULL,
    [SUPNAME]            CHAR (50)       CONSTRAINT [DF__SUPINFO__SUPNAME__6A276FFF] DEFAULT ('') NULL,
    [SUP_TYPE]           CHAR (15)       CONSTRAINT [DF__SUPINFO__SUP_TYP__6B1B9438] DEFAULT ('') NOT NULL,
    [ACCTNO]             CHAR (15)       CONSTRAINT [DF__SUPINFO__ACCTNO__6C0FB871] DEFAULT ('') NOT NULL,
    [STATUS]             CHAR (16)       CONSTRAINT [DF__SUPINFO__STATUS__6D03DCAA] DEFAULT ('') NOT NULL,
    [PHONE]              CHAR (19)       CONSTRAINT [DF__SUPINFO__PHONE__6DF800E3] DEFAULT ('') NOT NULL,
    [FAX]                CHAR (19)       CONSTRAINT [DF__SUPINFO__FAX__6EEC251C] DEFAULT ('') NOT NULL,
    [CRLIMIT]            NUMERIC (8)     CONSTRAINT [DF__SUPINFO__CRLIMIT__6FE04955] DEFAULT ((0)) NOT NULL,
    [TERMS]              CHAR (15)       CONSTRAINT [DF__SUPINFO__TERMS__70D46D8E] DEFAULT ('') NOT NULL,
    [SUPNOTE]            TEXT            CONSTRAINT [DF__SUPINFO__SUPNOTE__71C891C7] DEFAULT ('') NOT NULL,
    [PO1099]             BIT             CONSTRAINT [DF__SUPINFO__PO1099__72BCB600] DEFAULT ((0)) NOT NULL,
    [PURCH_TYPE]         CHAR (9)        CONSTRAINT [DF__SUPINFO__PURCH_T__73B0DA39] DEFAULT ('') NOT NULL,
    [R_LINK]             CHAR (10)       CONSTRAINT [DF__SUPINFO__R_LINK__74A4FE72] DEFAULT ('') NOT NULL,
    [C_LINK]             CHAR (10)       CONSTRAINT [DF__SUPINFO__C_LINK__759922AB] DEFAULT ('') NOT NULL,
    [Q_NOTIFY]           CHAR (1)        CONSTRAINT [DF__SUPINFO__Q_NOTIF__768D46E4] DEFAULT ('') NOT NULL,
    [YTD_PURCH]          NUMERIC (12, 2) CONSTRAINT [DF__SUPINFO__YTD_PUR__77816B1D] DEFAULT ((0)) NOT NULL,
    [CREDUSED]           NUMERIC (10, 2) CONSTRAINT [DF__SUPINFO__CREDUSE__78758F56] DEFAULT ((0)) NOT NULL,
    [CREDAVL]            NUMERIC (10, 2) CONSTRAINT [DF__SUPINFO__CREDAVL__7969B38F] DEFAULT ((0)) NOT NULL,
    [APBAL]              NUMERIC (10, 2) CONSTRAINT [DF__SUPINFO__APBAL__7A5DD7C8] DEFAULT ((0)) NOT NULL,
    [BK_ACCT_NO]         CHAR (15)       CONSTRAINT [DF__SUPINFO__BK_ACCT__7B51FC01] DEFAULT ('') NOT NULL,
    [CONTR_NOTE]         TEXT            CONSTRAINT [DF__SUPINFO__CONTR_N__7C46203A] DEFAULT ('') NOT NULL,
    [SUPPREFX]           CHAR (4)        CONSTRAINT [DF__SUPINFO__SUPPREF__7D3A4473] DEFAULT ('') NOT NULL,
    [modifiedDate]       SMALLDATETIME   CONSTRAINT [DF_SUPINFO_modifiedDate] DEFAULT (getdate()) NULL,
    [Fcused_Uniq]        CHAR (10)       CONSTRAINT [DF__SUPINFO__Fcused___16B0C90A] DEFAULT ('') NOT NULL,
    [Ad_link]            CHAR (10)       CONSTRAINT [DF__SUPINFO__Ad_link__0368EA6C] DEFAULT ('') NOT NULL,
    [Tax_id]             CHAR (8)        CONSTRAINT [DF__SUPINFO__Tax_id__045D0EA5] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT             CONSTRAINT [DF_SUPINFO_IsSynchronizedFlag] DEFAULT ((0)) NOT NULL,
    [isQBSync]           BIT             CONSTRAINT [DF_SUPINFO_isQBSync] DEFAULT ((0)) NOT NULL,
    [internal]           BIT             CONSTRAINT [DF_SUPINFO_internal] DEFAULT ((0)) NOT NULL,
    [PayInHomeCurr]      BIT             CONSTRAINT [DF_SUPINFO_PayInHomeCurr] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [SUPINFO_PK] PRIMARY KEY CLUSTERED ([UNIQSUPNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_SUPQBSYNC]
    ON [dbo].[SUPINFO]([isQBSync] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SUPSYNC]
    ON [dbo].[SUPINFO]([IsSynchronizedFlag] ASC);


GO
CREATE NONCLUSTERED INDEX [SUPID]
    ON [dbo].[SUPINFO]([SUPID] ASC);


GO
CREATE NONCLUSTERED INDEX [SUPNAME]
    ON [dbo].[SUPINFO]([SUPNAME] ASC);


GO
CREATE NONCLUSTERED INDEX [UPSUPNAME]
    ON [dbo].[SUPINFO]([SUPNAME] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/24/2014
-- Description:	Update trigger to save date/tiem when record was updated
---- 08/13/15 SS-update IsSynchronizedFlag to 0, unless web service is trying to update it to 1
--08-18-2015 sachin s remove the update trigger should be once	
--08/26/15 YS added isQBSync flag for quickbooks integration
--08/28/15 Sachin s-delete records from SynchronizationMultiLocationLog table if uniquenum exists while update the record
--09/24/15-Sachin s- The above code return error if multiple records are updated and Inserted return more than one result 
-- =============================================
CREATE TRIGGER [dbo].[SUPINFO_UPDATE]
   ON  [dbo].[SUPINFO]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--08/12/15 Sachins -Update the IsSynchronizedFlag as 0 when you update something
	UPDATE SUPINFO SET SUPINFO.modifiedDate =GETDATE(), 	
	--sachin s remove the update trigger should be once							 
	 --where SUPINFO.UNIQSUPNO  IN (SELECT UNIQSUPNO from inserted)
    -- Insert statements for trigger here
	
	---- 08/13/15 SS-update IsSynchronizedFlag to 0, unless web service is trying to update it to 1
	  --08/26/15 YS added isQBSync flag for quickbooks integration
     IsSynchronizedFlag =
							 CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
						         WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END,
	 IsQBSync =
							 CASE WHEN (I.IsQBSync = 1 and D.IsQBSync = 1) THEN 0
						         WHEN (I.IsQBSync = 1 and D.IsQBSync = 0) THEN 1
						ELSE 0 END
	 FROM inserted I inner join deleted D on i.UNIQSUPNO=d.UNIQSUPNO
			where I.UNIQSUPNO =SUPINFO.UNIQSUPNO  	
			
	     --08/28/15 -Sachins delete records from SynchronizationMultiLocationLog table if uniquenum exists while update the record
		  --Check IsSynchronizedFlag is zero 
		 -- IF((SELECT IsSynchronizedFlag FROM inserted) = 0)
		 --   BEGIN
			----Delete the Unique num from SynchronizationMultiLocationLog table if exists  with same UNIQ_KEY so all location pick again
			-- DELETE sml FROM SynchronizationMultiLocationLog sml 
			--  INNER JOIN SUPINFO sup on sml.UniqueNum=sup.UNIQSUPNO
			--	where sup.UNIQSUPNO =sml.UniqueNum 					
			--END
			--09/24/15-Sachin s- The above code return error if multiple records are updated and Inserted return more than one result 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNIQSUPNO=SynchronizationMultiLocationLog.Uniquenum);
			END					
							

END
