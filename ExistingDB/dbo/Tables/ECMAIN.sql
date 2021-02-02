CREATE TABLE [dbo].[ECMAIN] (
    [UNIQECNO]                 CHAR (10)        CONSTRAINT [DF__ECMAIN__UNIQECNO__46BD6CDA] DEFAULT ('') NOT NULL,
    [ECONO]                    CHAR (20)        CONSTRAINT [DF__ECMAIN__ECONO__47B19113] DEFAULT ('') NOT NULL,
    [BOMCUSTNO]                CHAR (10)        CONSTRAINT [DF__ECMAIN__BOMCUSTN__48A5B54C] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]                 CHAR (10)        CONSTRAINT [DF__ECMAIN__UNIQ_KEY__4999D985] DEFAULT ('') NOT NULL,
    [CHANGETYPE]               CHAR (10)        CONSTRAINT [DF__ECMAIN__CHANGETY__4A8DFDBE] DEFAULT ('') NOT NULL,
    [ECSTATUS]                 NVARCHAR (100)   NOT NULL,
    [PURPOSE]                  TEXT             CONSTRAINT [DF__ECMAIN__PURPOSE__4C764630] DEFAULT ('') NOT NULL,
    [ECDESCRIPT]               TEXT             CONSTRAINT [DF__ECMAIN__ECDESCRI__4D6A6A69] DEFAULT ('') NOT NULL,
    [OUNITCOST]                NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__OUNITCOS__4E5E8EA2] DEFAULT ((0)) NOT NULL,
    [NUNITCOST]                NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NUNITCOS__4F52B2DB] DEFAULT ((0)) NOT NULL,
    [FGIBAL]                   NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__FGIBAL__5046D714] DEFAULT ((0)) NOT NULL,
    [FGIUPDATE]                NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__FGIUPDAT__513AFB4D] DEFAULT ((0)) NOT NULL,
    [WIPUPDATE]                NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__WIPUPDAT__522F1F86] DEFAULT ((0)) NOT NULL,
    [TOTMATL]                  NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTMATL__532343BF] DEFAULT ((0)) NOT NULL,
    [TOTLABOR]                 NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTLABOR__541767F8] DEFAULT ((0)) NOT NULL,
    [TOTMISC]                  NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTMISC__550B8C31] DEFAULT ((0)) NOT NULL,
    [NETMATLCHG]               NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NETMATLC__55FFB06A] DEFAULT ((0)) NOT NULL,
    [EXPDATE]                  SMALLDATETIME    NULL,
    [TOTRWKMATL]               NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKMA__56F3D4A3] DEFAULT ((0)) NOT NULL,
    [TOTRWKLAB]                NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKLA__57E7F8DC] DEFAULT ((0)) NOT NULL,
    [TOTRWKMISC]               NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTRWKMI__58DC1D15] DEFAULT ((0)) NOT NULL,
    [RWKMATLEA]                NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__RWKMATLE__59D0414E] DEFAULT ((0)) NOT NULL,
    [RWKMATLQTY]               NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__RWKMATLQ__5AC46587] DEFAULT ((0)) NOT NULL,
    [RWKLABEA]                 NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__RWKLABEA__5BB889C0] DEFAULT ((0)) NOT NULL,
    [RWKLABQTY]                NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__RWKLABQT__5CACADF9] DEFAULT ((0)) NOT NULL,
    [TOTRWKCOST]               NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKCO__5DA0D232] DEFAULT ((0)) NOT NULL,
    [CHGSTDCOST]               BIT              CONSTRAINT [DF__ECMAIN__CHGSTDCO__5E94F66B] DEFAULT ((0)) NOT NULL,
    [NEWSTDCOST]               NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NEWSTDCO__5F891AA4] DEFAULT ((0)) NOT NULL,
    [CHGLBCOST]                BIT              CONSTRAINT [DF__ECMAIN__CHGLBCOS__607D3EDD] DEFAULT ((0)) NOT NULL,
    [NEWLBCOST]                NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NEWLBCOS__61716316] DEFAULT ((0)) NOT NULL,
    [CHGPRODNO]                BIT              CONSTRAINT [DF__ECMAIN__CHGPRODN__6265874F] DEFAULT ((0)) NOT NULL,
    [NEWPRODNO]                CHAR (25)        CONSTRAINT [DF__ECMAIN__NEWPRODN__6359AB88] DEFAULT ('') NOT NULL,
    [CHGREV]                   BIT              CONSTRAINT [DF__ECMAIN__CHGREV__644DCFC1] DEFAULT ((0)) NOT NULL,
    [NEWREV]                   CHAR (8)         CONSTRAINT [DF__ECMAIN__NEWREV__6541F3FA] DEFAULT ('') NULL,
    [CHGDESCR]                 BIT              CONSTRAINT [DF__ECMAIN__CHGDESCR__66361833] DEFAULT ((0)) NOT NULL,
    [NEWDESCR]                 CHAR (45)        CONSTRAINT [DF__ECMAIN__NEWDESCR__672A3C6C] DEFAULT ('') NOT NULL,
    [CHGSERNO]                 BIT              CONSTRAINT [DF__ECMAIN__CHGSERNO__681E60A5] DEFAULT ((0)) NOT NULL,
    [NEWSERNO]                 BIT              CONSTRAINT [DF__ECMAIN__NEWSERNO__691284DE] DEFAULT ((0)) NOT NULL,
    [COPYPHANT]                BIT              CONSTRAINT [DF__ECMAIN__COPYPHAN__6BEEF189] DEFAULT ((0)) NOT NULL,
    [COPYABC]                  BIT              CONSTRAINT [DF__ECMAIN__COPYABC__6CE315C2] DEFAULT ((0)) NOT NULL,
    [COPYORDPOL]               BIT              CONSTRAINT [DF__ECMAIN__COPYORDP__6DD739FB] DEFAULT ((0)) NOT NULL,
    [COPYLEADTM]               BIT              CONSTRAINT [DF__ECMAIN__COPYLEAD__6ECB5E34] DEFAULT ((0)) NOT NULL,
    [COPYNOTE]                 BIT              CONSTRAINT [DF__ECMAIN__COPYNOTE__6FBF826D] DEFAULT ((0)) NOT NULL,
    [COPYSPEC]                 BIT              CONSTRAINT [DF__ECMAIN__COPYSPEC__70B3A6A6] DEFAULT ((0)) NOT NULL,
    [COPYWKCTRS]               BIT              CONSTRAINT [DF__ECMAIN__COPYWKCT__71A7CADF] DEFAULT ((0)) NOT NULL,
    [COPYWOLIST]               BIT              CONSTRAINT [DF__ECMAIN__COPYWOLI__729BEF18] DEFAULT ((0)) NOT NULL,
    [COPYTOOL]                 BIT              CONSTRAINT [DF__ECMAIN__COPYTOOL__73901351] DEFAULT ((0)) NOT NULL,
    [COPYOUTS]                 BIT              CONSTRAINT [DF__ECMAIN__COPYOUTS__7484378A] DEFAULT ((0)) NOT NULL,
    [COPYDOCS]                 BIT              CONSTRAINT [DF__ECMAIN__COPYDOCS__75785BC3] DEFAULT ((0)) NOT NULL,
    [COPYINST]                 BIT              CONSTRAINT [DF__ECMAIN__COPYINST__766C7FFC] DEFAULT ((0)) NOT NULL,
    [COPYCKLIST]               BIT              CONSTRAINT [DF__ECMAIN__COPYCKLI__7760A435] DEFAULT ((0)) NOT NULL,
    [COPYSSNO]                 BIT              CONSTRAINT [DF__ECMAIN__COPYSSNO__7854C86E] DEFAULT ((0)) NOT NULL,
    [COPYBMNOTE]               BIT              CONSTRAINT [DF__ECMAIN__COPYBMNO__7A3D10E0] DEFAULT ((0)) NOT NULL,
    [COPYEFFDTS]               BIT              CONSTRAINT [DF__ECMAIN__COPYEFFD__7B313519] DEFAULT ((0)) NOT NULL,
    [COPYREFDES]               BIT              CONSTRAINT [DF__ECMAIN__COPYREFD__7C255952] DEFAULT ((0)) NOT NULL,
    [COPYALTPTS]               BIT              CONSTRAINT [DF__ECMAIN__COPYALTP__7D197D8B] DEFAULT ((0)) NOT NULL,
    [OPENDATE]                 SMALLDATETIME    NULL,
    [UPDATEDDT]                SMALLDATETIME    NULL,
    [ECOREF]                   CHAR (15)        CONSTRAINT [DF__ECMAIN__ECOREF__7E0DA1C4] DEFAULT ('') NOT NULL,
    [CHGCUST]                  BIT              CONSTRAINT [DF__ECMAIN__CHGCUST__7F01C5FD] DEFAULT ((0)) NOT NULL,
    [NEWCUSTNO]                CHAR (10)        CONSTRAINT [DF__ECMAIN__NEWCUSTN__7FF5EA36] DEFAULT ('') NOT NULL,
    [TOTRWKWCST]               NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKWC__00EA0E6F] DEFAULT ((0)) NOT NULL,
    [TOTRWKFCST]               NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKFC__01DE32A8] DEFAULT ((0)) NOT NULL,
    [NEWMATLCST]               NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NEWMATLC__02D256E1] DEFAULT ((0)) NOT NULL,
    [BOM_NOTE]                 TEXT             CONSTRAINT [DF__ECMAIN__BOM_NOTE__03C67B1A] DEFAULT ('') NOT NULL,
    [ECOFILE]                  CHAR (200)       CONSTRAINT [DF__ECMAIN__ECOFILE__04BA9F53] DEFAULT ('') NOT NULL,
    [ECOSOURCE]                CHAR (10)        CONSTRAINT [DF__ECMAIN__ECOSOURC__05AEC38C] DEFAULT ('') NOT NULL,
    [EFFECTIVEDT]              SMALLDATETIME    NULL,
    [ECOLOCK]                  BIT              CONSTRAINT [DF__ECMAIN__ECOLOCK__06A2E7C5] DEFAULT ((0)) NOT NULL,
    [ECOLOCKDT]                SMALLDATETIME    NULL,
    [SAVEDT]                   SMALLDATETIME    NULL,
    [SAVEINT]                  CHAR (8)         CONSTRAINT [DF__ECMAIN__SAVEINT__088B3037] DEFAULT ('') NULL,
    [ORIGINDOC]                CHAR (200)       CONSTRAINT [DF__ECMAIN__ORIGINDO__097F5470] DEFAULT ('') NOT NULL,
    [UPDSOPRICE]               BIT              CONSTRAINT [DF__ECMAIN__UPDSOPRI__0A7378A9] DEFAULT ((0)) NOT NULL,
    [ECOITEMARC]               BIT              CONSTRAINT [DF__ECMAIN__ECOITEMA__0B679CE2] DEFAULT ((0)) NOT NULL,
    [COPYOTHPRC]               BIT              CONSTRAINT [DF__ECMAIN__COPYOTHP__0C5BC11B] DEFAULT ((0)) NOT NULL,
    [lCopySupplier]            BIT              CONSTRAINT [DF__ECMAIN__lCopySup__139E86DE] DEFAULT ((0)) NOT NULL,
    [lUpdateMPN]               BIT              CONSTRAINT [DF__ECMAIN__lUpdateM__1492AB17] DEFAULT ((0)) NOT NULL,
    [NEWSTDCOSTPR]             NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NEWSTDCO__2E0AC65C] DEFAULT ((0)) NOT NULL,
    [OUNITCOSTPR]              NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__OUNITCOS__54DA7ABA] DEFAULT ((0)) NOT NULL,
    [NUNITCOSTPR]              NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NUNITCOS__55CE9EF3] DEFAULT ((0)) NOT NULL,
    [TOTMATLPR]                NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTMATLP__56C2C32C] DEFAULT ((0)) NOT NULL,
    [TOTLABORPR]               NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTLABOR__57B6E765] DEFAULT ((0)) NOT NULL,
    [TOTMISCPR]                NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTMISCP__58AB0B9E] DEFAULT ((0)) NOT NULL,
    [NETMATLCHGPR]             NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NETMATLC__599F2FD7] DEFAULT ((0)) NOT NULL,
    [TOTRWKMATLPR]             NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKMA__5A935410] DEFAULT ((0)) NOT NULL,
    [TOTRWKLABPR]              NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKLA__5B877849] DEFAULT ((0)) NOT NULL,
    [TOTRWKMISCPR]             NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__TOTRWKMI__5C7B9C82] DEFAULT ((0)) NOT NULL,
    [RWKMATLEAPR]              NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__RWKMATLE__5D6FC0BB] DEFAULT ((0)) NOT NULL,
    [RWKLABEAPR]               NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__RWKLABEA__5E63E4F4] DEFAULT ((0)) NOT NULL,
    [TOTRWKCOSTPR]             NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKCO__5F58092D] DEFAULT ((0)) NOT NULL,
    [NEWLBCOSTPR]              NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NEWLBCOS__604C2D66] DEFAULT ((0)) NOT NULL,
    [TOTRWKWCSTPR]             NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKWC__6140519F] DEFAULT ((0)) NOT NULL,
    [TOTRWKFCSTPR]             NUMERIC (10, 2)  CONSTRAINT [DF__ECMAIN__TOTRWKFC__623475D8] DEFAULT ((0)) NOT NULL,
    [NEWMATLCSTPR]             NUMERIC (13, 5)  CONSTRAINT [DF__ECMAIN__NEWMATLC__63289A11] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]            CHAR (10)        CONSTRAINT [DF__ECMAIN__PRFCUSED__641CBE4A] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ]          CHAR (10)        CONSTRAINT [DF__ECMAIN__FUNCFCUS__6510E283] DEFAULT ('') NOT NULL,
    [Uniquerout]               CHAR (10)        CONSTRAINT [DF__ECMAIN__UniquetR__3E570815] DEFAULT ('') NOT NULL,
    [NewBOMCUSTNO]             CHAR (10)        CONSTRAINT [DF__ECMAIN__NewBOMCU__4835780A] DEFAULT ('') NOT NULL,
    [ENGINEER]                 UNIQUEIDENTIFIER NULL,
    [IsApproveProcess]         BIT              NULL,
    [aspBuyerReadyForApproval] UNIQUEIDENTIFIER NULL,
    [MailSent]                 BIT              CONSTRAINT [DF__ECMAIN__MailSent__4A339A6C] DEFAULT ((0)) NOT NULL,
    [ECOLOCKINT]               UNIQUEIDENTIFIER NULL,
    CONSTRAINT [ECMAIN_PK] PRIMARY KEY CLUSTERED ([UNIQECNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BOMCUSTNO]
    ON [dbo].[ECMAIN]([BOMCUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [ECONO]
    ON [dbo].[ECMAIN]([ECONO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[ECMAIN]([UNIQ_KEY] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/27/15
-- Description:	Insert trigger for ECO. When ECO is created, need to insert e-mail notification into a queue
-- Modification:
--	09/01/15	VL	Allow BCN to send trigger in 'ECO' case
-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
-- =============================================
CREATE TRIGGER [dbo].[Ecmain_Insert]
   ON  [dbo].[ECMAIN]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    declare @defaultEmail varchar(max)='',@EmailTo varchar(max)=' ',@body varchar(max)=' ', @ChangeType char(10)=' ', @Triggername char(20) = ' '
	-- only send trigger email if ChangeType = 'ECO' or 'DEVIATION'
	SELECT @ChangeType = ChangeType FROM inserted

	IF @ChangeType = 'ECO' OR @ChangeType = 'DEVIATION' OR @ChangeType = 'BCN'
		BEGIN	
		--SELECT @TriggerName = CASE WHEN @ChangeType = 'ECO' THEN 'ECO Initiated' ELSE CASE WHEN @ChangeType = 'DEVIATION' THEN 'Deviation Initiated' ELSE 'BCN Initiated' END END
		SELECT @TriggerName = CASE WHEN (@ChangeType = 'ECO' OR @ChangeType = 'BCN') THEN 'ECO Initiated' ELSE 'Deviation Initiated' END
		
		-- Prepare body part for ECO    
		SELECT @body =
		REPLACE(REPLACE ( 
		 (
		 select '<p>ECO No <b>'+LTRIM(RTRIM(I.EcoNo))+'</b></p>'+
				'<p>Product Number: <b>' + LTRIM(RTRIM(P.Part_no))+' '+LTRIM(RTRIM(P.Revision))+'</b></p>'+
				'<p>Purpose of Changes: <b>'+LTRIM(RTRIM(CAST(E.Purpose AS varchar(max))))+'</b></p>'
				FROM Inserted I inner join Ecmain E ON I.UniqEcno = E.UniqEcno INNER JOIN Inventor P on I.Uniq_key = P.Uniq_key where I.UniqEcno<>' '
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
		 select  ', ' +  P.EMAIL  + ''
			from aspnet_membership P  inner join wmTriggersActionSubsc AT on AT.fkUserId=P.UserId
			where AT.fkActTriggerId in (select acttriggerid from MnxTriggersAction where triggerName =@TriggerName)
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
			,MnxTriggersAction.actTriggerId as fktriggerID from MnxTriggersAction where triggerName =@TriggerName
			COMMIT
		
			end --- (@EmailTo<>' ') and @EmailTo is not null	
		end	--- (@body <>' ' and @body is not null)	
	END --  end of ChangeType = 'ECO' or 'DEVIATION'
END
GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/27/15
-- Description:	Update trigger for ECO. When ECO is completed, need to insert e-mail notification into a queue
-- Modification: Only send trigger email if Ecstatus is 'Complete' and ChangeType ='ECO'
-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
-- =============================================
CREATE TRIGGER [dbo].[Ecmain_Update]
   ON [dbo].[ECMAIN]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    declare @defaultEmail varchar(max)='',@EmailTo varchar(max)=' ',@body varchar(max)=' ', @ChangeType char(10)=' ', @EcStatus char(10)
	-- 09/02/15 VL Only send trigger email if Ecstatus is 'Complete' and ChangeType ='ECO'
	SELECT @ChangeType = ChangeType, @EcStatus = EcStatus FROM inserted
	IF (@ChangeType = 'ECO' OR @ChangeType = 'BCN') AND @EcStatus = 'Completed'
	BEGIN
		-- Prepare body part for ECO   
		-- inner join between inserted and ecmain to get purpose because text field is not allowed in inserted and deleted, also use cast() otherwise get Argument data type ntext is invalid for argument 1 of left or rtrim... function error
		SELECT @body =
		REPLACE(REPLACE ( 
			(
			select '<p>ECO No <b>'+LTRIM(RTRIM(I.EcoNo))+'</b></p>'+
				'<p>Product Number: <b>' + LTRIM(RTRIM(P.Part_no))+' '+LTRIM(RTRIM(P.Revision))+'</b></p>'+
				'<p>Purpose of Changes: <b>'+LTRIM(RTRIM(CAST(E.Purpose AS varchar(max))))+'</b></p>'
				FROM Inserted I inner join Ecmain E ON I.UniqEcno = E.UniqEcno INNER JOIN Inventor P on I.Uniq_key = P.Uniq_key where I.UniqEcno<>' '
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
			from aspnet_Membership P  inner join wmTriggersActionSubsc AT on AT.fkUserId=P.UserId
			where AT.fkActTriggerId in (select acttriggerid from MnxTriggersAction where triggerName = 'ECO Released')
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
			,MnxTriggersAction.actTriggerId as fktriggerID from MnxTriggersAction where triggerName = 'ECO Released'
			COMMIT
		
			end --- (@EmailTo<>' ') and @EmailTo is not null	
		end	--- (@body <>' ' and @body is not null)	
	END
END