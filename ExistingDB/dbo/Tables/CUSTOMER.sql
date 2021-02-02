CREATE TABLE [dbo].[CUSTOMER] (
    [CUSTNO]             CHAR (10)        CONSTRAINT [DF__CUSTOMER__CUSTNO__2B7F66B9] DEFAULT ('') NOT NULL,
    [CUSTNAME]           CHAR (50)        CONSTRAINT [DF__CUSTOMER__CUSTNA__2C738AF2] DEFAULT ('') NULL,
    [PHONE]              CHAR (20)        CONSTRAINT [DF__CUSTOMER__PHONE__2D67AF2B] DEFAULT ('') NOT NULL,
    [FAX]                CHAR (19)        CONSTRAINT [DF__CUSTOMER__FAX__2E5BD364] DEFAULT ('') NOT NULL,
    [BLINKADD]           CHAR (10)        CONSTRAINT [DF__CUSTOMER__BLINKA__2F4FF79D] DEFAULT ('') NOT NULL,
    [SLINKADD]           CHAR (10)        CONSTRAINT [DF__CUSTOMER__SLINKA__30441BD6] DEFAULT ('') NOT NULL,
    [TERRITORY]          CHAR (15)        CONSTRAINT [DF__CUSTOMER__TERRIT__3138400F] DEFAULT ('') NOT NULL,
    [TERMS]              CHAR (15)        CONSTRAINT [DF__CUSTOMER__TERMS__322C6448] DEFAULT ('') NOT NULL,
    [CREDLIMIT]          NUMERIC (9)      CONSTRAINT [DF__CUSTOMER__CREDLI__33208881] DEFAULT ((0)) NOT NULL,
    [PROFILE]            TEXT             CONSTRAINT [DF__CUSTOMER__PROFIL__3414ACBA] DEFAULT ('') NOT NULL,
    [CUSTNOTE]           TEXT             CONSTRAINT [DF__CUSTOMER__CUSTNO__3508D0F3] DEFAULT ('') NOT NULL,
    [ACCTSTATUS]         CHAR (9)         CONSTRAINT [DF__CUSTOMER__ACCTST__35FCF52C] DEFAULT ('') NOT NULL,
    [DIVISION]           CHAR (12)        CONSTRAINT [DF__CUSTOMER__DIVISI__36F11965] DEFAULT ('') NOT NULL,
    [SREPS]              CHAR (100)       CONSTRAINT [DF__CUSTOMER__SREPS__37E53D9E] DEFAULT ('') NOT NULL,
    [CREDITOK]           CHAR (15)        CONSTRAINT [DF__CUSTOMER__CREDIT__38D961D7] DEFAULT ('') NOT NULL,
    [RESL_NO]            CHAR (16)        CONSTRAINT [DF__CUSTOMER__RESL_N__3D9E16F4] DEFAULT ('') NOT NULL,
    [AR_CALDATE]         SMALLDATETIME    NULL,
    [AR_CALTIME]         CHAR (10)        CONSTRAINT [DF__CUSTOMER__AR_CAL__3E923B2D] DEFAULT ('') NOT NULL,
    [AR_CALBY]           CHAR (10)        CONSTRAINT [DF__CUSTOMER__AR_CAL__3F865F66] DEFAULT ('') NOT NULL,
    [AR_CALNOTE]         TEXT             CONSTRAINT [DF__CUSTOMER__AR_CAL__407A839F] DEFAULT ('') NOT NULL,
    [AR_HIGHBAL]         NUMERIC (12, 2)  CONSTRAINT [DF__CUSTOMER__AR_HIG__416EA7D8] DEFAULT ((0)) NOT NULL,
    [CREDITNOTE]         TEXT             CONSTRAINT [DF__CUSTOMER__CREDIT__4262CC11] DEFAULT ('') NOT NULL,
    [ACCT_DATE]          SMALLDATETIME    CONSTRAINT [DF_CUSTOMER_ACCT_DATE] DEFAULT (getdate()) NULL,
    [SAVEINIT]           NVARCHAR (256)   NULL,
    [OUT_MARGIN]         NUMERIC (6, 2)   CONSTRAINT [DF__CUSTOMER__OUT_MA__444B1483] DEFAULT ((0)) NOT NULL,
    [TL_MARGIN]          NUMERIC (6, 2)   CONSTRAINT [DF__CUSTOMER__TL_MAR__453F38BC] DEFAULT ((0)) NOT NULL,
    [MAT_MARGIN]         NUMERIC (6, 2)   CONSTRAINT [DF__CUSTOMER__MAT_MA__46335CF5] DEFAULT ((0)) NOT NULL,
    [LAB_MARGIN]         NUMERIC (6, 2)   CONSTRAINT [DF__CUSTOMER__LAB_MA__4727812E] DEFAULT ((0)) NOT NULL,
    [MIN_ORDAMT]         NUMERIC (12, 2)  CONSTRAINT [DF__CUSTOMER__MIN_OR__481BA567] DEFAULT ((0)) NOT NULL,
    [SCRAP_FACT]         NUMERIC (6, 2)   CONSTRAINT [DF__CUSTOMER__SCRAP___490FC9A0] DEFAULT ((0)) NOT NULL,
    [COMMITEM]           NUMERIC (1)      CONSTRAINT [DF__CUSTOMER__COMMIT__4A03EDD9] DEFAULT ((0)) NOT NULL,
    [CUSTSPEC]           NUMERIC (4)      CONSTRAINT [DF__CUSTOMER__CUSTSP__4AF81212] DEFAULT ((0)) NOT NULL,
    [LABOR]              BIT              CONSTRAINT [DF__CUSTOMER__LABOR__4BEC364B] DEFAULT ((0)) NOT NULL,
    [MATERIAL]           BIT              CONSTRAINT [DF__CUSTOMER__MATERI__4CE05A84] DEFAULT ((0)) NOT NULL,
    [SPLIT1]             NUMERIC (1)      CONSTRAINT [DF__CUSTOMER__SPLIT1__4DD47EBD] DEFAULT ((0)) NOT NULL,
    [SPLIT2]             NUMERIC (1)      CONSTRAINT [DF__CUSTOMER__SPLIT2__4EC8A2F6] DEFAULT ((0)) NOT NULL,
    [SPLITAMT]           NUMERIC (12, 2)  CONSTRAINT [DF__CUSTOMER__SPLITA__4FBCC72F] DEFAULT ((0)) NOT NULL,
    [SPLITPERC]          NUMERIC (6, 2)   CONSTRAINT [DF__CUSTOMER__SPLITP__50B0EB68] DEFAULT ((0)) NOT NULL,
    [TOOLING]            BIT              CONSTRAINT [DF__CUSTOMER__TOOLIN__51A50FA1] DEFAULT ((0)) NOT NULL,
    [SIC_CODE]           CHAR (5)         CONSTRAINT [DF__CUSTOMER__SIC_CO__529933DA] DEFAULT ('') NOT NULL,
    [SIC_DESC]           CHAR (35)        CONSTRAINT [DF__CUSTOMER__SIC_DE__538D5813] DEFAULT ('') NOT NULL,
    [DELIVTIME]          CHAR (7)         CONSTRAINT [DF__CUSTOMER__DELIVT__54817C4C] DEFAULT ('') NOT NULL,
    [STATUS]             CHAR (8)         CONSTRAINT [DF__CUSTOMER__STATUS__5575A085] DEFAULT ('') NOT NULL,
    [SERIFLAG]           BIT              CONSTRAINT [DF__CUSTOMER__SERIFL__5669C4BE] DEFAULT ((0)) NOT NULL,
    [OVERHEAD]           NUMERIC (6, 2)   CONSTRAINT [DF__CUSTOMER__OVERHE__575DE8F7] DEFAULT ((0)) NOT NULL,
    [IS_EDITED]          CHAR (3)         CONSTRAINT [DF__CUSTOMER__IS_EDI__58520D30] DEFAULT ('') NOT NULL,
    [SALEDSCTID]         CHAR (10)        CONSTRAINT [DF__CUSTOMER__SALEDS__59463169] DEFAULT ('') NOT NULL,
    [CUSTPFX]            CHAR (4)         CONSTRAINT [DF__CUSTOMER__CUSTPF__5A3A55A2] DEFAULT ('') NOT NULL,
    [ACTTAXABLE]         BIT              CONSTRAINT [DF__CUSTOMER__ACTTAX__5B2E79DB] DEFAULT ((0)) NOT NULL,
    [INACTDT]            SMALLDATETIME    NULL,
    [INACTINIT]          NVARCHAR (256)   NULL,
    [modifiedDate]       DATETIME         CONSTRAINT [DF_CUSTOMER_modifiedDate] DEFAULT (getdate()) NULL,
    [FcUsed_uniq]        CHAR (10)        CONSTRAINT [DF__CUSTOMER__FcUsed__26E730D3] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT              CONSTRAINT [DF_CUSTOMER_IsSynchronizedFlag] DEFAULT ((0)) NOT NULL,
    [isQBSync]           BIT              CONSTRAINT [DF_CUSTOMER_isQBSync] DEFAULT ((0)) NOT NULL,
    [internal]           BIT              CONSTRAINT [DF_CUSTOMER_internal] DEFAULT ((0)) NOT NULL,
    [CustCode]           NVARCHAR (10)    CONSTRAINT [DF__CUSTOMER__CustCo__0DB3D0BA] DEFAULT ('') NOT NULL,
    [LastStmtSent]       DATETIME2 (7)    NULL,
    [LastStmtSentUserId] UNIQUEIDENTIFIER NULL,
    [WebSite]            VARCHAR (150)    CONSTRAINT [DF__CUSTOMER__WebSit__05497342] DEFAULT (NULL) NULL,
    CONSTRAINT [CUSTOMER_PK] PRIMARY KEY CLUSTERED ([CUSTNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CUSTNAME]
    ON [dbo].[CUSTOMER]([CUSTNAME] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_qbSync]
    ON [dbo].[CUSTOMER]([isQBSync] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Sync]
    ON [dbo].[CUSTOMER]([IsSynchronizedFlag] ASC);


GO
-- =============================================
-- Author:Yelena Shmidt
-- Create date: 04/24/2014 
-- Description:	Update trigger for customer table. When the record is updated save current date/time into modifiedDate colum
-- 07/27/15 YS update Customer.InactDt become null and Customer.InactInit = ' ' If Customer Status was changed to be Active 
-- 08/13/15 Sachin s  update IsSynchronizedFlag to 0, unless web service is trying to update it to 1
--08/26/15 YS per Anuj added new column isQBSync for quickbooks syncronization 
--08/28/15 delete records from SynchronizationMultiLocationLog table if uniquenum exists while update the record
--09/24/15-Sachin s- The above code return error if multiple records are updated and Inserted return more than one result 
-- =============================================
CREATE TRIGGER [dbo].[Customer_Update] 
   ON  [dbo].[CUSTOMER] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Update CUSTOMER SET Customer.modifiedDate = GETDATE() WHERE CUSTNO IN (SELECT CUSTNO from inserted)
	-- 07/27/15 YS update Customer.InactDt become null and Customer.InactInit = ' ' If Customer Status was changed to be Active 
    Update Customer Set INACTDT= case when deleted.status='Inactive' and inserted.STATUS='Active' then null 
										when deleted.status='Active' and inserted.STATUS='Inactive' then getdate()
										else customer.INACTDT end,
						INACTINIT=case when deleted.status='Inactive' and inserted.STATUS='Active' then ' ' 
										when deleted.status='Active' and inserted.STATUS='Inactive' then Inserted.SAVEINIT
										else customer.INACTINIT end
																					 
						from  Inserted inner join Deleted on inserted.CUSTNO=deleted.custno
					and deleted.status<>inserted.STATUS 
					where inserted.custno=Customer.custno
	-- 08/06/15 Sachin s update IsSynchronizedFlag to 0, unless web service is trying to update it to 1
	--08/26/15 YS Update isQBSync to 0 if any changes, unless QB sync app updating to 1
	  Update Customer SET 
	 IsSynchronizedFlag= 
						CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
					    WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END,
					isQBSync= 
						     CASE WHEN (I.isQBSync = 1 and D.isQBSync = 1) THEN 0
						       WHEN (I.isQBSync = 1 and D.isQBSync = 0) THEN 1
						ELSE 0 END	
					FROM inserted I inner join deleted D on i.CUSTNO=d.CUSTNO
					where I.CUSTNO =Customer.CUSTNO  
		----08/28/15 - delete records from SynchronizationMultiLocationLog table if uniquenum exists while update the record
		--  --Check IsSynchronizedFlag is zero 
		--  IF((SELECT IsSynchronizedFlag FROM inserted) = 0)
		--    BEGIN
		--	--Delete the Unique num from SynchronizationMultiLocationLog table if exists  with same UNIQ_KEY so all location pick again
		--	 DELETE sml FROM SynchronizationMultiLocationLog sml 
		--	  INNER JOIN Customer cus on sml.UniqueNum=cus.CUSTNO
		--		where cus.CUSTNO =sml.UniqueNum 					
		--	END
		--09/24/15-Sachin s- The above code return error if multiple records are updated and Inserted return more than one result 
			IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.CUSTNO=SynchronizationMultiLocationLog.Uniquenum);
			END					



END