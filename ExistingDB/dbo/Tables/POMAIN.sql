CREATE TABLE [dbo].[POMAIN] (
    [PONUM]                    CHAR (15)        CONSTRAINT [DF__POMAIN__PONUM__636F8578] DEFAULT ('') NOT NULL,
    [PODATE]                   SMALLDATETIME    NULL,
    [POSTATUS]                 CHAR (8)         CONSTRAINT [DF__POMAIN__POSTATUS__6463A9B1] DEFAULT ('') NOT NULL,
    [CONUM]                    NUMERIC (3)      CONSTRAINT [DF__POMAIN__CONUM__6557CDEA] DEFAULT ((0)) NOT NULL,
    [VERDATE]                  SMALLDATETIME    NULL,
    [BUYER]                    CHAR (3)         CONSTRAINT [DF__POMAIN__BUYER__664BF223] DEFAULT ('') NOT NULL,
    [APPVNAME]                 CHAR (8)         CONSTRAINT [DF__POMAIN__APPVNAME__6740165C] DEFAULT ('') NOT NULL,
    [FINALNAME]                CHAR (8)         CONSTRAINT [DF__POMAIN__FINALNAM__68343A95] DEFAULT ('') NOT NULL,
    [POTAX]                    NUMERIC (10, 2)  CONSTRAINT [DF__POMAIN__POTAX__69285ECE] DEFAULT ((0)) NOT NULL,
    [POTOTAL]                  NUMERIC (18, 2)  CONSTRAINT [DF__POMAIN__POTOTAL__6A1C8307] DEFAULT ((0)) NOT NULL,
    [TERMS]                    CHAR (15)        CONSTRAINT [DF__POMAIN__TERMS__6B10A740] DEFAULT ('') NOT NULL,
    [PONOTE]                   TEXT             CONSTRAINT [DF__POMAIN__PONOTE__6C04CB79] DEFAULT ('') NOT NULL,
    [POFOOTER]                 TEXT             CONSTRAINT [DF__POMAIN__POFOOTER__6CF8EFB2] DEFAULT ('') NOT NULL,
    [CLOSDDATE]                SMALLDATETIME    NULL,
    [IS_PRINTED]               BIT              CONSTRAINT [DF__POMAIN__IS_PRINT__6DED13EB] DEFAULT ((0)) NOT NULL,
    [C_LINK]                   CHAR (10)        CONSTRAINT [DF__POMAIN__C_LINK__6EE13824] DEFAULT ('') NOT NULL,
    [R_LINK]                   CHAR (10)        CONSTRAINT [DF__POMAIN__R_LINK__6FD55C5D] DEFAULT ('') NOT NULL,
    [I_LINK]                   CHAR (10)        CONSTRAINT [DF__POMAIN__I_LINK__70C98096] DEFAULT ('') NOT NULL,
    [B_LINK]                   CHAR (10)        CONSTRAINT [DF__POMAIN__B_LINK__71BDA4CF] DEFAULT ('') NOT NULL,
    [SHIPCHG]                  NUMERIC (8, 2)   CONSTRAINT [DF__POMAIN__SHIPCHG__72B1C908] DEFAULT ((0)) NOT NULL,
    [IS_SCTAX]                 BIT              CONSTRAINT [DF__POMAIN__IS_SCTAX__73A5ED41] DEFAULT ((0)) NOT NULL,
    [SCTAXPCT]                 NUMERIC (7, 4)   CONSTRAINT [DF__POMAIN__SCTAXPCT__749A117A] DEFAULT ((0)) NOT NULL,
    [CONFNAME]                 CHAR (20)        CONSTRAINT [DF__POMAIN__CONFNAME__758E35B3] DEFAULT ('') NOT NULL,
    [CONFIRMBY]                CHAR (6)         CONSTRAINT [DF__POMAIN__CONFIRMB__768259EC] DEFAULT ('') NOT NULL,
    [SHIPCHARGE]               CHAR (15)        CONSTRAINT [DF__POMAIN__SHIPCHAR__77767E25] DEFAULT ('') NOT NULL,
    [FOB]                      CHAR (15)        CONSTRAINT [DF__POMAIN__FOB__786AA25E] DEFAULT ('') NOT NULL,
    [SHIPVIA]                  CHAR (15)        CONSTRAINT [DF__POMAIN__SHIPVIA__795EC697] DEFAULT ('') NOT NULL,
    [DELTIME]                  CHAR (8)         CONSTRAINT [DF__POMAIN__DELTIME__7A52EAD0] DEFAULT ('') NOT NULL,
    [ISINBATCH]                BIT              CONSTRAINT [DF__POMAIN__ISINBATC__7B470F09] DEFAULT ((0)) NOT NULL,
    [RECONTODT]                NUMERIC (18, 2)  CONSTRAINT [DF__POMAIN__RECONTOD__7C3B3342] DEFAULT ((0)) NOT NULL,
    [ARCSTAT]                  CHAR (8)         CONSTRAINT [DF__POMAIN__ARCSTAT__7D2F577B] DEFAULT ('') NOT NULL,
    [POPRIORITY]               CHAR (10)        CONSTRAINT [DF__POMAIN__POPRIORI__7E237BB4] DEFAULT ('') NOT NULL,
    [POACKNDOC]                CHAR (200)       CONSTRAINT [DF__POMAIN__POACKNDO__7F179FED] DEFAULT ('') NOT NULL,
    [VERINIT]                  CHAR (8)         CONSTRAINT [DF__POMAIN__VERINIT__000BC426] DEFAULT ('') NULL,
    [UNIQSUPNO]                CHAR (10)        CONSTRAINT [DF__POMAIN__UNIQSUPN__00FFE85F] DEFAULT ('') NOT NULL,
    [POCHANGES]                VARCHAR (MAX)    CONSTRAINT [DF__POMAIN__POCHANGE__01F40C98] DEFAULT ('') NOT NULL,
    [LFREIGHTINCLUDE]          BIT              CONSTRAINT [DF__POMAIN__LFREIGHT__02E830D1] DEFAULT ((0)) NOT NULL,
    [POUNIQUE]                 CHAR (10)        CONSTRAINT [DF__POMAIN__POUNIQUE__03DC550A] DEFAULT ('') NOT NULL,
    [CurrChange]               VARCHAR (MAX)    CONSTRAINT [DF_POMAIN_CurrChange] DEFAULT ('') NOT NULL,
    [Acknowledged]             BIT              CONSTRAINT [DF_POMAIN_Acknowledged] DEFAULT ((0)) NOT NULL,
    [RecVer]                   ROWVERSION       NOT NULL,
    [aspnetBuyer]              UNIQUEIDENTIFIER NULL,
    [FcUsed_uniq]              CHAR (10)        CONSTRAINT [DF_POMAIN_fcused_uniq] DEFAULT ('') NOT NULL,
    [Fchist_key]               CHAR (10)        CONSTRAINT [DF_POMAIN_fchist_key] DEFAULT ('') NOT NULL,
    [POTAXFC]                  NUMERIC (10, 2)  CONSTRAINT [DF_POMAIN_POTAXFC] DEFAULT ((0.00)) NOT NULL,
    [pototalFC]                NUMERIC (18, 2)  CONSTRAINT [DF_POMAIN_pototalFC] DEFAULT ((0.00)) NOT NULL,
    [SHIPCHGFC]                NUMERIC (8, 2)   CONSTRAINT [DF_POMAIN_SHIPCHGFC] DEFAULT ((0.0)) NOT NULL,
    [RECONTODTFC]              NUMERIC (18, 2)  CONSTRAINT [DF_POMAIN_RECONTODTFC] DEFAULT ((0.00)) NOT NULL,
    [aspApproveUser]           UNIQUEIDENTIFIER NULL,
    [ApproveD]                 SMALLDATETIME    NULL,
    [aspFinalApproveUser]      UNIQUEIDENTIFIER NULL,
    [FinalApproveD]            SMALLDATETIME    NULL,
    [aspBuyerReadyForApproval] UNIQUEIDENTIFIER NULL,
    [ReadyForApproveD]         SMALLDATETIME    NULL,
    [isNew]                    BIT              CONSTRAINT [DF_POMAIN_isNew] DEFAULT ((0)) NOT NULL,
    [prFcUsed_uniq]            CHAR (10)        CONSTRAINT [DF_POMAIN_prFcUsed_uniq] DEFAULT ('') NOT NULL,
    [funcFcUsed_uniq]          CHAR (10)        CONSTRAINT [DF_POMAIN_funcFcUsed_uniq] DEFAULT ('') NOT NULL,
    [PoTaxPR]                  NUMERIC (10, 2)  CONSTRAINT [DF_POMAIN_PoTaxPR] DEFAULT ((0.00)) NOT NULL,
    [POTOTALPR]                NUMERIC (18, 2)  CONSTRAINT [DF_POMAIN_POTOTALPR] DEFAULT ((0.00)) NOT NULL,
    [SHIPCHGPR]                NUMERIC (8, 2)   CONSTRAINT [DF_POMAIN_SHIPCHGPR] DEFAULT ((0.00)) NOT NULL,
    [RECONTODTPR]              NUMERIC (18, 2)  CONSTRAINT [DF_POMAIN_RECONTODTPR] DEFAULT ((0.00)) NOT NULL,
    [IsApproveProcess]         BIT              CONSTRAINT [DF_POMAIN_IsApproveProcess] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [POMAIN_PK] PRIMARY KEY NONCLUSTERED ([POUNIQUE] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [PONUM]
    ON [dbo].[POMAIN]([PONUM] ASC);


GO
CREATE NONCLUSTERED INDEX [IsInBatch]
    ON [dbo].[POMAIN]([ISINBATCH] ASC);


GO
CREATE NONCLUSTERED INDEX [isprinted]
    ON [dbo].[POMAIN]([IS_PRINTED] ASC);


GO
CREATE NONCLUSTERED INDEX [POCONUM]
    ON [dbo].[POMAIN]([PONUM] ASC, [CONUM] ASC);


GO
CREATE NONCLUSTERED INDEX [PODATE]
    ON [dbo].[POMAIN]([PODATE] ASC);


GO
CREATE NONCLUSTERED INDEX [POSTATUS]
    ON [dbo].[POMAIN]([POSTATUS] ASC);


GO
CREATE NONCLUSTERED INDEX [PoStatus4PoSup]
    ON [dbo].[POMAIN]([POSTATUS] ASC)
    INCLUDE([PONUM], [UNIQSUPNO]);


GO
CREATE NONCLUSTERED INDEX [SUPPONUM]
    ON [dbo].[POMAIN]([UNIQSUPNO] ASC, [PONUM] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/14/2013
-- Description:	Update trigger
-- Modified : 04/23/14 YS added update for verdate
--11\24\14 YS populate new dates for each approval level, when approval was activated, create notification for the next approval
--04/08/15 YS check in wmsetting table for customer modified values
--12/10/2018 Satish B: Upaded POstatus and PONUM of the POITEMS,PITSCHD,POITEMSTAX tables when approved
-- =============================================
CREATE TRIGGER [dbo].[Pomain_Update] 
   ON  [dbo].[POMAIN] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    --DECLARE @cPoChanges varchar(max)
    --DECLARE @cPoChanges TABLE (pounique char(10),Pochanges varchar(max))
    --INSERT INTO @cPoChanges (pounique,pochanges) SELECT pounique,Pochanges from Inserted
    BEGIN TRANSACTION
		
		--SELECT @cPoChanges =ISNULL(Pomain.POCHANGES,' ') FROM Pomain inner join Inserted on Pomain.PONUM=Inserted.Ponum
		UPDATE POMAIN SET 
			VERDATE =GETDATE(),
			POCHANGES=Inserted.CurrChange+
			CASE WHEN NOT Pomain.POCHANGES IS NULL  AND Pomain.PoChanges<>' ' THEN CHAR(13) +pomain.Pochanges ELSE '' END, 
			CurrChange=''
			FROM inserted  
			WHERE Pomain.pounique=Inserted.POUNIQUE
		
		--11/24/14 YS populate new dates for each approval level, when approval was activated, if the chnages were made and aspBuyerreadyforapprove become null - reset all other approvals to null
		UPDATE Pomain SET pomain.ReadyForApproveD=
				CASE WHEN  I.aspBuyerReadyForApproval is null and d.aspBuyerReadyForApproval is not null THEN NULL      --- reset all approval
				 	 WHEN I.aspBuyerReadyForApproval is not null and (I.aspBuyerReadyForApproval<>d.aspBuyerReadyForApproval OR d.aspBuyerReadyForApproval is null) 
					THEN GetDate() ELSE  Pomain.ReadyForApproveD END,
				pomain.ApproveD= 
				CASE WHEN  I.aspBuyerReadyForApproval is null and d.aspBuyerReadyForApproval is not null THEN NULL 
				WHEN I.aspApproveUser is not null and (I.aspApproveUser<>d.aspApproveUser OR d.aspApproveUser is null )
					THEN GetDate() ELSE  Pomain.ApproveD END,
				pomain.aspApproveUser = 
				CASE WHEN I.aspBuyerReadyForApproval is null and d.aspBuyerReadyForApproval is not null THEN NULL ELSE i.aspApproveUser END, 	
				pomain.finalApproveD= 
				CASE WHEN I.aspFinalApproveUser is not null and (I.aspFinalApproveUser<>d.aspFinalApproveUser OR d.aspFinalApproveUser is null )
					THEN GetDate() ELSE  Pomain.finalApproveD END,
				pomain.aspFinalApproveUser =
				case when I.aspBuyerReadyForApproval is null and d.aspBuyerReadyForApproval is not null THEN NULL ELSE i.aspFinalApproveUser END 
				FROM inserted I inner join Deleted D on I.poUnique=D.POUnique 
			WHERE Pomain.pounique=I.POUNIQUE
			
		--11/24/14 YS create notofocation for the next approval level
			if EXISTS (SELECT 1 from Inserted inner join Deleted on Inserted.pounique =Deleted.poUnique 
						where inserted.aspBuyerReadyForApproval is not null and 
						(inserted.aspBuyerReadyForApproval<>deleted.aspBuyerReadyForApproval or deleted.aspBuyerReadyForApproval is null))
			BEGIN
			-- find amount allowed to approve and all users that have that permission
			DECLARE @tapprovaluser TABLE (userid uniqueidentifier,ponum char(15))
			INSERT INTO @tapprovaluser (userid,ponum)
			SELECT userid ,t.ponum
			from aspnet_profile p 
			cross apply (
			SELECT poitems.ponum,
				SUM( CASE  WHEN Poitems.POITTYPE <> 'MRO' and poitems.POITTYPE<>'Services'  THEN poitems.COSTEACH*poitems.ORD_QTY ELSE cast(0.0 as numeric(18,2)) END ) invtAmount, 
				SUM( CASE  WHEN Poitems.POITTYPE = 'MRO' or poitems.POITTYPE='Services'  THEN poitems.COSTEACH*poitems.ORD_QTY ELSE cast(0.0 as numeric(18,2)) END ) noninvtAmount
			FROM poitems inner join inserted i on poitems.ponum=i.ponum 
			GROUP BY poitems.ponum ) t 
			where (t.invtAmount<=p.frstAmtInvtApproved and p.frstAmtInvtApproved<>0) 
			or (t.noninvtAmount<=p.frstAmtNonInvtApproved and p.frstAmtNonInvtApproved<>0.00)	
				
			-- notify that a po is ready for the first approval
				INSERT INTO [dbo].[wmTriggerNotification]
			   ([noticeType]
			   ,[recipientId]
			   ,[dateAdded]
			   ,[triggerId]
			   ,[notificationValues])
				SELECT 'Action', A.UserId,
				getdate(),m.actTriggerid,
				'{''ponum'':'''+i.Ponum+'''}'
				FROM Inserted I inner join Deleted D on I.pounique=D.pounique
				inner join @tapprovaluser A on I.ponum=A.ponum
				CROSS JOIN (SELECT actTriggerid , summaryTemplate,bodyTemplate from  [MnxTriggersAction] where triggerName='Purchase Order is ready for first approval') M
				where (i.aspBuyerReadyForApproval<>D.aspBuyerReadyForApproval or d.aspBuyerReadyForApproval is null) and i.aspBuyerReadyForApproval is not null
		 END  ---- if EXISTS (SELECT 1 from Inserted inner join Deleted on Inserted.pounique =Deleted.poUnique where inserted.aspBuyerReadyForApproval is not null and ...
						
		-- check if first approval was updated and the second approval is required
		--04/08/15 YS check in wmsetting table for customer modified values
		--if EXISTS (SELECT 1 FROM [MnxSettingsManagement] where moduleid=11 and settingname='approvalCount' and settingValue='2')
		if EXISTS (SELECT 1 
				FROM [MnxSettingsManagement] S LEFT OUTER JOIN WmSettingsManagement W ON S.settingid=w.settingid
				where s.moduleid=11 and s.settingname='approvalCount' and coalesce(s.settingValue,w.settingValue)='2')
		and 
		EXISTS (SELECT 1 from Inserted inner join Deleted on Inserted.pounique =Deleted.poUnique 
						where inserted.aspApproveUser is not null and 
						(inserted.aspApproveUser<>deleted.aspApproveUser or deleted.aspApproveUser is null))
			BEGIN
			-- find amount allowed to approve and all users that have that permission
			DECLARE @tFinalapprovaluser TABLE (userid uniqueidentifier,ponum char(15))
			INSERT INTO @tapprovaluser (userid,ponum)
			SELECT userid ,t.ponum
			from aspnet_profile p 
			cross apply (
			SELECT poitems.ponum,
				SUM( CASE  WHEN Poitems.POITTYPE <> 'MRO' and poitems.POITTYPE<>'Services'  THEN poitems.COSTEACH*poitems.ORD_QTY ELSE cast(0.0 as numeric(18,2)) END ) invtAmount, 
				SUM( CASE  WHEN Poitems.POITTYPE = 'MRO' or poitems.POITTYPE='Services'  THEN poitems.COSTEACH*poitems.ORD_QTY ELSE cast(0.0 as numeric(18,2)) END ) noninvtAmount
			FROM poitems inner join inserted i on poitems.ponum=i.ponum 
			GROUP BY poitems.ponum ) t 
			where (t.invtAmount<=p.finalAmtInvtApproved and p.finalAmtInvtApproved<>0) 
			or (t.noninvtAmount<=p.finalAmtNonInvtApproved and p.finalAmtNonInvtApproved<>0.00)	
				-- notify that a po is ready for the first approval
				INSERT INTO [dbo].[wmTriggerNotification]
			   ([noticeType]
			   ,[recipientId]
			   ,[dateAdded]
			   ,[triggerId]
			   ,[notificationValues])
				SELECT 'Action', A.UserId,
				getdate(),m.actTriggerid,
				'{''ponum'':'''+i.Ponum+'''}'
				FROM Inserted I inner join Deleted D on I.pounique=D.pounique
				inner join @tFinalapprovaluser A on i.ponum=A.ponum
				CROSS JOIN (SELECT actTriggerid , summaryTemplate,bodyTemplate from  [MnxTriggersAction] where triggerName='Purchase Order is ready for final approval') M
				where i.aspApproveUser is not null and 
						(i.aspApproveUser<>d.aspApproveUser OR d.aspApproveUser is null)
		 END  ---- EXISTS (SELECT 1 FROM [MnxSettingsManagement] where moduleid=11 and settingname='approvalCount' and settingValue='2') and ... 
	   --12/10/2018 Satish B: Added for when upade POMAIN table then POITEMS,PITSCHD,POITEMSTAX tax should update				
	   IF EXISTS (SELECT 1 FROM deleted WHERE SUBSTRING(PONUM,1,1) = 'T')
	       BEGIN 
		        
				DECLARE @poNum CHAR(15)  ,@existtingPO CHAR (15)
				SELECT @poNum =PONUM FROM inserted
				SELECT @existtingPO =PONUM FROM deleted

		        UPDATE POITEMS SET PONUM = @poNum WHERE PONUM = @existtingPO

				UPDATE POITSCHD set PONUM =  @poNum  where PONUM = @existtingPO

				update POITEMSTAX set PONUM =  @poNum  where PONUM = @existtingPO
				
		   END

    COMMIT 

END




GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/13/2010
-- Description:	Delete Trigger to modify PoChages
-- =============================================
CREATE TRIGGER [dbo].[PoMain_Delete] 
   ON  dbo.POMAIN
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
      
    SELECT Ponum FROM DELETED
	-- record was deleted, not normal for the PO module.
	IF @@ROWCOUNT<>0
	BEGIN
	-- removed record from pomain. Remove poitems and poitschd records
	BEGIN TRANSACTION
	-- this delete will trigger delete trigger in poitems if  any
	DELETE FROM Poitems WHERE Ponum in (SELECT Ponum FROM Deleted)
	--I want to delete poitschd records here if Pomain record was removed.
	-- otherwise will remove the records inside Manex front end
	DELETE FROM Poitschd WHERE Ponum in (SELECT Ponum FROM Deleted)
	COMMIT
	END
	
END