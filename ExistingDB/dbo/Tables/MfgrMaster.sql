CREATE TABLE [dbo].[MfgrMaster] (
    [MfgrMasterId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [PartMfgr]           VARCHAR (8)     CONSTRAINT [DF_MfgrMaster_PartMfgr] DEFAULT ('') NOT NULL,
    [mfgr_pt_no]         VARCHAR (30)    CONSTRAINT [DF_MfgrMaster_mfgr_pt_no] DEFAULT ('') NOT NULL,
    [mfgrDescript]       VARCHAR (100)   CONSTRAINT [DF_MfgrMaster_mfgrDescript] DEFAULT ('') NOT NULL,
    [Root]               VARCHAR (30)    CONSTRAINT [DF_MfgrMaster_Root] DEFAULT ('') NOT NULL,
    [marking]            VARCHAR (10)    CONSTRAINT [DF_MfgrMaster_marking] DEFAULT ('') NOT NULL,
    [body]               VARCHAR (10)    CONSTRAINT [DF_MfgrMaster_body] DEFAULT ('') NOT NULL,
    [pitch]              VARCHAR (10)    CONSTRAINT [DF_MfgrMaster_pitch] DEFAULT ('') NOT NULL,
    [part_spec]          VARCHAR (100)   CONSTRAINT [DF_MfgrMaster_part_spec] DEFAULT ('') NOT NULL,
    [part_pkg]           VARCHAR (15)    CONSTRAINT [DF_MfgrMaster_part_pkg] DEFAULT ('') NOT NULL,
    [uniqpkg]            CHAR (10)       CONSTRAINT [DF_MfgrMaster_uniqpkg] DEFAULT ('') NOT NULL,
    [is_deleted]         BIT             CONSTRAINT [DF_MfgrMaster_is_deleted] DEFAULT ((0)) NOT NULL,
    [MatlType]           VARCHAR (10)    CONSTRAINT [DF_MfgrMaster_MatlType] DEFAULT ('') NOT NULL,
    [autolocation]       BIT             CONSTRAINT [DF_MfgrMaster_autolocation] DEFAULT ((0)) NOT NULL,
    [MATLTYPEVALUE]      VARCHAR (20)    CONSTRAINT [DF_MfgrMaster_MATLTYPEVALUE] DEFAULT ('') NOT NULL,
    [LDISALLOWBUY]       BIT             CONSTRAINT [DF_MfgrMaster_LDISALLOWBUY] DEFAULT ((0)) NOT NULL,
    [LDISALLOWKIT]       BIT             CONSTRAINT [DF_MfgrMaster_LDISALLOWKIT] DEFAULT ((0)) NOT NULL,
    [SFTYSTK]            NUMERIC (7)     CONSTRAINT [DF_MfgrMaster_SFTYSTK] DEFAULT ((0)) NOT NULL,
    [MOISTURE]           VARCHAR (3)     CONSTRAINT [DF_MfgrMaster_MOISTURE] DEFAULT ('') NOT NULL,
    [EICCSTATUS]         BIT             CONSTRAINT [DF_MfgrMaster_EICCSTATUS] DEFAULT ((0)) NOT NULL,
    [LifeCycle]          VARCHAR (50)    CONSTRAINT [DF_MfgrMaster_LifeCycle] DEFAULT ('Active') NOT NULL,
    [PTLENGTH]           NUMERIC (7, 3)  CONSTRAINT [DF_MfgrMaster_PTLENGTH] DEFAULT ((0.00)) NOT NULL,
    [PTWIDTH]            NUMERIC (7, 3)  CONSTRAINT [DF_MfgrMaster_PTWIDTH] DEFAULT ((0.00)) NOT NULL,
    [PTDEPTH]            NUMERIC (7, 3)  CONSTRAINT [DF_MfgrMaster_PTDEPTH] DEFAULT ((0.00)) NOT NULL,
    [ptwt]               NUMERIC (9, 2)  CONSTRAINT [DF_MfgrMaster_ptwt] DEFAULT ((0.00)) NOT NULL,
    [qtyPerPkg]          NUMERIC (12, 2) CONSTRAINT [DF_MfgrMaster_qtyPerPkg] DEFAULT ((0)) NOT NULL,
    [shelfLife]          INT             NULL,
    [IsSynchronizedFlag] BIT             DEFAULT ((0)) NULL,
    [countryofOrigin]    NVARCHAR (50)   CONSTRAINT [DF_MfgrMaster_countryofOrigin] DEFAULT ('') NOT NULL,
    [LifeCycleDate]      DATE            NULL,
    [Series]             NVARCHAR (50)   CONSTRAINT [DF_MfgrMaster_Series] DEFAULT ('') NOT NULL,
    [MpnImageLink]       NVARCHAR (200)  CONSTRAINT [DF_MfgrMaster_MpnImage] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_MfgrMaster] PRIMARY KEY CLUSTERED ([MfgrMasterId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AML]
    ON [dbo].[MfgrMaster]([PartMfgr] ASC, [mfgr_pt_no] ASC);


GO
CREATE NONCLUSTERED INDEX [Is_deleted]
    ON [dbo].[MfgrMaster]([is_deleted] ASC);


GO
CREATE NONCLUSTERED INDEX [Package]
    ON [dbo].[MfgrMaster]([uniqpkg] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/27/2013
-- Description:	When record is marked as deleted check if antiavl for the record exists and remove it as well
-- 05/20/14 YS force some columns to be upper case. UI Independent
-- 10/09/14 YS move trigger from Invtmfhd to mfgrmaster
-- =============================================
CREATE TRIGGER [dbo].[MfgrMaster_Update]
   ON  dbo.MfgrMaster 
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	-- 05/20/14 YS force some columns to be upper case. UI Independent
	-- 10/09/14 YS move trigger from Invtmfhd to mfgrmaster
	UPDATE [MfgrMaster] set PARTMFGR=UPPER(I.PartMfgr) FROM inserted I where I.MfgrMasterId=[MfgrMaster].MfgrMasterId 
	--10/09/14 YS  if mfgrmaster is_deleted flag become 1 update all related records invtmpnlink is_deleted with 1
	UPDATE InvtMPNLink SET is_deleted=1 
		FROM Inserted I INNER JOIN Deleted D on I.MfgrMasterId=D.MfgrMasterId 
		where I.IS_DELETED =1 and D.IS_DELETED =0
		and InvtMPNLink.mfgrMasterId=I.MfgrMasterId
	-- delete any records associated with deleted.uniq_key,mfgr_pt_no and partmfgr from antiavl table
	DELETE FROM ANTIAVL WHERE UNIQ_KEY+PARTMFGR+MFGR_PT_NO IN 
	(SELECT L.UNIQ_KEY+I.PARTMFGR+I.MFGR_PT_NO 
	 from inserted I inner join deleted D on I.MfgrMasterId =D.MfgrMasterId 
	 INNER JOIN InvtMPNLink L ON l.mfgrMasterId=I.MfgrMasterId
	 where I.IS_DELETED =1 and D.IS_DELETED =0)
	
	-- 10/03/15  Sachins S -update IsSynchronizedFlag to 0,WHEN update the from web service		
	update MfgrMaster set IsSynchronizedFlag=
						  CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END
			FROM inserted I inner join deleted D on i.MfgrMasterId=d.MfgrMasterId
			where I.MfgrMasterId =MfgrMaster.MfgrMasterId 
	-- 10/03/15  Sachins S -delete the record from SynchronizationMultiLocationLog while upadte the records  
	--if one location already synchronized and other location not getting synchronized
		IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			    DELETE FROM SynchronizationMultiLocationLog 
				WHERE EXISTS (SELECT 1 FROM Inserted where IsSynchronizedFlag=0 and Inserted.MfgrMasterId=SynchronizationMultiLocationLog.Uniquenum);
			END 

	
	COMMIT
    -- Insert statements for trigger here

END
GO
-- =============================================
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/27/2013
-- Description:	When record is removed check if antiavl for the record exists and remove it as well
--  10/09/14 (Denis is 31 today)
-- remove records from Invtmpnlink, also move code from
-- =============================================
CREATE TRIGGER [dbo].[MfgrMaster_Delete]
   ON  dbo.MfgrMaster
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	
	BEGIN TRANSACTION	
		delete from InvtMPNLink WHERE mfgrMasterId IN (SELECT mfgrMasterId from Deleted)
		-- delete any records associated with deleted.uniq_key,mfgr_pt_no and partmfgr from antiavl table
		DELETE FROM ANTIAVL WHERE UNIQ_KEY+PARTMFGR+MFGR_PT_NO IN (SELECT UNIQ_KEY+PARTMFGR+MFGR_PT_NO  from deleted)
	IF @@TRANCOUNT<>0	
	COMMIT
	--10/03/15 sachins-Insert the record in to the SynchronizationDeletedRecords
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'MfgrMaster'
           ,'mfgrMasterId'
           ,Deleted.mfgrMasterId
		    from Deleted
END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/31/2013
-- Description:	Insert trigger for Invtmfhd
-- 05/20/14 YS force some columns to be upper case. UI Independent
-- 10/09/14 YS move invtmfhd trigger to MfgrMaster Insert trigger
-- =============================================
CREATE TRIGGER [dbo].[MfgrMaster_Insert] 
   ON  dbo.MfgrMaster 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 05/20/14 YS force some columns to be upper case. UI Independent
	-- 10/09/14 YS replace invtmfhd with 2 new tables
	UPDATE MfgrMaster set PARTMFGR=UPPER(I.PartMfgr) FROM inserted I where I.MfgrMasterId=MfgrMaster.MfgrMasterId 
    -- Insert statements for trigger here
    -- 10/31/13 YS update [InvtMpnClean] table with new partmfgr and mfgr_pt_no
   
   
    INSERT INTO [InvtMpnClean]
           ([partMfgr]
           ,[mfgr_pt_no]
           ,[cleanmpn])
          select I.partMfgr, I.mfgr_pt_no,UPPER(dbo.fnKeepAlphaNumeric(I.Mfgr_Pt_No))
          from inserted I where i.PARTMFGR+i.MFGR_PT_NO NOT IN (SELECT  partMfgr+mfgr_pt_no from InvtMpnClean)


END