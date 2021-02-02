CREATE TABLE [dbo].[CMMAIN] (
    [SNAME]           CHAR (35)       CONSTRAINT [DF__CMMAIN__SNAME__253C7D7E] DEFAULT ('') NOT NULL,
    [TRANS_NO]        NUMERIC (7)     CONSTRAINT [DF__CMMAIN__TRANS_NO__2630A1B7] DEFAULT ((0)) NOT NULL,
    [CMDATE]          SMALLDATETIME   CONSTRAINT [DF_CMMAIN_CMDATE] DEFAULT (getdate()) NULL,
    [CMEMONO]         CHAR (10)       CONSTRAINT [DF__CMMAIN__CMEMONO__2724C5F0] DEFAULT ('') NOT NULL,
    [INVDATE]         SMALLDATETIME   NULL,
    [INVOICENO]       CHAR (10)       CONSTRAINT [DF__CMMAIN__INVOICEN__2818EA29] DEFAULT ('') NOT NULL,
    [PACKLISTNO]      CHAR (10)       CONSTRAINT [DF__CMMAIN__PACKLIST__290D0E62] DEFAULT ('') NOT NULL,
    [SONO]            CHAR (10)       CONSTRAINT [DF__CMMAIN__SONO__2A01329B] DEFAULT ('') NOT NULL,
    [CUSTNO]          CHAR (10)       CONSTRAINT [DF__CMMAIN__CUSTNO__2AF556D4] DEFAULT ('') NOT NULL,
    [SAVEINIT]        CHAR (8)        CONSTRAINT [DF__CMMAIN__SAVEINIT__2BE97B0D] DEFAULT ('') NULL,
    [LINKADD]         CHAR (10)       CONSTRAINT [DF__CMMAIN__LINKADD__2CDD9F46] DEFAULT ('') NOT NULL,
    [FRT_TXBLE]       BIT             CONSTRAINT [DF__CMMAIN__FRT_TXBL__2EC5E7B8] DEFAULT ((0)) NOT NULL,
    [CM_FRT]          NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__CM_FRT__2FBA0BF1] DEFAULT ((0)) NOT NULL,
    [CM_FRT_TAX]      NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__CM_FRT_T__30AE302A] DEFAULT ((0)) NOT NULL,
    [CMSTDPRICE]      NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__CMSTDPRI__31A25463] DEFAULT ((0)) NOT NULL,
    [CMTOTEXTEN]      NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__CMTOTEXT__3296789C] DEFAULT ((0)) NOT NULL,
    [CMSTD_TAX]       BIT             CONSTRAINT [DF__CMMAIN__CMSTD_TA__338A9CD5] DEFAULT ((0)) NOT NULL,
    [TOTTAXE]         NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__TOTTAXE__347EC10E] DEFAULT ((0)) NOT NULL,
    [CMTOTAL]         NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__CMTOTAL__3572E547] DEFAULT ((0)) NOT NULL,
    [CMREASON]        TEXT            CONSTRAINT [DF__CMMAIN__CMREASON__36670980] DEFAULT ('') NOT NULL,
    [CM_DUPL]         BIT             CONSTRAINT [DF__CMMAIN__CM_DUPL__375B2DB9] DEFAULT ((0)) NOT NULL,
    [CMTYPE]          CHAR (1)        CONSTRAINT [DF__CMMAIN__CMTYPE__384F51F2] DEFAULT ('') NOT NULL,
    [INVTOTAL]        NUMERIC (14, 2) CONSTRAINT [DF__CMMAIN__INVTOTAL__3943762B] DEFAULT ((0)) NOT NULL,
    [IS_REL_GL]       BIT             CONSTRAINT [DF__CMMAIN__IS_REL_G__3A379A64] DEFAULT ((0)) NOT NULL,
    [IS_CMPOST]       BIT             CONSTRAINT [DF__CMMAIN__IS_CMPOS__3B2BBE9D] DEFAULT ((0)) NOT NULL,
    [IS_CMPRN]        BIT             CONSTRAINT [DF__CMMAIN__IS_CMPRN__3C1FE2D6] DEFAULT ((0)) NOT NULL,
    [TERMS]           CHAR (15)       CONSTRAINT [DF__CMMAIN__TERMS__3E082B48] DEFAULT ('') NOT NULL,
    [BLINKADD]        CHAR (10)       CONSTRAINT [DF__CMMAIN__BLINKADD__5026DB83] DEFAULT ('') NOT NULL,
    [DESC_1_TM]       CHAR (30)       CONSTRAINT [DF__CMMAIN__DESC_1_T__511AFFBC] DEFAULT ('') NOT NULL,
    [DESC_OTH]        CHAR (30)       CONSTRAINT [DF__CMMAIN__DESC_OTH__520F23F5] DEFAULT ('') NOT NULL,
    [PRNT_INV]        BIT             CONSTRAINT [DF__CMMAIN__PRNT_INV__53F76C67] DEFAULT ((0)) NOT NULL,
    [COG_GL_NBR]      CHAR (13)       CONSTRAINT [DF__CMMAIN__COG_GL_N__57C7FD4B] DEFAULT ('') NOT NULL,
    [FRT_GL_NO]       CHAR (13)       CONSTRAINT [DF__CMMAIN__FRT_GL_N__5C8CB268] DEFAULT ('') NOT NULL,
    [FC_GL_NO]        CHAR (13)       CONSTRAINT [DF__CMMAIN__FC_GL_NO__5D80D6A1] DEFAULT ('') NOT NULL,
    [DISC_GL_NO]      CHAR (13)       CONSTRAINT [DF__CMMAIN__DISC_GL___5E74FADA] DEFAULT ('') NOT NULL,
    [AR_GL_NO]        CHAR (13)       CONSTRAINT [DF__CMMAIN__AR_GL_NO__5F691F13] DEFAULT ('') NOT NULL,
    [PRINTED]         BIT             CONSTRAINT [DF__CMMAIN__PRINTED__605D434C] DEFAULT ((0)) NOT NULL,
    [TotExten]        NUMERIC (13, 2) CONSTRAINT [DF_CMMAIN_TotExten] DEFAULT ((0.00)) NOT NULL,
    [INV_DUPL]        BIT             CONSTRAINT [DF__CMMAIN__INV_DUPL__6521F869] DEFAULT ((0)) NOT NULL,
    [IS_RMA]          BIT             CONSTRAINT [DF__CMMAIN__IS_RMA__66161CA2] DEFAULT ((0)) NOT NULL,
    [RECVDATE]        SMALLDATETIME   NULL,
    [FOB]             CHAR (15)       CONSTRAINT [DF__CMMAIN__FOB__67FE6514] DEFAULT ('') NOT NULL,
    [SHIPVIA]         CHAR (15)       CONSTRAINT [DF__CMMAIN__SHIPVIA__68F2894D] DEFAULT ('') NOT NULL,
    [SHIPCHARGE]      CHAR (15)       CONSTRAINT [DF__CMMAIN__SHIPCHAR__69E6AD86] DEFAULT ('') NOT NULL,
    [DSCTAMT]         NUMERIC (17, 2) CONSTRAINT [DF__CMMAIN__DSCTAMT__6CC31A31] DEFAULT ((0)) NOT NULL,
    [CSTATUS]         CHAR (10)       CONSTRAINT [DF__CMMAIN__CSTATUS__6DB73E6A] DEFAULT ('') NOT NULL,
    [CAPPVNAME]       CHAR (8)        CONSTRAINT [DF__CMMAIN__CAPPVNAM__6EAB62A3] DEFAULT ('') NOT NULL,
    [TAPPVDTTIME]     SMALLDATETIME   NULL,
    [DSAVEDATE]       SMALLDATETIME   NULL,
    [LSALESTAXONlY]   BIT             CONSTRAINT [DF__CMMAIN__LSALESTA__6F9F86DC] DEFAULT ((0)) NOT NULL,
    [LFREIGHTONLY]    BIT             CONSTRAINT [DF__CMMAIN__LFREIGHT__7093AB15] DEFAULT ((0)) NOT NULL,
    [LFREIGHTTAXONLY] BIT             CONSTRAINT [DF__CMMAIN__LFREIGHT__7187CF4E] DEFAULT ((0)) NOT NULL,
    [PTAX]            NUMERIC (17, 2) CONSTRAINT [DF__CMMAIN__PTAX__727BF387] DEFAULT ((0)) NOT NULL,
    [STAX]            NUMERIC (17, 2) CONSTRAINT [DF__CMMAIN__STAX__737017C0] DEFAULT ((0)) NOT NULL,
    [CMUNIQUE]        CHAR (10)       CONSTRAINT [DF__CMMAIN__CMUNIQUE__74643BF9] DEFAULT ('') NOT NULL,
    [cRMANO]          CHAR (10)       CONSTRAINT [DF_CMMAIN_cRMANO] DEFAULT ('') NOT NULL,
    [RecVer]          ROWVERSION      NOT NULL,
    [Attention]       CHAR (10)       CONSTRAINT [DF_CMMAIN_Attention] DEFAULT ('') NOT NULL,
    [WayBill]         CHAR (20)       CONSTRAINT [DF_CMMAIN_Waybill] DEFAULT ('') NOT NULL,
    [Rmar_Foot]       TEXT            CONSTRAINT [DF_CMMAIN_Rmar_foot] DEFAULT ('') NOT NULL,
    [CM_FRTFC]        NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__CM_FRTFC__1EDBFAB7] DEFAULT ((0)) NOT NULL,
    [CM_FRT_TAXFC]    NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__CM_FRT_T__1FD01EF0] DEFAULT ((0)) NOT NULL,
    [CMTOTEXTENFC]    NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__CMTOTEXT__20C44329] DEFAULT ((0)) NOT NULL,
    [TOTTAXEFC]       NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__TOTTAXEF__21B86762] DEFAULT ((0)) NOT NULL,
    [CMTOTALFC]       NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__CMTOTALF__22AC8B9B] DEFAULT ((0)) NOT NULL,
    [INVTOTALFC]      NUMERIC (14, 2) CONSTRAINT [DF__CMMAIN__INVTOTAL__23A0AFD4] DEFAULT ((0)) NOT NULL,
    [TOTEXTENFC]      NUMERIC (13, 2) CONSTRAINT [DF__CMMAIN__TOTEXTEN__2494D40D] DEFAULT ((0)) NOT NULL,
    [DSCTAMTFC]       NUMERIC (17, 2) CONSTRAINT [DF__CMMAIN__DSCTAMTF__2588F846] DEFAULT ((0)) NOT NULL,
    [PTAXFC]          NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__PTAXFC__267D1C7F] DEFAULT ((0)) NOT NULL,
    [STAXFC]          NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__STAXFC__277140B8] DEFAULT ((0)) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)       CONSTRAINT [DF__CMMAIN__FCUSED_U__300686B9] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__CMMAIN__FCHIST_K__30FAAAF2] DEFAULT ('') NOT NULL,
    [CM_FRTPR]        NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__CM_FRTPR__649BE137] DEFAULT ((0)) NOT NULL,
    [CM_FRT_TAXPR]    NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__CM_FRT_T__65900570] DEFAULT ((0)) NOT NULL,
    [CMTOTEXTENPR]    NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__CMTOTEXT__668429A9] DEFAULT ((0)) NOT NULL,
    [TOTTAXEPR]       NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__TOTTAXEP__67784DE2] DEFAULT ((0)) NOT NULL,
    [CMTOTALPR]       NUMERIC (12, 2) CONSTRAINT [DF__CMMAIN__CMTOTALP__686C721B] DEFAULT ((0)) NOT NULL,
    [INVTOTALPR]      NUMERIC (14, 2) CONSTRAINT [DF__CMMAIN__INVTOTAL__69609654] DEFAULT ((0)) NOT NULL,
    [TOTEXTENPR]      NUMERIC (13, 2) CONSTRAINT [DF__CMMAIN__TOTEXTEN__6A54BA8D] DEFAULT ((0)) NOT NULL,
    [DSCTAMTPR]       NUMERIC (17, 2) CONSTRAINT [DF__CMMAIN__DSCTAMTP__6B48DEC6] DEFAULT ((0)) NOT NULL,
    [PTAXPR]          NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__PTAXPR__6C3D02FF] DEFAULT ((0)) NOT NULL,
    [STAXPR]          NUMERIC (10, 2) CONSTRAINT [DF__CMMAIN__STAXPR__6D312738] DEFAULT ((0)) NOT NULL,
    [PRFcused_Uniq]   CHAR (10)       CONSTRAINT [DF__CMMAIN__PRFcused__6E254B71] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__CMMAIN__FUNCFCUS__6F196FAA] DEFAULT ('') NOT NULL,
    CONSTRAINT [CMMAIN_PK] PRIMARY KEY CLUSTERED ([CMUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CMEMONO]
    ON [dbo].[CMMAIN]([CMEMONO] ASC);


GO
CREATE NONCLUSTERED INDEX [INVOICENO]
    ON [dbo].[CMMAIN]([INVOICENO] ASC);


GO
CREATE NONCLUSTERED INDEX [PACKLISTNO]
    ON [dbo].[CMMAIN]([PACKLISTNO] ASC);


GO

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/06/2012
-- Description:	Insert trigger will check if the balance still the same as when CM was started
-- Modification:
-- 03/18/15 VL added FC fields and fob, shipvia, SHIPCHARGE, ATTENTION, TERMS
-- 07/20/16	VL	Added 'CM RMA Created' action trigger
-- 11/03/16 VL added PR fields
-- =============================================
CREATE TRIGGER [dbo].[CmMain_Insert]
   ON  [dbo].[CMMAIN] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    -- call "PlMain4CmView","gcInvoiceNo = '"+thisform.pcInvoiceNo+"'",'View' to check the current balance
    declare @tPlMain Table (custno char(10),packlistno char(10),InvTotal numeric(20,2),TotTaxE numeric(17,2),
				freightamt numeric(10,2), TotTaxF numeric(10,2),SumCmTotal numeric(20,2), 
				INVOICENO char(10),invdate smalldatetime,sono char(10),TotExten numeric(20,2),
				inv_foot text,linkadd char(10),frt_gl_no char(13),fc_gl_no chaR(13),blinkadd char(10) ,
				dsctamt numeric(17,2),disc_gl_no char(13),Ar_Gl_No char(13),
				PONO char(20),OrderDate smalldatetime,CustName char(35),ClosedTotal numeric(20,2),
				InvoiceTotal numeric(20,2),Arcredits numeric(20,2),OrigTotTaxe numeric(17,2),
				OrigFreightAmt numeric(10,2),OrigTotTaxF numeric(17,2),
				OrigTotExten numeric(20,2),OrigInvTotal numeric(20,2),OrigDsctAmt numeric(17,2),
				InvTotalFC numeric(20,2),TotTaxEFC numeric(17,2), freightamtFC numeric(10,2), 
				TotTaxFFC numeric(10,2),SumCmTotalFC numeric(20,2),
				TotExtenFC numeric(20,2), dsctamtFC numeric(17,2),ClosedTotalFC numeric(20,2),
				InvoiceTotalFC numeric(20,2),ArcreditsFC numeric(20,2),OrigTotTaxeFC numeric(17,2),
				OrigFreightAmtFC numeric(10,2),OrigTotTaxFFC numeric(17,2),
				OrigTotExtenFC numeric(20,2),OrigInvTotalFC numeric(20,2), rigDsctAmtFC numeric(17,2), 
				Fcused_uniq char(10), Fchist_key char(10), fob char(15), shipvia char(15), 
				SHIPCHARGE char(15), ATTENTION char(10), TERMS char(15),
				-- 11/03/16 VL added PR fields
				InvTotalPR numeric(20,2),TotTaxEPR numeric(17,2), freightamtPR numeric(10,2), 
				TotTaxFPR numeric(10,2),SumCmTotalPR numeric(20,2),
				TotExtenPR numeric(20,2), dsctamtPR numeric(17,2),ClosedTotalPR numeric(20,2),
				InvoiceTotalPR numeric(20,2),ArcreditsPR numeric(20,2),OrigTotTaxePR numeric(17,2),
				OrigFreightAmtPR numeric(10,2),OrigTotTaxFPR numeric(17,2),
				OrigTotExtenPR numeric(20,2),OrigInvTotalPR numeric(20,2), OrigDsctAmtPR numeric(17,2), PRFcused_uniq char(10), FuncFcused_uniq char(10))
					
	BEGIN TRANSACTION
	DECLARE @lcInvoiceno char(10),@CMUnique char(10),@cmtotal numeric(20,2),@tottaxe numeric(17,2),@cm_frt numeric(10,2),@cm_frt_tax numeric(10,2),@DSCTAMT numeric(17,2),@cmtotexten numeric(20,2)
	SELECT @lcInvoiceno=Invoiceno,@CMUnique=cmunique,@cmtotal=cmtotal,@tottaxe=tottaxe,@cm_frt=cm_frt,@cm_frt_tax=cm_frt_tax,@DSCTAMT=inserted.DSCTAMT,@cmtotexten=cmtotexten  FROM INSERTED
	INSERT INTO @tPlMain EXEC PlMain4CmView @lcInvoiceno ,@CMUnique
	
	IF @cmtotal>(select InvTotal FROM @tPlMain)
	BEGIN
		--- raise an error and rollback
		RAISERROR('You are trying to create a credit memo for more than invoice balance. Aborting Save transaction.',1,1)
		ROLLBACK TRANSACTION
		RETURN
	END	
	IF (Select @tottaxe-t.TotTaxe from @tPlMain t)>0.05 or ((SElect @tottaxe-t.TotTaxe from @tPlMain t)>0 and @cmtotal<>(SELECT InvTotal FROM @tPlMain t))
	BEGIN
		--- raise error
		RAISERROR('The sales tax amount on this credit memo is bigger than available to credit. Aborting Save transaction.',1,1)
		ROLLBACK TRANSACTION
		RETURN
	END	
	
	IF (SELECT @cm_frt-FreightAmt FROM @tPlMain ) >0.05 or ((SElect @cm_frt-FreightAmt from @tPlMain t)>0 and @cmtotal<>(SELECT InvTotal FROM @tPlMain t))
	BEGIN
	--- raise error
		RAISERROR('The freight amount on this credit memo is bigger than available to credit. Aborting Save transaction.',1,1)
		ROLLBACK TRANSACTION
		RETURN
	END	
	
	IF (SELECT @cm_frt_tax-TotTaxF FROM @tPlMain )>0.05 or  ((SElect @cm_frt_tax-TotTaxF from @tPlMain t)>0 and @cmtotal<>(SELECT InvTotal FROM @tPlMain t))
	BEGIN
	--- raise error
		RAISERROR('The freight tax amount on this credit memo is bigger than available to credit. Aborting Save transaction.',1,1)
		ROLLBACK TRANSACTION
		RETURN
	END	
	IF (SELECT @DSCTAMT-dsctamt FROM @tPlMain ) >0.05 or  ((SElect @DSCTAMT-dsctamt from @tPlMain t)>0 and @cmtotal<>(SELECT InvTotal FROM @tPlMain t))
	-- raise an error
	BEGIN
	--- raise error
		RAISERROR('The discount amount on this credit memo is bigger than available to credit. Aborting Save transaction.',1,1)
		ROLLBACK TRANSACTION
		RETURN
	END	
	
	IF (SELECT @cmtotexten-TotExten from @tPlMain) >0.05 or  ((SElect @cmtotexten-TotExten from @tPlMain t)>0 and @cmtotal<>(SELECT InvTotal FROM @tPlMain t))
	BEGIN
	--- raise error
		RAISERROR('The extended amount on this credit memo is bigger than available to credit. Aborting Save transaction.',1,1)
		ROLLBACK TRANSACTION
		RETURN
	END	
	-- 06/29/12 YS mark is_rel_gl records  as released if cmTotal=0
	-- 07/05/12 YS when CM created from RMA total is going to be 0 will update sp_Cmemo_Total
	UPDATE CmMain SET IS_REL_GL = CASE WHEN I.CMTotal =0.00 THEN 1 ELSE CmMain.IS_REL_GL END FROM inserted I WHERE I.CMUNIQUE=CmMain.CmUnique and I.IS_RMA =0 	
	COMMIT	

	-- 07/20/16 VL added the 'RMA CM Created' action trigger, copied the code from Porecdtl insert trigger and modified it
	-- Insert statements for trigger here
    declare @defaultEmail varchar(max)='',@EmailTo varchar(max)=' ',@body nvarchar(max)=' '


   -- reject material email    
    SELECT @body =
    REPLACE(REPLACE ( 
	 (
     select '<p>Credit Memo:<b>'+I.Cmemono+
			'</b> has been created for RMA: <b>'+rtrim(I.Sono)+
			'</b> as a result of the RMA Receiver #: <b>'+I.Packlistno+'</b></p>'
			FROM Inserted I 
	 for xml path('')
	)
     ,'&lt;' , '<' ),'&gt;','>')
	 
	 	  
	if (@body <>' ' and @body is not null)
	begin
	-- check if notification trigger set and subscribers subscribed
	--02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
	SELECT @EmailTo =
	 STUFF(
	(
     select  ', ' +  P.EMAIL   + ''
		from aspnet_Membership P  inner join wmTriggersActionSubsc AT on AT.fkUserId=P.UserId
		where AT.fkActTriggerId in (select acttriggerid from MnxTriggersAction where triggerName ='RMA CM Created')
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
		,MnxTriggersAction.actTriggerId as fktriggerID from MnxTriggersAction where triggerName ='RMA CM Created'
		COMMIT
		
		end --- (@EmailTo<>' ') and @EmailTo is not null	
	end	--- (@body <>' ' and @body is not null)	

	-- 07/20/16 VL End}	
END