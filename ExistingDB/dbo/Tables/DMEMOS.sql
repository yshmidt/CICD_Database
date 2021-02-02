CREATE TABLE [dbo].[DMEMOS] (
    [UNIQDMHEAD]      CHAR (10)        CONSTRAINT [DF__DMEMOS__UNIQDMHE__6E0C4425] DEFAULT ('') NOT NULL,
    [TRANS_NO]        NUMERIC (10)     CONSTRAINT [DF__DMEMOS__TRANS_NO__6FF48C97] DEFAULT ((0)) NOT NULL,
    [DMDATE]          SMALLDATETIME    CONSTRAINT [DF_DMEMOS_DMDATE] DEFAULT (getdate()) NULL,
    [DMEMONO]         CHAR (10)        CONSTRAINT [DF__DMEMOS__DMEMONO__70E8B0D0] DEFAULT ('') NOT NULL,
    [INVNO]           CHAR (20)        CONSTRAINT [DF__DMEMOS__INVNO__71DCD509] DEFAULT ('') NOT NULL,
    [INVDATE]         SMALLDATETIME    NULL,
    [PONUM]           CHAR (15)        CONSTRAINT [DF__DMEMOS__PONUM__73C51D7B] DEFAULT ('') NOT NULL,
    [DMTOTAL]         NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__DMTOTAL__74B941B4] DEFAULT ((0)) NOT NULL,
    [DMAPPLIED]       NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__DMAPPLIE__75AD65ED] DEFAULT ((0)) NOT NULL,
    [DMREASON]        TEXT             CONSTRAINT [DF__DMEMOS__DMREASON__76A18A26] DEFAULT ('') NOT NULL,
    [SAVEINIT]        CHAR (8)         CONSTRAINT [DF__DMEMOS__SAVEINIT__7795AE5F] DEFAULT ('') NULL,
    [IS_REL_GL]       BIT              CONSTRAINT [DF__DMEMOS__IS_REL_G__7889D298] DEFAULT ((0)) NOT NULL,
    [IS_PRINTED]      BIT              CONSTRAINT [DF__DMEMOS__IS_PRINT__797DF6D1] DEFAULT ((0)) NOT NULL,
    [UNIQAPHEAD]      CHAR (10)        CONSTRAINT [DF__DMEMOS__UNIQAPHE__7A721B0A] DEFAULT ('') NOT NULL,
    [UNIQSUPNO]       CHAR (10)        CONSTRAINT [DF__DMEMOS__UNIQSUPN__7B663F43] DEFAULT ('') NOT NULL,
    [DMSTATUS]        CHAR (14)        CONSTRAINT [DF__DMEMOS__DMSTATUS__7C5A637C] DEFAULT ('') NOT NULL,
    [DMTYPE]          NUMERIC (1)      CONSTRAINT [DF__DMEMOS__DMTYPE__7D4E87B5] DEFAULT ((0)) NOT NULL,
    [R_LINK]          CHAR (10)        CONSTRAINT [DF__DMEMOS__R_LINK__7E42ABEE] DEFAULT ('') NOT NULL,
    [EDITDT]          SMALLDATETIME    NULL,
    [REASON]          CHAR (25)        CONSTRAINT [DF__DMEMOS__REASON__7F36D027] DEFAULT ('') NOT NULL,
    [INIT]            CHAR (8)         CONSTRAINT [DF__DMEMOS__INIT__002AF460] DEFAULT ('') NULL,
    [DMNOTE]          TEXT             CONSTRAINT [DF__DMEMOS__DMNOTE__011F1899] DEFAULT ('') NOT NULL,
    [DMRUNIQUE]       CHAR (10)        CONSTRAINT [DF__DMEMOS__DMRUNIQU__02133CD2] DEFAULT ('') NOT NULL,
    [NDISCAMT]        NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__NDISCAMT__0307610B] DEFAULT ((0)) NOT NULL,
    [DMTOTALFC]       NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__DMTOTALF__28063D95] DEFAULT ((0)) NOT NULL,
    [DMAPPLIEDFC]     NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__DMAPPLIE__28FA61CE] DEFAULT ((0)) NOT NULL,
    [NDISCAMTFC]      NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__NDISCAMT__29EE8607] DEFAULT ((0)) NOT NULL,
    [NTAXAMT]         NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__NTAXAMT__2AE2AA40] DEFAULT ((0)) NOT NULL,
    [NTAXAMTFC]       NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__NTAXAMTF__2BD6CE79] DEFAULT ((0)) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)        CONSTRAINT [DF__DMEMOS__FCUSED_U__2CCAF2B2] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)        CONSTRAINT [DF__DMEMOS__FCHIST_K__2DBF16EB] DEFAULT ('') NOT NULL,
    [DMTOTALPR]       NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__DMTOTALP__3A3B9317] DEFAULT ((0)) NOT NULL,
    [DMAPPLIEDPR]     NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__DMAPPLIE__3B2FB750] DEFAULT ((0)) NOT NULL,
    [NDISCAMTPR]      NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__NDISCAMT__3C23DB89] DEFAULT ((0)) NOT NULL,
    [NTAXAMTPR]       NUMERIC (10, 2)  CONSTRAINT [DF__DMEMOS__NTAXAMTP__3D17FFC2] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)        CONSTRAINT [DF__DMEMOS__PRFCUSED__3E0C23FB] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__DMEMOS__FUNCFCUS__3F004834] DEFAULT ('') NOT NULL,
    [SaveUserId]      UNIQUEIDENTIFIER NULL,
    [EditUserId]      UNIQUEIDENTIFIER NULL,
    CONSTRAINT [DMEMOS_PK] PRIMARY KEY CLUSTERED ([UNIQDMHEAD] ASC)
);


