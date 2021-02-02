CREATE TABLE [dbo].[SOMAIN] (
    [BLINKADD]        CHAR (10)       CONSTRAINT [DF__SOMAIN__BLINKADD__023403BA] DEFAULT ('') NOT NULL,
    [SONO]            CHAR (10)       CONSTRAINT [DF__SOMAIN__SONO__041C4C2C] DEFAULT ('') NOT NULL,
    [CUSTNO]          CHAR (10)       CONSTRAINT [DF__SOMAIN__CUSTNO__05107065] DEFAULT ('') NOT NULL,
    [SHIPNO]          CHAR (5)        CONSTRAINT [DF__SOMAIN__SHIPNO__0604949E] DEFAULT ('') NOT NULL,
    [ORDERDATE]       SMALLDATETIME   NULL,
    [TMPACK]          BIT             CONSTRAINT [DF__SOMAIN__TMPACK__06F8B8D7] DEFAULT ((0)) NOT NULL,
    [TMPACKDT]        SMALLDATETIME   NULL,
    [TMPACKINIT]      CHAR (8)        CONSTRAINT [DF__SOMAIN__TMPACKIN__07ECDD10] DEFAULT ('') NULL,
    [POACK]           BIT             CONSTRAINT [DF__SOMAIN__POACK__08E10149] DEFAULT ((0)) NOT NULL,
    [POACKDT]         SMALLDATETIME   NULL,
    [POACKINIT]       CHAR (8)        CONSTRAINT [DF__SOMAIN__POACKINI__09D52582] DEFAULT ('') NULL,
    [PORECEIV]        BIT             CONSTRAINT [DF__SOMAIN__PORECEIV__0AC949BB] DEFAULT ((0)) NOT NULL,
    [POREINIT]        CHAR (8)        CONSTRAINT [DF__SOMAIN__POREINIT__0BBD6DF4] DEFAULT ('') NULL,
    [POREDT]          SMALLDATETIME   NULL,
    [PONO]            CHAR (20)       CONSTRAINT [DF__SOMAIN__PONO__0CB1922D] DEFAULT ('') NOT NULL,
    [CUSTWONO]        CHAR (10)       CONSTRAINT [DF__SOMAIN__CUSTWONO__0DA5B666] DEFAULT ('') NOT NULL,
    [SONOTE]          TEXT            CONSTRAINT [DF__SOMAIN__SONOTE__0E99DA9F] DEFAULT ('') NOT NULL,
    [ORDPASSWD]       CHAR (5)        CONSTRAINT [DF__SOMAIN__ORDPASSW__0F8DFED8] DEFAULT ('') NOT NULL,
    [IS_CLOSED]       BIT             CONSTRAINT [DF__SOMAIN__IS_CLOSE__135E8FBC] DEFAULT ((0)) NOT NULL,
    [DATECHG]         SMALLDATETIME   NULL,
    [SOFOOT]          TEXT            CONSTRAINT [DF__SOMAIN__SOFOOT__1452B3F5] DEFAULT ('') NOT NULL,
    [ORD_TYPE]        CHAR (10)       CONSTRAINT [DF__SOMAIN__ORD_TYPE__1546D82E] DEFAULT ('') NOT NULL,
    [DELIV_AMPM]      CHAR (2)        CONSTRAINT [DF__SOMAIN__DELIV_AM__172F20A0] DEFAULT ('') NOT NULL,
    [BUYER]           CHAR (10)       CONSTRAINT [DF__SOMAIN__BUYER__182344D9] DEFAULT ('') NOT NULL,
    [SOAMOUNT]        NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOAMOUNT__19176912] DEFAULT ((0)) NOT NULL,
    [GLDIVNO]         CHAR (2)        CONSTRAINT [DF__SOMAIN__GLDIVNO__1AFFB184] DEFAULT ('') NOT NULL,
    [IS_RMA]          BIT             CONSTRAINT [DF__SOMAIN__IS_RMA__1BF3D5BD] DEFAULT ((0)) NOT NULL,
    [ORIGINSONO]      CHAR (10)       CONSTRAINT [DF__SOMAIN__ORIGINSO__1CE7F9F6] DEFAULT ('') NOT NULL,
    [INVOICENO]       CHAR (10)       CONSTRAINT [DF__SOMAIN__INVOICEN__1DDC1E2F] DEFAULT ('') NOT NULL,
    [SOAMTDSCT]       NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOAMTDSC__1ED04268] DEFAULT ((0)) NOT NULL,
    [SOEXTEND]        NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOEXTEND__1FC466A1] DEFAULT ((0)) NOT NULL,
    [SOTAX]           NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOTAX__20B88ADA] DEFAULT ((0)) NOT NULL,
    [PRINTPRDT]       BIT             CONSTRAINT [DF__SOMAIN__PRINTPRD__21ACAF13] DEFAULT ((0)) NOT NULL,
    [SOAPPROVAL]      BIT             CONSTRAINT [DF__SOMAIN__SOAPPROV__22A0D34C] DEFAULT ((0)) NOT NULL,
    [SOAPPRVINT]      CHAR (8)        CONSTRAINT [DF__SOMAIN__SOAPPRVI__2394F785] DEFAULT ('') NOT NULL,
    [SOAPPRVDT]       SMALLDATETIME   NULL,
    [SAVEINT]         CHAR (8)        CONSTRAINT [DF__SOMAIN_SaveInt] DEFAULT ('') NOT NULL,
    [SAVEDT]          SMALLDATETIME   NULL,
    [ACKPO_DOC]       CHAR (200)      CONSTRAINT [DF__SOMAIN__ACKPO_DO__257D3FF7] DEFAULT ('') NOT NULL,
    [TERMS]           CHAR (15)       CONSTRAINT [DF__SOMAIN__TERMS__26716430] DEFAULT ('') NOT NULL,
    [SOPTAX]          NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOPTAX__27658869] DEFAULT ((0)) NOT NULL,
    [SOSTAX]          NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOSTAX__2859ACA2] DEFAULT ((0)) NOT NULL,
    [SOCHANGES]       TEXT            CONSTRAINT [DF__SOMAIN__SOCHANGE__294DD0DB] DEFAULT ('') NOT NULL,
    [SOAMOUNTFC]      NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOAMOUNT__334D07B8] DEFAULT ((0)) NOT NULL,
    [SOAMTDSCTFC]     NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOAMTDSC__34412BF1] DEFAULT ((0)) NOT NULL,
    [SOEXTENDFC]      NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOEXTEND__3535502A] DEFAULT ((0)) NOT NULL,
    [SOTAXFC]         NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOTAXFC__36297463] DEFAULT ((0)) NOT NULL,
    [SOPTAXFC]        NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOPTAXFC__371D989C] DEFAULT ((0)) NOT NULL,
    [SOSTAXFC]        NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOSTAXFC__3811BCD5] DEFAULT ((0)) NOT NULL,
    [FCHIST_KEY]      CHAR (10)       CONSTRAINT [DF__SOMAIN__FCHIST_K__3905E10E] DEFAULT ('') NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)       CONSTRAINT [DF__SOMAIN__FCUSED_U__39FA0547] DEFAULT ('') NOT NULL,
    [SOAMOUNTPR]      NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOAMOUNT__62E8A2EF] DEFAULT ((0.00)) NOT NULL,
    [SOAMTDSCTPR]     NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOAMTDSC__63DCC728] DEFAULT ((0.00)) NOT NULL,
    [SOEXTENDPR]      NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOEXTEND__64D0EB61] DEFAULT ((0.00)) NOT NULL,
    [SOTAXPR]         NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOTAXPR__65C50F9A] DEFAULT ((0.00)) NOT NULL,
    [SOPTAXPR]        NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOPTAXPR__66B933D3] DEFAULT ((0.00)) NOT NULL,
    [SOSTAXPR]        NUMERIC (17, 2) CONSTRAINT [DF__SOMAIN__SOSTAXPR__67AD580C] DEFAULT ((0.00)) NOT NULL,
    [PRFcused_Uniq]   CHAR (10)       CONSTRAINT [DF__SOMAIN__PRFcused__68A17C45] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__SOMAIN__FUNCFCUS__6A89C4B7] DEFAULT ('') NOT NULL,
    CONSTRAINT [SOMAIN_PK] PRIMARY KEY CLUSTERED ([SONO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BUYER]
    ON [dbo].[SOMAIN]([BUYER] ASC);


GO
CREATE NONCLUSTERED INDEX [CUSTNO]
    ON [dbo].[SOMAIN]([CUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [ORDDATE]
    ON [dbo].[SOMAIN]([ORDERDATE] ASC);


GO
CREATE NONCLUSTERED INDEX [PONO]
    ON [dbo].[SOMAIN]([PONO] ASC);


GO
CREATE NONCLUSTERED INDEX [SONOINVNO]
    ON [dbo].[SOMAIN]([SONO] ASC, [INVOICENO] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 11/03/15
-- Description:	Insert trigger for SO. When SO is created, need to insert e-mail notification into a queue
-- Modification: 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
-- Modification: 30/01/17 Raviraj P : To verify work flow module with creating new SO
-- =============================================
CREATE TRIGGER [dbo].[Somain_Insert]
   ON  [dbo].[SOMAIN]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    declare @defaultEmail varchar(max)='',@EmailTo varchar(max)=' ',@body varchar(max)=' ', @Triggername char(20) = ' '
	-- Modification: 30/01/17 Raviraj P : To verify work flow module with creating new SO
	--,@totalAmount numeric(11,2),@wfHeaderId char(10),@lnTotalCount int, @lnCnt int,@metaDataName char(25),@groupUserIdCount int, @groupUserIdCnt int,
	--@startValue numeric(11,2),@endValue numeric(11,2),@operatorType char(20),@wfConfigId char(10),@wfRequestId char(10), @isGroup bit , @isAll bit ,@approverGid uniqueidentifier, 
	--@approverUid uniqueidentifier

	--DECLARE @tInserted TABLE(wfConfigId char(10),approverGid uniqueidentifier, approverUid uniqueidentifier, configName char(100), metaDataId char(10),
	--		operatorType char(20), startValue numeric(12,2), endValue numeric(12,2), remindValue numeric(12,2), remindUnit char(10), isAll bit,
	--		wfid char(10), stepNumber int, isGroup bit,operator char(20),nId Int IDENTITY(1,1))

	--Declare @groupUserIds Table(fkuserid uniqueidentifier,rowId Int IDENTITY(1,1))

	BEGIN	
	
	SELECT @TriggerName = 'SO Approvals'
		
	-- Prepare body part for ECO    
	SELECT @body =
	REPLACE(REPLACE ( 
		(
		select '<p>Sales Order No <b>'+LTRIM(RTRIM(I.Sono))+' Acknowledgement'+'</b></p>'
			FROM Inserted I 
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

	--BEGIN    -- Modification: 30/01/17 Raviraj P : To verify work flow module with creating new SO
	--    -- Total sum of order quantity of so
	--	SELECT @totalAmount = Inserted.SOAMOUNT From Inserted
	--	-- Get Workflow header details
	--	SELECT @wfHeaderId = WFid FROM WFHeader WHERE ModuleId=14
	--	-- Get the metadataname
	--	SELECT @metaDataName = MetaDataName FROM MnxWFMetaData where ModuleId=14

	--	INSERT @tInserted 
	--	SELECT wfConfigId,approverGid , approverUid , configName , metaDataId,
	--		operatorType, startValue, endValue, remindValue, remindUnit, isAll,
	--		wfid , stepNumber, isGroup,
	--		REPLACE(LTRIM(RTRIM(operatorType)),LTRIM(RTRIM(@metaDataName)),'') AS operator
	--		FROM WFConfig
	--		WHERE WFConfig.WFid = @wfHeaderId order by StepNumber
	--		SET @lnTotalCount = @@ROWCOUNT;
	--		SET @lnCnt = 0

	--	IF @lnTotalCount <> 0		
	--		BEGIN
	--			WHILE @lnTotalCount > @lnCnt
	--				BEGIN
	--					SET @lnCnt = @lnCnt + 1	
	--					SELECT @startValue = startValue , @endValue=endValue, @operatorType = LTRIM(RTRIM(operator)),@wfConfigId = wfConfigId
	--					FROM @tInserted WHERE nId = @lnCnt;
	--					select @isGroup =isGroup , @isAll = isAll,@approverGid =approverGid,@approverUid=approverUid From @tInserted WHERE nId = @lnCnt;
	--					IF @operatorType = '>'
	--					BEGIN
	--						If  @totalAmount > @startValue
	--						BEGIN
	--							IF @totalAmount > @startValue
	--								BEGIN
	--										set @wfRequestId = dbo.fn_GenerateUniqueNumber()
	--										INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,RequestorId,WFConfigId)
	--										SELECT 14, inserted.SONO,inserted.ORDERDATE,'',@wfRequestId,'00000000-0000-0000-0000-000000000000',@wfConfigId FROM INSERTED 

	--										WAITFOR DELAY '00:00:05'
	--										IF @isGroup = 1 and  @isAll = 1
	--											BEGIN
	--												SET NOCOUNT ON;
	--												INSERT @groupUserIds
	--												SELECT fkuserid FROM aspmnx_groupUsers WHERE fkgroupid = @approverGid;
	--												SET @groupUserIdCount = @@ROWCOUNT;
	--												SET @groupUserIdCnt = 0;
	--												IF @groupUserIdCount <> 0		
	--												 BEGIN
	--													WHILE @groupUserIdCount> @groupUserIdCnt
	--														BEGIN
	--															 SET @groupUserIdCnt = @groupUserIdCnt + 1;
	--															 INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,Approver)
	--															 VALUES('',0, dbo.fn_GenerateUniqueNumber(), @wfRequestId,(SELECT fkuserid from @groupUserIds where rowId = @groupUserIdCnt))
	--														END
	--												END
	--											END
	--										ELSE 
	--											BEGIN 
	--												INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId)
	--												VALUES('',0, dbo.fn_GenerateUniqueNumber(),@wfRequestId)
	--											END
	--								END
	--						END
	--					END
	--					ELSE IF @operatorType = '<'
	--						BEGIN
	--							IF @totalAmount < @startValue
	--								BEGIN
	--										set @wfRequestId = dbo.fn_GenerateUniqueNumber()
	--										INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,RequestorId,WFConfigId)
	--										SELECT 14, inserted.SONO,inserted.ORDERDATE,'',@wfRequestId,'00000000-0000-0000-0000-000000000000',@wfConfigId FROM INSERTED 
	--										WAITFOR DELAY '00:00:05'
	--										IF @isGroup = 1 and  @isAll = 1
	--											BEGIN
	--												SET NOCOUNT ON;
	--												INSERT @groupUserIds
	--												SELECT fkuserid FROM aspmnx_groupUsers WHERE fkgroupid = @approverGid;
	--												SET @groupUserIdCount = @@ROWCOUNT;
	--												SET @groupUserIdCnt = 0;
	--												IF @groupUserIdCount <> 0		
	--												 BEGIN
	--													WHILE @groupUserIdCount> @groupUserIdCnt
	--														BEGIN
	--															 SET @groupUserIdCnt = @groupUserIdCnt + 1;
	--															 INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,Approver)
	--															 VALUES('',0, dbo.fn_GenerateUniqueNumber(), @wfRequestId,(SELECT fkuserid from @groupUserIds where rowId = @groupUserIdCnt))
	--														END
	--												END
	--											END
	--										ELSE 
	--											BEGIN 
	--												INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId)
	--												VALUES('',0, dbo.fn_GenerateUniqueNumber(),@wfRequestId)
	--											END
	--								END
	--						END
	--					ELSE IF @operatorType = '<='
	--						BEGIN
	--							IF @totalAmount <= @startValue
	--								BEGIN
	--										set @wfRequestId = dbo.fn_GenerateUniqueNumber()
	--										INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,RequestorId,WFConfigId)
	--										SELECT 14, inserted.SONO,inserted.ORDERDATE,'',@wfRequestId,'00000000-0000-0000-0000-000000000000',@wfConfigId FROM INSERTED 
	--										WAITFOR DELAY '00:00:05'
	--									IF @isGroup = 1 and  @isAll = 1
	--											BEGIN
	--												SET NOCOUNT ON;
	--												INSERT @groupUserIds
	--												SELECT fkuserid FROM aspmnx_groupUsers WHERE fkgroupid = @approverGid;
	--												SET @groupUserIdCount = @@ROWCOUNT;
	--												SET @groupUserIdCnt = 0;
	--												IF @groupUserIdCount <> 0		
	--												 BEGIN
	--													WHILE @groupUserIdCount> @groupUserIdCnt
	--														BEGIN
	--															 SET @groupUserIdCnt = @groupUserIdCnt + 1;
	--															 INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,Approver)
	--															 VALUES('',0, dbo.fn_GenerateUniqueNumber(), @wfRequestId,(SELECT fkuserid from @groupUserIds where rowId = @groupUserIdCnt))
	--														END
	--												END
	--											END
	--										ELSE 
	--											BEGIN 
	--												INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId)
	--												VALUES('',0, dbo.fn_GenerateUniqueNumber(),@wfRequestId)
	--											END
	--								END
	--						END
	--					ELSE IF @operatorType = '>='
	--						BEGIN
	--							IF @totalAmount >= @startValue
	--								BEGIN
	--										set @wfRequestId = dbo.fn_GenerateUniqueNumber()
	--										INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,RequestorId,WFConfigId)
	--										SELECT 14, inserted.SONO,inserted.ORDERDATE,'',@wfRequestId,'00000000-0000-0000-0000-000000000000',@wfConfigId FROM INSERTED 
	--										WAITFOR DELAY '00:00:05'
										
	--										IF @isGroup = 1 and  @isAll = 1
	--											BEGIN
	--												SET NOCOUNT ON;
	--												INSERT @groupUserIds
	--												SELECT fkuserid FROM aspmnx_groupUsers WHERE fkgroupid = @approverGid;
	--												SET @groupUserIdCount = @@ROWCOUNT;
	--												SET @groupUserIdCnt = 0;
	--												IF @groupUserIdCount <> 0		
	--												 BEGIN
	--													WHILE @groupUserIdCount> @groupUserIdCnt
	--														BEGIN
	--															 SET @groupUserIdCnt = @groupUserIdCnt + 1;
	--															 INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,Approver)
	--															 VALUES('',0, dbo.fn_GenerateUniqueNumber(), @wfRequestId,(SELECT fkuserid from @groupUserIds where rowId = @groupUserIdCnt))
	--														END
	--												END
	--											END
	--										ELSE 
	--											BEGIN 
	--												INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId)
	--												VALUES('',0, dbo.fn_GenerateUniqueNumber(),@wfRequestId)
	--											END
	--								END
	--						END
	--					ELSE IF @operatorType = '='
	--						BEGIN
	--							IF @totalAmount = @startValue
	--								BEGIN
	--										set @wfRequestId = dbo.fn_GenerateUniqueNumber()
	--										INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,RequestorId,WFConfigId)
	--										SELECT 14, inserted.SONO,inserted.ORDERDATE,'',@wfRequestId,'00000000-0000-0000-0000-000000000000',@wfConfigId FROM INSERTED 
	--										WAITFOR DELAY '00:00:05'
	--										IF @isGroup = 1 and  @isAll = 1
	--											BEGIN
	--												SET NOCOUNT ON;
	--												INSERT @groupUserIds
	--												SELECT fkuserid FROM aspmnx_groupUsers WHERE fkgroupid = @approverGid;
	--												SET @groupUserIdCount = @@ROWCOUNT;
	--												SET @groupUserIdCnt = 0;
	--												IF @groupUserIdCount <> 0		
	--												 BEGIN
	--													WHILE @groupUserIdCount> @groupUserIdCnt
	--														BEGIN
	--															 SET @groupUserIdCnt = @groupUserIdCnt + 1;
	--															 INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,Approver)
	--															 VALUES('',0, dbo.fn_GenerateUniqueNumber(), @wfRequestId,(SELECT fkuserid from @groupUserIds where rowId = @groupUserIdCnt))
	--														END
	--												END
	--											END
	--										ELSE 
	--											BEGIN 
	--												INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId)
	--												VALUES('',0, dbo.fn_GenerateUniqueNumber(),@wfRequestId)
	--											END
	--								END
	--						END
	--						ELSE IF @operatorType = 'Between'
	--						BEGIN
	--								IF @totalAmount >= @startValue and @totalAmount <= @endValue
	--									BEGIN
	--											set @wfRequestId = dbo.fn_GenerateUniqueNumber()
	--											INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,RequestorId,WFConfigId)
	--										SELECT 14, inserted.SONO,inserted.ORDERDATE,'',@wfRequestId,'00000000-0000-0000-0000-000000000000',@wfConfigId FROM INSERTED 
	--											WAITFOR DELAY '00:00:05'
	--											IF @isGroup = 1 and  @isAll = 1
	--											BEGIN
	--												SET NOCOUNT ON;
	--												INSERT @groupUserIds
	--												SELECT fkuserid FROM aspmnx_groupUsers WHERE fkgroupid = @approverGid;
	--												SET @groupUserIdCount = @@ROWCOUNT;
	--												SET @groupUserIdCnt = 0;
	--												IF @groupUserIdCount <> 0		
	--												 BEGIN
	--													WHILE @groupUserIdCount> @groupUserIdCnt
	--														BEGIN
	--															 SET @groupUserIdCnt = @groupUserIdCnt + 1;
	--															 INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,Approver)
	--															 VALUES('',0, dbo.fn_GenerateUniqueNumber(), @wfRequestId,(SELECT fkuserid from @groupUserIds where rowId = @groupUserIdCnt))
	--														END
	--												END
	--											END
	--										ELSE 
	--											BEGIN 
	--												INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId)
	--												VALUES('',0, dbo.fn_GenerateUniqueNumber(),@wfRequestId)
	--											END
	--									END
	--						END
	--				END
	--		END -- End of @lnTotalCount <> 0		
	--	END
	END
