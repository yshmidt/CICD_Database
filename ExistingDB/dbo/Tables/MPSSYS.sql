CREATE TABLE [dbo].[MPSSYS] (
    [MPSDATE]              SMALLDATETIME NULL,
    [MRPDATE]              SMALLDATETIME NULL,
    [NEEDLEVEL]            BIT           CONSTRAINT [DF__MPSSYS__NEEDLEVE__787FB0F7] DEFAULT ((0)) NOT NULL,
    [VIEWDAYS]             NUMERIC (4)   CONSTRAINT [DF__MPSSYS__VIEWDAYS__7973D530] DEFAULT ((0)) NOT NULL,
    [DIVTRANSF]            BIT           CONSTRAINT [DF__MPSSYS__DIVTRANS__7A67F969] DEFAULT ((0)) NOT NULL,
    [GLDIVNO]              CHAR (2)      CONSTRAINT [DF__MPSSYS__GLDIVNO__7B5C1DA2] DEFAULT ('') NOT NULL,
    [KEYFIELD]             CHAR (10)     CONSTRAINT [DF__MPSSYS__KEYFIELD__7C5041DB] DEFAULT ('') NOT NULL,
    [LIGNORPROJ]           BIT           CONSTRAINT [DF__MPSSYS__LIGNORPR__7D446614] DEFAULT ((0)) NOT NULL,
    [LIGNORESCRAP]         BIT           CONSTRAINT [DF__MPSSYS__LIGNORES__7E388A4D] DEFAULT ((0)) NOT NULL,
    [LIGNOREKITSTATUS]     BIT           CONSTRAINT [DF__MPSSYS__LIGNOREK__7F2CAE86] DEFAULT ((0)) NOT NULL,
    [LFCSTAPPROVE]         BIT           CONSTRAINT [DF__MPSSYS__LFCSTAPP__0020D2BF] DEFAULT ((0)) NOT NULL,
    [LTOPLEVELSCRAP]       BIT           CONSTRAINT [DF__MPSSYS__LTOPLEVE__0114F6F8] DEFAULT ((0)) NOT NULL,
    [nLastFcstNbr]         NUMERIC (4)   CONSTRAINT [DF_MPSSYS_nLastFcstNbr] DEFAULT ((0)) NOT NULL,
    [lShipments2Any]       BIT           CONSTRAINT [DF_MPSSYS_lShipments2Any] DEFAULT ((1)) NOT NULL,
    [lastmrprunnote]       VARCHAR (500) CONSTRAINT [DF_MPSSYS_lastmrprunnote] DEFAULT ('') NOT NULL,
    [MRPSUCCESS]           BIT           CONSTRAINT [DF_MPSSYS_MRPSUCCESS] DEFAULT ((0)) NOT NULL,
    [LASTMRPDATE]          SMALLDATETIME NULL,
    [lSuppressNoWOActions] BIT           CONSTRAINT [DF_MPSSYS_lSuppressNoWOActions] DEFAULT ((0)) NOT NULL,
    [lSuppressNoPOActions] BIT           CONSTRAINT [DF_MPSSYS_lSuppressNoPOActions] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [MPSSYS_PK] PRIMARY KEY CLUSTERED ([KEYFIELD] ASC)
);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/07/2013
-- Description:	WHen MRPDATE is updated create a notification
-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
-- 05/31/19 YS add code to populate new settings for the LastMrpRunDt
-- =============================================
CREATE TRIGGER [dbo].[MpsSys_update] 
   ON  [dbo].[MPSSYS] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    IF (select DELETED.MRPDATE from deleted) <> (SELECT mrpdate from inserted)
	--	LastMrpRunNote = "Mrp run completed successfully.",;
	--MrpSuccess = .T
	begin
	--05/31/19 YS update wmSettingsManagement for the LastMrpRunDt
	DECLARE @settingid uniqueidentifier
	select @settingid=settingid from MnxSettingsManagement where settingName='LastMrpRunDt' and settingModule = 'MRPExecutinByDt'
	IF EXISTS (select 1 from wmSettingsManagement where settingId=@settingid)
		UPDATE wmSettingsManagement set settingValue=convert(character,MRPDATE,21) from Inserted
			where settingId=@settingid 
	else
	-- new record in wmSettingsManagement
	INSERT INTO wmSettingsManagement (settingId,settingValue) VALUES (@SettingId,(SELECT convert(character,MRPDATE,21) FROM Inserted))
	--05/31/19 YS end  update wmSettingsManagement for the LastMrpRunDt
	declare @MRPSUCCESS bit =0
		INSERT INTO [dbo].[wmTriggerEmails]
           ([messageid]
           ,[toEmail]
           ,[subject]
           ,[body]
           ,[dateAdded]
           ,[deleteOnSend])
        SELECT newid(),
			p.EMAIL,
			s.[messageSubject],
			case when @MRPSUCCESS = 1 then 'Auto-MRP complete successfully' else 'Auto-MRP failed' END as body,
			GETDATE(),
			1
			from MnxTriggerEvents E inner join wmTriggerEventSubscriptions S on e.eventId =s.eventId  
			-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
			inner join aspnet_membership p on s.userId =p.UserId 
			where e.eventName ='Automatic MRP'

	end

END