GO
CREATE NONCLUSTERED INDEX [DMDATE]
    ON [dbo].[DMEMOS]([DMDATE] ASC);


GO
CREATE NONCLUSTERED INDEX [DMEMONO]
    ON [dbo].[DMEMOS]([DMEMONO] ASC);


GO
CREATE NONCLUSTERED INDEX [DMRUNIQUE]
    ON [dbo].[DMEMOS]([DMRUNIQUE] ASC);


GO
CREATE NONCLUSTERED INDEX [INVNO]
    ON [dbo].[DMEMOS]([INVNO] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL_STATUS]
    ON [dbo].[DMEMOS]([IS_REL_GL] ASC, [DMSTATUS] ASC)
    INCLUDE([UNIQDMHEAD], [DMDATE], [DMEMONO], [UNIQSUPNO]);


GO
CREATE NONCLUSTERED INDEX [uniqsupno]
    ON [dbo].[DMEMOS]([UNIQSUPNO] ASC);


GO
CREATE NONCLUSTERED INDEX [uniqueaphead]
    ON [dbo].[DMEMOS]([UNIQAPHEAD] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 1/15/2014
-- Description:	Insert trigger for debit memo. When debit memo is created from DMR insert e-mail notification into a queue
-- 01/15/14 YS added new column notificationType varchar(20)
--- coud have 'N' - for notification
---			  'E' - for email
---			  'N,E' - for both
--- open for future methods of notification
-- 04/08/15 YS user settings are saved in WmSettingsManagement
-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
-- =============================================
CREATE TRIGGER [dbo].[Dmemos_Insert]
   ON  [dbo].[DMEMOS]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    declare @defaultEmail varchar(max)='',@EmailTo varchar(max)=' ',@body varchar(max)=' '


    -- check if DM was created by DMR
     
    
    SELECT @body =
    REPLACE(REPLACE ( 
	 (
     select '<p>Debit Memo:<b>'+I.Dmemono+
			'</b> has been created for Invoice <b>'+rtrim(I.Invno)+
			'</b> as a result of the  DMR #: <b>'+D.Dmr_No+'</b></p>'
			FROM Inserted I inner join PORECMRB D on I.DMRUNIQUE =D.DMRUNIQUE where i.DMRUNIQUE<>' '
        for xml path('')
	)
     ,'&lt;' , '<' ),'&gt;','>')
   -- insert into @fromDMr SELECT i.dmrunique, i.DMEMONO,i.INVNO,d.DMR_NO ,d.RMA_NO ,d.RMA_DATE 
			--from inserted I inner join PORECMRB D on I.DMRUNIQUE =D.DMRUNIQUE where i.DMRUNIQUE<>' '
	if (@body <>' ' and @body is not null)
	begin
	-- check if notification trigger set and subscribers subscribed
	-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
	SELECT @EmailTo =
	 STUFF(
	(
     select  ', ' +  P.EMAIL   + ''
		--from aspnet_Profile P  inner join wmTriggersActionSubsc AT on AT.fkUserId=P.UserId
		from aspnet_Membership P  inner join wmTriggersActionSubsc AT on AT.fkUserId=P.UserId
		where AT.fkActTriggerId in (select acttriggerid from MnxTriggersAction where triggerName ='DMR DM Created')
		and charindex('E',AT.notificationType)<>0 and P.EMAIL <>' ' and P.EMAIL is not null
	for xml path('')
	),
	1,1,'')
	if (@EmailTo<>' ' and @EmailTo is not null)
		begin
		-- 04/08/15 YS user settings are saved in WmSettingsManagement
		select @defaultEmail = ISNULL(s.settingValue,w.settingValue) from MnxSettingsManagement S LEFT OUTER JOIN WmSettingsManagement W ON S.settingid=w.settingid
			where S.settingName='defaultEmail'
		BEGIN TRANSACTION
			
		
		INSERT INTO wmTriggerEmails   
		(
		toEmail 
		,tocc 
		,tobcc   
		,fromEmail 
		,fromPw 
		,[subject]   
		, body
		,attachments  
		,isHtml   
		,dateAdded 
		,deleteOnSend 
		-- 01/15/14 added link to mnxTriggersAction or wmTriggers. Empty if not provided
		,fktriggerID 
		)
		select @EmailTo as toEmail
		,'' as tocc 
		,'' as tobcc   
		,@defaultEmail as fromEmail 
		,NULL as fromPw 
		,MnxTriggersAction.subjectTemplate as [subject]   
		,@body as body
		,NULL as attachments  
		,1 as isHtml   
		,getdate() 
		,0 
		,MnxTriggersAction.actTriggerId as fktriggerID from MnxTriggersAction where triggerName ='DMR DM Created'
		COMMIT
		
		end --- (@EmailTo<>' ') and @EmailTo is not null	
	end	--- (@body <>' ' and @body is not null)	

END