END
GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 07/24/2012
-- Description:	Delete trigger
-- Modification:
--	08/03/16 VL added to delete Sopricestax records
-- =============================================
CREATE TRIGGER [dbo].[Somain_Delete] 
   ON  [dbo].[SOMAIN] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
		DELETE FROM Sodetail Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM Soprices Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM Soprsrep Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM SoHist Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM SoPHis Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM Due_dts Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM Dudthist Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM Ecso Where Sono IN (SELECT Sono from Deleted)
		DELETE FROM Sopricestax Where Sono IN (SELECT Sono from Deleted)

		UPDATE WOENTRY SET SONO = '', Uniqueln = '' WHERE Sono IN (SELECT Sono from Deleted)
	
	COMMIT
END
	
GO
-- =============================================
-- Author:		David Sharp
-- Create date: 12/12/2012
-- Description:	Notify Subscribers when a SO is acknowledged
-- 01/15/14 YS added new column notificationType varchar(20)
--- coud have 'N' - for notification
---			  'E' - for email
---			  'N,E' - for both
--- open for future methods of notification
-- =============================================
CREATE TRIGGER [dbo].[NOTICE_SOAcknowledge_Update]
   ON  [dbo].[SOMAIN]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    DECLARE @SONO varchar(10)
    SELECT @SONO=i.SONO FROM inserted i INNER JOIN deleted d ON i.SONO=d.SONO WHERE NOT i.POACKDT IS NULL AND d.POACKDT IS NULL
    IF @SONO <>''
    BEGIN
		INSERT INTO dbo.wmTriggerNotification(noticeType,recipientId,[subject],body,triggerId,dateAdded)
		SELECT 'Subscribe',fkUserId,'SO Acknowledged','<p>SO: <b>'+@SONO+'</b> was just acknowledged.</p>',
				'a0943cb2-76ea-4b75-83a0-ed7f9f566cb1',GETDATE()
			FROM wmTriggersActionSubsc 
			WHERE fkActTriggerId='a0943cb2-76ea-4b75-83a0-ed7f9f566cb1' 
			-- 01/15/14 YS added new column notificationType varchar(20)
			and charindex('N',notificationType)<>0
	END
END