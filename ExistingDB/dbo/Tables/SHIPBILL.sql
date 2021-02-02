CREATE TABLE [dbo].[SHIPBILL] (
    [LINKADD]            CHAR (10)      CONSTRAINT [DF__SHIPBILL__LINKAD__3FA7264E] DEFAULT ('') NOT NULL,
    [CUSTNO]             CHAR (10)      CONSTRAINT [DF__SHIPBILL__CUSTNO__409B4A87] DEFAULT ('') NOT NULL,
    [SHIPTO]             VARCHAR (50)   CONSTRAINT [DF__SHIPBILL__SHIPTO__418F6EC0] DEFAULT ('') NOT NULL,
    [ADDRESS1]           VARCHAR (50)   CONSTRAINT [DF__SHIPBILL__ADDRES__428392F9] DEFAULT ('') NOT NULL,
    [ADDRESS2]           VARCHAR (50)   CONSTRAINT [DF__SHIPBILL__ADDRES__4377B732] DEFAULT ('') NOT NULL,
    [CITY]               VARCHAR (50)   CONSTRAINT [DF__SHIPBILL__CITY__446BDB6B] DEFAULT ('') NOT NULL,
    [STATE]              CHAR (50)      CONSTRAINT [DF__SHIPBILL__STATE__455FFFA4] DEFAULT ('') NOT NULL,
    [ZIP]                CHAR (20)      CONSTRAINT [DF__SHIPBILL__ZIP__465423DD] DEFAULT ('') NOT NULL,
    [COUNTRY]            VARCHAR (50)   CONSTRAINT [DF__SHIPBILL__COUNTR__47484816] DEFAULT ('') NOT NULL,
    [PHONE]              CHAR (20)      CONSTRAINT [DF__SHIPBILL__PHONE__483C6C4F] DEFAULT ('') NOT NULL,
    [FAX]                CHAR (19)      CONSTRAINT [DF__SHIPBILL__FAX__49309088] DEFAULT ('') NOT NULL,
    [E_MAIL]             NVARCHAR (200) CONSTRAINT [DF__SHIPBILL__E_MAIL__4A24B4C1] DEFAULT ('') NOT NULL,
    [TRANSDAY]           NUMERIC (2)    CONSTRAINT [DF__SHIPBILL__TRANSD__4B18D8FA] DEFAULT ((0)) NOT NULL,
    [FOB]                CHAR (15)      CONSTRAINT [DF__SHIPBILL__FOB__4C0CFD33] DEFAULT ('') NOT NULL,
    [SHIPCHARGE]         CHAR (15)      CONSTRAINT [DF__SHIPBILL__SHIPCH__4D01216C] DEFAULT ('') NOT NULL,
    [SHIPVIA]            CHAR (15)      CONSTRAINT [DF__SHIPBILL__SHIPVI__4DF545A5] DEFAULT ('') NOT NULL,
    [ATTENTION]          CHAR (30)      CONSTRAINT [DF__SHIPBILL__ATTENT__4EE969DE] DEFAULT ('') NOT NULL,
    [RECORDTYPE]         CHAR (1)       CONSTRAINT [DF__SHIPBILL__RECORD__4FDD8E17] DEFAULT ('') NOT NULL,
    [BILLACOUNT]         CHAR (20)      CONSTRAINT [DF__SHIPBILL__BILLAC__50D1B250] DEFAULT ('') NOT NULL,
    [SHIPTIME]           CHAR (8)       CONSTRAINT [DF__SHIPBILL__SHIPTI__51C5D689] DEFAULT ('') NOT NULL,
    [SHIPNOTE]           TEXT           CONSTRAINT [DF__SHIPBILL__SHIPNO__52B9FAC2] DEFAULT ('') NOT NULL,
    [SHIP_DAYS]          NUMERIC (3)    CONSTRAINT [DF__SHIPBILL__SHIP_D__53AE1EFB] DEFAULT ((0)) NOT NULL,
    [RECV_DEFA]          BIT            CONSTRAINT [DF__SHIPBILL__RECV_D__54A24334] DEFAULT ((0)) NOT NULL,
    [CONFIRM]            CHAR (6)       CONSTRAINT [DF__SHIPBILL__CONFIR__5596676D] DEFAULT ('') NOT NULL,
    [PKFOOTNOTE]         TEXT           CONSTRAINT [DF__SHIPBILL__PKFOOT__568A8BA6] DEFAULT ('') NOT NULL,
    [INFOOTNOTE]         TEXT           CONSTRAINT [DF__SHIPBILL__INFOOT__577EAFDF] DEFAULT ('') NOT NULL,
    [TAXEXEMPT]          CHAR (15)      CONSTRAINT [DF__SHIPBILL__TAXEXE__5872D418] DEFAULT ('') NOT NULL,
    [FOREIGNTAX]         BIT            CONSTRAINT [DF__SHIPBILL__FOREIG__5966F851] DEFAULT ((0)) NOT NULL,
    [modifiedDate]       DATETIME       NULL,
    [address4]           VARCHAR (50)   CONSTRAINT [DF_SHIPBILL_address4] DEFAULT ('') NOT NULL,
    [address3]           VARCHAR (50)   CONSTRAINT [DF_SHIPBILL_address3] DEFAULT ('') NOT NULL,
    [bk_uniq]            CHAR (10)      CONSTRAINT [DF_SHIPBILL_bk_uniq] DEFAULT ('') NOT NULL,
    [Fcused_Uniq]        CHAR (10)      CONSTRAINT [DF_SHIPBILL_Fcused_Uniq] DEFAULT ('') NOT NULL,
    [useDefaultTax]      BIT            CONSTRAINT [DF_SHIPBILL_usedefaulttax] DEFAULT ((0)) NOT NULL,
    [IsSynchronizedFlag] BIT            CONSTRAINT [DF__SHIPBILL__IsSync__14151ED8] DEFAULT ((0)) NOT NULL,
    [isQBSync]           BIT            CONSTRAINT [DF_SHIPBILL_isQBSync] DEFAULT ((0)) NOT NULL,
    [IsDefaultAddress]   BIT            CONSTRAINT [D_SHIPBILL_IsDefaultAddress] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [SHIPBILL_PK] PRIMARY KEY CLUSTERED ([LINKADD] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_custno]
    ON [dbo].[SHIPBILL]([CUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_recordtype]
    ON [dbo].[SHIPBILL]([RECORDTYPE] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SHIPBILLQBSYNC]
    ON [dbo].[SHIPBILL]([isQBSync] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SHIPBILLSync]
    ON [dbo].[SHIPBILL]([IsSynchronizedFlag] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SHIPTO]
    ON [dbo].[SHIPBILL]([SHIPTO] ASC);


GO
CREATE NONCLUSTERED INDEX [LINK_TYPE]
    ON [dbo].[SHIPBILL]([CUSTNO] ASC, [LINKADD] ASC, [RECORDTYPE] ASC);


GO
CREATE NONCLUSTERED INDEX [SBADDRESS]
    ON [dbo].[SHIPBILL]([ADDRESS1] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <09/01/2010>
-- Description:	<Delete trigger to make sure ShipTax records are delted as well>
--08/06/15 Sachin Inserted a record into [DeletedRecordsLog] for syncronization
--08/12/15 sachins-Change the name of the table from DeletedRecordsLog to SynchronizationDeletedRecords
--08/13/15 YS do not synchronize any records with empty custno
-- =============================================
CREATE TRIGGER [dbo].[ShipBill_Delete] 
   ON  dbo.SHIPBILL
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	BEGIN TRANSACTION		
	 DELETE FROM ShipTax WHERE LinkAdd in (SELECT LinkAdd FROM Deleted)
	
	--08/06/15 Sachin Inserted a record into [DeletedRecordsLog] for syncronization
	--08/12/15 sachins-Change the name of the table from DeletedRecordsLog to SynchronizationDeletedRecords
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'SHIPBILL'
           ,'LinkAdd'
           ,Deleted.LINKADD from Deleted
		   --08/13/15 YS do not synchronize any records with empty custno
		   where custno<>' '			  
		 
	COMMIT
END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/24/2014
-- Description:	Update trigger to save date/tiem when record was updated
--08/06/15 Sachin update customer.modifiedDate 
--08/06/15 YS no CAST needed for the getdate() function. Shipbill table is sahring the information between customer and supplier
---- 08/06/15 SS-update IsSynchronizedFlag to 0, unless web service is trying to update it to 1
--08/18/2015 Sachin s comment the code modifiedDate for synchronization
--sachin s :08-18-2015 Removes the update statement
--08/26/15 YS added isQbSync for QuickBooks integration
--08/28/15 Sachin s-delete records from SynchronizationMultiLocationLog table if uniquenum exists while update the record
--09-24-2015-Sachin s- The code return error if multiple records are updated and Inserted return more than one result 
-- 09/24/15 SS-update IsSynchronizedFlag to 1, unless web can not sync the records 
-- =============================================
CREATE TRIGGER [dbo].[SHIPBILL_UPDATE]
   ON  dbo.SHIPBILL
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE SHIPBILL SET modifiedDate =GETDATE(), 
	--sachin s :08-18-2015 Removes the update statement 
	--where LINKADD IN (SELECT LINKADD from inserted)
	--08/06/15 Sachin update customer.modifiedDate 
	--08/06/15 YS removed cast()
	-- 08/06/15 check if the record is for customer or a supplier . 
	--This will create false update for modifieddate if the address was updated for a supplier
	---- on the other hand the supplier's modified date will be never updated.  
	--08/18/2015 Sachin s comment the code modifiedDate for synchronization
	--Update CUSTOMER SET Customer.modifiedDate = GetDate() WHERE CUSTNO IN (SELECT CUSTNO from inserted)
    -- Insert statements for trigger here
	---- 08/06/15 SS-update IsSynchronizedFlag to 0, unless web service is trying to update it to 1     
	  IsSynchronizedFlag= CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
					 --09/24/15 SS-update IsSynchronizedFlag to 1, unless web can not sync the records 
						ELSE 0 END,
						 IsQBSync= CASE WHEN (I.IsQBSync = 1 and D.IsQBSync = 1) THEN 0
						       WHEN (I.IsQBSync = 1 and D.IsQBSync = 0) THEN 1
						ELSE 0 END
	 FROM inserted I inner join deleted D on i.LINKADD=d.LINKADD
			where I.LINKADD =SHIPBILL.LINKADD  
	     --09-24-2015-Sachin s- The code return error if multiple records are updated and Inserted return more than one result 
		 --08/28/15 -delete records from SynchronizationMultiLocationLog table if uniquenum exists while update the record
		  --Check IsSynchronizedFlag is zero 
		 -- IF((SELECT IsSynchronizedFlag FROM inserted) = 0)
		 --   BEGIN
			----Delete the Unique num from SynchronizationMultiLocationLog table if exists  with same UNIQ_KEY so all location pick again
			-- DELETE sml FROM SynchronizationMultiLocationLog sml 
			--  INNER JOIN SHIPBILL shpb on sml.UniqueNum=shpb.LINKADD
			--	where shpb.LINKADD =sml.UniqueNum 					
			--END
			--
			--09-24-2015-Sachin s- The code return error if multiple records are updated and Inserted return more than one result 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.LINKADD=SynchronizationMultiLocationLog.Uniquenum);
			END					
				 
END