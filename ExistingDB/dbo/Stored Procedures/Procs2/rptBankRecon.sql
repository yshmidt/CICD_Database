
	-- =============================================
	-- Author:			Debbie
	-- Create date:		08/29/2013
	-- Description:		Compiles the details for the Bank Reconciliation reports
	-- Used On:			In VFP we used to have bkrecon, bkrecosd and bkrecosc . . . this procedure has been created to have all of the information on one report bkrecon.mrt
	-- Modifications:	11/19/2013 DRP:  Added RecordReconDate as reference.  So we can see when the individual record was reconciled on . 
	--									 added @ldReconDate and changed the filder :  and (reconcileDate is null or datediff(day,reconcileDate,@ldate) < 0 )) to and (reconcileDate is null or datediff(day,reconcileDate,@ldReconDate) < 0 ))
	--					12/09/2013 DRP:  needed to add Group by to the Deposit section instead of pulling all of the individual invoices from the deposit fwd. 
	--					12/16/2013 DRP:  Added 11 fields that will be used to populate with Book values for the report.  These Book Values can change from report to report especially if the users backdate records.
	--					02/13/2014 DRP:  Had to change the date filter on all of the Prior book values  also then needed to change the date filter on all of the Book Values.
	--					03/13/2014 DRP:  needed to change the code for Outstanding Checks on how it gathered records for Voided checks.  Now if a check is original cut in Jan but later voided a couple months later in March
	--									 The Jan and Feb Statement will still show the check as outstanding, but it will then no longer be included in the outstanding Check within March when it was voided. 
	--					03/28/2014 DRP:  I had to add [and apchkmst.CHECKAMT <> 0.00] to where I gather outstanding checks so that if the original Check was for 0.00 and has a status of 'Void' 
	--									 that it will properly not be included in the results. 
	--					04/25/2014 DRP:  To clear up possible confusion added VoidDate field and then included the Void Date into the Payee as extra reference 
	--									 so the users can easily see that the Check has been voided and when.  This is when it will fall off of the outstanding Check listing
	--					01/10/2017 DRP:  On 9/24/15 Vicky had added an extra field "AtdUniq_key" to the <<GetAllGlReleased>> procedure that I happen to be using below.  when she added that field it broke this procedure.  I have added the new field to the @GetAllGlReleased declared table below. 
-- 01/29/18 VL Changed the length of Bk_Acct_No from char(15) to char(50)
-- 02/26/19 VL Changed Banks.AcctTitle from char(25) to char(50), Banks.Bank from char(35) to char(50)
-- 04/11/19 YS/VL added BKRECON.STMTDATE IS NOT NULL criteria, so if the record didn't have associated Bkrecon record, it won't show, sometimes we fix data by assigning a value in reconuniq field, but no Bkrecon record is created
-- 07/18/19 VL found the code added on 04/11/19 would remove those not cleared records that have not have Bkrecon record yet.  Added ApchkMst.Reconuniq='' to include those not cleared records but filter out those records marked as reconciled but didn't really reconcilied, #5520
	-- =============================================
	CREATE PROCEDURE  [dbo].[rptBankRecon]
	  --declare

	  @lcReconUniq char(10) = ''	  --This will be the Unique Bank reconciliation value
	 ,@UserId uniqueidentifier = null  -- userid for security


	as
	Begin
	-- 02/26/19 VL Changed Banks.AcctTitle from char(25) to char(50), Banks.Bank from char(35) to char(50)
	declare	@results table	(ReconUniq char(10),Bank char(50),Bk_Acct_No char(50),AcctTitle char(50),StmtDate smalldatetime,ReconDate smalldatetime,Bk_uniq char(10)
							,LastStmBal numeric (12,2),StmtTotalDep numeric(12,2),StmtWithDrawl numeric(12,2),IntEarned numeric(12,2),SvcChgs numeric(12,2)
							,DepCorr numeric(12,2),WithDrCorr numeric(12,2),RecordType char(25),[Date] smalldatetime,Reference char(20),Amount numeric(12,2)
							,ReasonPayee varchar(max),Cleared bit,/*04/25/2014 DRP: ADDED VoidDate*/ VoidDate date ,LastStmtDt smalldatetime,RecordReconDate Smalldatetime
							,StmtRecReconOn char(10),LastPostBookTotal numeric (15,2),LastNotPostBookTotal numeric(15,2),DepPost numeric(15,2),DepNotPost numeric (15,2)
							,ChkPost numeric(15,2),ChkNotPost numeric(15,2),JeDebitPost numeric(15,2),JeDebitNotPost numeric (15,2),JeCreditPost numeric (15,2)
							,JeCreditNotPost numeric (15,2),NsfPost numeric(15,2),NsfNotPost numeric (15,2),PostBookTotal numeric (15,2),NotPostBookTotal numeric(15,2))
							
	declare @LastBook as table (TotDep numeric (15,2),CheckAmt numeric (15,2),JeDebit numeric(15,2),JeCredit numeric (15,2))

	Declare @GetAllGlReleased table (GLRELUNIQUE char(10),RANKN bit,TrGroupIdNumber numeric (10,0),TRANS_DT smalldatetime,PERIOD numeric (3),FY char (4),GL_NBR char (13)
									,GL_DESCR char(30),DEBIT numeric (14,2),CREDIT numeric (14,2),SAVEINIT char(8),CIDENTIFIER char (30),LPOSTEDTOGL bit,CDRILL varchar(50)
									,TransactionType varchar(50),SourceTable varchar(25),SourceSubTable varchar(25),cSubIdentifier char(30),cSubDrill varchar(50)
									,fk_fydtluniq uniqueidentifier,GroupIdNumber bit,lSelect bit,DisplayValue varchar(50)
									,Atduniq_key char(10))	--01/10/17 DRP:  added the atduniq_key to match the GetAllGlRelease changes

	insert into @GetAllGlReleased exec dbo.GetAllGlReleased
	--select * from @getallglreleased


	--Declare the below values to be used later for the Outstanding records. 
	declare	@lcbk_Uniq char(10)=NULL						--Unique Bank Id
			,@ldStmtDate smalldatetime =NULL				--Date of the Statement based on the @lcReconUniq declared above
			,@gl_nbr char(13)=' '							--Bank Gl_nbr that will be used for Outstanding Journal Entries.
			,@ldReconDate smalldatetime = null				-- Date of Reconcile date based on the @lcReconUniq declared above --11/19/2013 DRP  ADDED
			,@ldLastStmtDate smalldatetime = null			--Date of the statement before the selected 
--12/16/2013 ADDED THESE BELOW TO GATHER THE BOOK VALUES . . keep in mind these are subject to change at anytime so if the users run the report on different days they may not see the same results.  Especially if they are in the habit of back dating transactions
			,@ldLastPostBookTotal numeric(15,2) = 0.00		--Would be all transactions within the system that hit the GL # for the Bank before the LastStmtDate
			,@ldLastNotPostBookTotal numeric(15,2) = 0.00	--would be all transactions within the system that where created but not posted for the GL # Before the LastStmtDate
--12/16/2013 BOOK VALUES PRIOR TO THIS STATEMENT
			,@ldPriorDepPost numeric(15,2) = 0.00
			,@ldPriorDepNotPost numeric(15,2) = 0.00
			,@ldPriorChkPost numeric (15,2) = 0.00
			,@ldPriorChkNotPost numeric (15,2) = 0.00
			,@ldPriorJeDebitPost numeric (15,2) = 0.00
			,@ldPriorJeDebitNotPost numeric (15,2) = 0.00
			,@ldPriorJeCreditPost numeric (15,2) = 0.00
			,@ldPriorJeCreditNotPost numeric(15,2) = 0.00
			,@ldPriorNsfPost numeric(15,2) = 0.00
			,@ldPriorNsfNotPost numeric (15,2) = 0.00 
--12/16/2013 BOOK VALUES FOR THIS STATEMENT
			,@ldDepPost numeric(15,2) = 0.00			--Would be all Deposits created and Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldDepNotPost numeric (15,2) = 0.00		--Would be all Deposits created but not Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldChkPost numeric(15,2) = 0.00			--Would be all Checks created and Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldChkNotPost numeric (15,2) = 0.00		--Would be all Checks Created but Not Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldJeDebitPost numeric(15,2) = 0.00		--Would be all Journal Entry Debits created and Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldJeDebitNotPost Numeric (15,2) = 0.00	--Would be all Journal Entry Debits created but NOT Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldJeCreditPost numeric(15,2) = 0.00		--Would be all Journal Entry Credits created and Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldJeCreditNotPost numeric (15,2) = 0.00	--Would be all Journal Entry Credits created but NOT Posted to the GL between LastStmtDate and CurrentStmtDate
			,@ldNsfPost numeric(15,2) = 0.00			--would be all Nsf created and posted to GL beween LasStmtDate and CurrentStmtDate
			,@ldNsfNotPost numeric (15,2) = 0.00		--would be all Nsf created but not posted to the GL Between LastStmtDate and CurrentStmtDate	

		--*****	
		--BEGIN: Populating BankRecon Statement Header Info for declared values above
			select	@lcbk_Uniq = bkrecon.Bk_uniq
					,@ldStmtDate = bkrecon.STMTDATE
					,@gl_nbr = banks.GL_NBR
					,@ldReconDate = RECONDATE --11/19/2013 DRP:  ADDED
					,@ldLastStmtDate = bkrecon.laststmtdt
			from	bkrecon inner join BANKS on bkrecon.BK_UNIQ = banks.BK_UNIQ where @lcReconUniq = reconuniq 
		--END: Populating BankRecon Statement Header Info for Declared Values above
		--*****

--12/16/2013
	--BEGIN: PRIOR BOOK VALUES
		--BEGIN: Deposits
			--will update the total for Deposits created but not Posted to GL, prior to select Statement date 
			select	@ldPriorDepNotPost = SUM(tot_dep) 
			from	DEPOSITS 
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)>0 
					and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)>=0 
					and dep_no in (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where Transactiontype='DEP' and Sourcetable='Deposits' and GL_NBR = @gl_nbr)
			--will update the total for Deposits created and Posted to GL, prior to select Statement date 
			select	@ldPriorDepPost = SUM(tot_dep)
			from	DEPOSITS 
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)>0 
					and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)>=0 
					and  is_reL_gl=1 
					and dep_no not in (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where Transactiontype='DEP' and Sourcetable='Deposits' and GL_NBR = @gl_nbr )
		--END: Deposits
		--*****		
		--BEGIN:  Checks
			--will update the total for Checks created but not posted to GL, prior to select Statement date
			select	@ldPriorChkNotPost = SUM(checkamt) 
			from	APCHKMST
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)>0 
					and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)>=0 
					and APCHK_UNIQ IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'CHECKS' AND SourceTable = 'APCHKMST' AND GL_NBR = @gl_nbr)
			--will update the total for Checks created and Posted to the GL, prior to select Statement date
			select	@ldPriorChkPost = SUM(checkamt) 
			from	APCHKMST
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)>0
					and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)>=0
					and IS_REL_GL = 1
					and APCHK_UNIQ not IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'CHECKS' AND SourceTable = 'APCHKMST' AND GL_NBR = @gl_nbr)
		--END:  Checks
		--*****
		--BEGIN:  JOURNAL ENTRY DEBITS
			--will update the total for Journal Entry Debits created but not posted to GL, prior to select Statement date
			select	@ldPriorJeDebitNotPost = SUM(gljedeto.DEBIT) 
			from	GLJEHDRO inner join GLJEDETO on  GLJEHDRO.JEOHKEY =  GLJEDETO.FKJEOH
			where	gljedeto.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)>0 
					and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)>=0 
					and STATUS = 'APPROVED'
			--will update the total for Journal Entry Debits Created and Posted to the GL, prior to select Statement date   
			select	@ldPriorJeDebitPost = SUM(gljedet.DEBIT) 
			from	GLJEHDR inner join GLJEDET on  GLJEHDR.UNIQJEHEAD =  GLJEDET.UNIQJEHEAD
			where	gljedet.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)>0 
					and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)>=0 
					and STATUS = 'POSTED'			
		--END:  JOURNAL ENTRY DEBITS
		--*****
		--BEGIN:  JOURNAL ENTRY CREDITS
			--will update total for Journal Entry Credits created but not posted to GL, prior to select Statement date
			select	@ldPriorJeCreditNotPost = SUM(gljedeto.CREDIT) 
			from	GLJEHDRO inner join GLJEDETO on  GLJEHDRO.JEOHKEY =  GLJEDETO.FKJEOH
			where	gljedeto.GL_NBR = @gl_nbr
--02/13/2014 		and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)>0
					and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)>=0
					and STATUS = 'APPROVED'
			--will update total for Journal Entry Credits created and posted to the GL, prior to select Statement date
			select	@ldPriorJeCreditPost = SUM(gljedet.CREDIT) 
			from	GLJEHDR inner join GLJEDET on  GLJEHDR.UNIQJEHEAD =  GLJEDET.UNIQJEHEAD
			where	gljedet.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)>0 
					and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)>=0 
					and STATUS = 'POSTED'	
		--END:  JOURNAL ENTRY CREDITS
		--*****
		--BEGIN:  NSF
			--will update total for NSF created but not posted to GL, prior to select Statement date
			select	@ldPriorNsfNotPost = SUM(REC_AMOUNT) 
			from	ARRETCK 
			where   
--02/13/2014		DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)>0
					DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)>=0
					and ARRETCK.GL_NBR =@gl_nbr
					and UNIQRETNO IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'NSF' AND SourceTable = 'ArretCk' AND GL_NBR = @gl_nbr)
			--will update total for NSF created and posted to the GL, prior to select Statement date	
			select	@ldPriorNsfPost = SUM(REC_AMOUNT) 
			from	ARRETCK 
			where	ARRETCK.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)>0 
					and DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)>=0 
					and IS_REL_GL = 1
					and UNIQRETNO not IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'NSF' AND SourceTable = 'ArretCk' AND GL_NBR = @gl_nbr)
		--END: NSF
	--END:  PRIOR BOOK VALUES

--12/16/2013 ADDED ALL OF THESE SECTIONS BELOW TO POPULATE THE BOOK VALUES. 
-- Note:  that the Book Values are taken from the individual records date . . . if the user is in the practice of changing transaction dates upon posting,
-- then there is a chance that the book Values on this report will not match the GL acct # Balance. 

		--BEGIN: calculating Book values for Deposits
			--will update the total for Deposits created but not Posted to GL, between Last Statement and the date of selected statement 
			select	@ldDepNotPost = SUM(tot_dep) 
			from	DEPOSITS 
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,deposits.DATE,@ldStmtDate)>=0
					and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,deposits.DATE,@ldStmtDate)>=0
					and (dep_no in (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where Transactiontype='DEP' and Sourcetable='Deposits' and GL_NBR = @gl_nbr) or IS_REL_GL = 0)
			--will update the total for Deposits created and Posted to GL, between Last Statement and the date of selected statement 
			select	@ldDepPost = SUM(tot_dep)
			from	DEPOSITS 
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,deposits.DATE,@ldStmtDate)>=0
					and DATEDIFF(Day,deposits.dATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,deposits.DATE,@ldStmtDate)>=0
					and  is_reL_gl=1 
					and dep_no not in (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where Transactiontype='DEP' and Sourcetable='Deposits' and GL_NBR = @gl_nbr )
		--END: Calculating Book Values for Deposits
		--*****
		--BEGIN:  calculating Book Values for Checks
			--will update the total for Checks created but not posted to GL, between Last Statement and the date of the selected statement
			select	@ldChkNotPost = SUM(checkamt) 
			from	APCHKMST
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,APCHKMST.CHECKDATE,@ldStmtDate)>=0
					and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,APCHKMST.CHECKDATE,@ldStmtDate)>=0
					and (APCHK_UNIQ IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'CHECKS' AND SourceTable = 'APCHKMST' AND GL_NBR = @gl_nbr) or IS_REL_GL = 0)
			--will update the total for Checks created and Posted to the GL, between Last Statement and the date of selected statement
			select	@ldChkPost = SUM(checkamt) 
			from	APCHKMST
			where	BK_UNIQ = @lcbk_Uniq
--02/13/2014		and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,APCHKMST.CHECKDATE,@ldStmtDate)>=0
					and DATEDIFF(Day,APCHKMST.CHECKDATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,APCHKMST.CHECKDATE,@ldStmtDate)>=0
					and IS_REL_GL = 1
					and APCHK_UNIQ not IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'CHECKS' AND SourceTable = 'APCHKMST' AND GL_NBR = @gl_nbr)
		--END:  calculating Book Values for Checks
		--*****
		--BEGIN:  CALCULATING BOOK VALUES FOR JOURNAL ENTRY DEBITS
			--will update the total for Journal Entry Debits created but not posted to GL, between Last Statement and the date of the selected statement
			select	@ldJeDebitNotPost = SUM(gljedeto.DEBIT) 
			from	GLJEHDRO inner join GLJEDETO on  GLJEHDRO.JEOHKEY =  GLJEDETO.FKJEOH
			where	gljedeto.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldStmtDate)>=0
					and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldStmtDate)>=0
					and STATUS = 'APPROVED'
			--will update the total for Journal Entry Debits Created and Posted to the GL, between Last Statement and the date of the selected statement   
			select	@ldJeDebitPost = SUM(gljedet.DEBIT) 
			from	GLJEHDR inner join GLJEDET on  GLJEHDR.UNIQJEHEAD =  GLJEDET.UNIQJEHEAD
			where	gljedet.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldStmtDate)>=0
					and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldStmtDate)>=0
					and STATUS = 'POSTED'			
		--END:  CALCULATING BOOK VALUES FOR JOURNAL ENTRY DEBITS
		--*****
		--BEGIN:  CALCULATING BOOK VALUES FOR JOURNAL ENTRY CREDITS
			--will update total for Journal Entry Credits created but not posted to GL, between Last Statement and the date of selected statement
			select	@ldJeCreditNotPost = SUM(gljedeto.CREDIT) 
			from	GLJEHDRO inner join GLJEDETO on  GLJEHDRO.JEOHKEY =  GLJEDETO.FKJEOH
			where	gljedeto.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldStmtDate)>=0
					and DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,GLJEHDRO.TRANSDATE,@ldStmtDate)>=0
					and STATUS = 'APPROVED'
			--will update total for Journal Entry Credits created and posted to the GL, between Last Statement and the date of selected statement
			select	@ldJeCreditPost = SUM(gljedet.CREDIT) 
			from	GLJEHDR inner join GLJEDET on  GLJEHDR.UNIQJEHEAD =  GLJEDET.UNIQJEHEAD
			where	gljedet.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldStmtDate)>=0
					and DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,GLJEHDR.TRANSDATE,@ldStmtDate)>=0
					and STATUS = 'POSTED'	
		--END:  CALCULATING BOOK VALUES FOR JOURNAL ENTRY CREDITS
		--*****
		--BEGIN: CALCULATING BOOK VALUES FOR NSF
			--will update total for NSF created but not posted to GL, between Last Statment and the date of selected statement
			select	@ldNsfNotPost = SUM(REC_AMOUNT) 
			from	ARRETCK 
			where   
--02/13/2014		DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,arretck.RET_DATE,@ldStmtDate)>=0
					DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,arretck.RET_DATE,@ldStmtDate)>=0
					and ARRETCK.GL_NBR =@gl_nbr
					and (UNIQRETNO IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'NSF' AND SourceTable = 'ArretCk' AND GL_NBR = @gl_nbr) or IS_REL_GL = 0)
			--will update total for NSF created and posted to the GL, between Last Statement and the date of Selected statement		
			select	@ldNsfPost = SUM(REC_AMOUNT) 
			from	ARRETCK 
			where	ARRETCK.GL_NBR = @gl_nbr
--02/13/2014		and DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)<=0 AND DATEDIFF(Day,arretck.RET_DATE,@ldStmtDate)>=0
					and DATEDIFF(Day,arretck.RET_DATE,@ldLastStmtDate)<0 AND DATEDIFF(Day,arretck.RET_DATE,@ldStmtDate)>=0
					and IS_REL_GL = 1
					and UNIQRETNO not IN (SELECT RTRIM(cSubdrill) from @GetAllGlReleased where TransactionType = 'NSF' AND SourceTable = 'ArretCk' AND GL_NBR = @gl_nbr)
		--END: CALCULATING BOOK VALUES FOR NSF


	--********************
	
	--**********
	--DEPOSITS
	--**********	
	--Gathers Cleared Deposits for selected statement
			--ClearDep Begin
			insert into @results
			select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,INTEARNED,SVCCHGS,DEPCORR,WITHDRCORR
					,CAST('Deposits' as CHAR(25)) as RecordType,isnull(z.DATE,''),isnull(REC_ADVICE,'') as Reference,isnull(z.REC_AMOUNT,0.00) as Amount,CAST ('' as varchar(max)) as ReasonPayee
					,CAST (1 as bit) as Cleared,/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as date) as voiddate,bkrecon.LASTSTMTDT,z.reconciledate,z.reconuniq
					,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
					,CAST (0.00 as numeric(15,2)) as DepPost,CAST (0.00 as numeric(15,2)) as DepNotPost
					,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
					,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
					,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
					,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
					,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal

			from	bkrecon
					inner join BANKS on banks.BK_UNIQ = bkrecon.BK_UNIQ
					left outer join (select	deposits.bk_uniq,[Date],sum(Arcredit.REC_AMOUNT) as Rec_Amount, Deposits.Dep_No 
											,Arcredit.REC_ADVICE,CASE WHEN ARCREDIT.ReconcileStatus=' ' THEN CAST(0 as bit)WHEN ARCREDIT.ReconcileStatus='C' THEN CAST(1 as bit) END as Cleared
											,reconciledate,arcredit.reconuniq
									FROM	Deposits 
											INNER JOIN ARCREDIT ON Deposits.DEP_NO =Arcredit.DEP_NO 
									where	(Deposits.Bk_Uniq = @lcbk_Uniq )
											AND DATEDIFF(day,[Date],@ldStmtDate) >=0
											AND ARCREDIT.reconuniq = @lcReconUniq
									group by deposits.bk_uniq,[Date], Deposits.Dep_No 
											,Arcredit.REC_ADVICE,CASE WHEN ARCREDIT.ReconcileStatus=' ' THEN CAST(0 as bit)WHEN ARCREDIT.ReconcileStatus='C' THEN CAST(1 as bit) END,reconciledate
											,arcredit.reconuniq
									) as z on bkrecon.BK_UNIQ = z.BK_UNIQ 		
			where	@lcReconUniq = bkrecon.reconuniq
		--ClearDep End	
	--Gathers Outstanding Deposits
		--OsDep Begin
		insert into @results
			select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,INTEARNED,SVCCHGS,DEPCORR,WITHDRCORR
					,CAST('Deposits' as CHAR(25)) as RecordType,isnull(z.DATE,''),isnull(REC_ADVICE,'') as Reference,isnull(z.REC_AMOUNT,0.00) as Amount,CAST ('' as varchar(max)) as ReasonPayee
					,CAST(0 as bit) as Cleared,/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as smalldatetime) as voiddate,bkrecon.LASTSTMTDT,z.reconciledate,z.reconuniq
					,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
					,CAST (0.00 as numeric(15,2)) as DepPost,CAST (0.00 as numeric(15,2)) as DepNotPost
					,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
					,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
					,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
					,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
					,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal

			from	bkrecon
					inner join BANKS on banks.BK_UNIQ = bkrecon.BK_UNIQ
					left outer join (select	deposits.bk_uniq,[Date],sum(Arcredit.REC_AMOUNT) as Rec_Amount, Deposits.Dep_No 
											,Arcredit.REC_ADVICE,CASE WHEN ARCREDIT.ReconcileStatus=' ' THEN CAST(0 as bit)WHEN ARCREDIT.ReconcileStatus='C' THEN CAST(1 as bit) END as Cleared
											,reconciledate,arcredit.reconuniq
									FROM	Deposits 
											INNER JOIN ARCREDIT ON Deposits.DEP_NO =Arcredit.DEP_NO 
											LEFT OUTER JOIN BKRECON ON ARCREDIT.reconuniq = BKRECON.RECONUNIQ 
									where	(Deposits.Bk_Uniq = @lcbk_Uniq )
											AND DATEDIFF(day,[Date],@ldStmtDate) >=0
											AND ARCREDIT.reconuniq <> @lcReconUniq
											-- 07/18/19 VL found the code added on 04/11/19 would remove those not cleared records that have not have Bkrecon record yet.  Added ApchkMst.Reconuniq='' to include those not cleared records but filter out those records marked as reconciled but didn't really reconcilied, #5520
											-- 04/11/19 YS/VL added BKRECON.STMTDATE IS NOT NULL criteria, so if the record didn't have associated Bkrecon record, it won't show, sometimes we fix data by assigning a value in reconuniq field, but no Bkrecon record is created
											--And ((reconciledate IS NULL and BKRECON.STMTDATE IS NOT NULL) OR datediff(day,@ldStmtDate , STMTDATE )>0)
											And ((reconciledate IS NULL AND ARCREDIT.reconuniq='') OR datediff(day,@ldStmtDate , STMTDATE )>0)
									group by deposits.bk_uniq,[Date], Deposits.Dep_No 
											,Arcredit.REC_ADVICE,CASE WHEN ARCREDIT.ReconcileStatus=' ' THEN CAST(0 as bit)WHEN ARCREDIT.ReconcileStatus='C' THEN CAST(1 as bit) END,reconciledate
											,arcredit.reconuniq
									) as z on bkrecon.BK_UNIQ = z.BK_UNIQ 		
			where	@lcReconUniq = bkrecon.reconuniq
		--OsDep End
		
	--**********	
	--**********
	--CHECKS
	--**********
	--Gathers Cleared Checks for selected statement
		--ClearCks Begin
			insert into @results
 			select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
					,CAST('Checks' as CHAR(25)) as RecordTyp,isnull(x.CHECKDATE,'') as [Date],isnull(x.CHECKNO,'') as Reference,isnull(x.CHECKAMT,0.00) as Amount,isnull(x.ShipTo,'') as ReasonPayee
					,CAST(1 as bit) as Cleared,/*04/25/2014 DRP: ADDED VoidDate*/ x.voiddate,bkrecon.LASTSTMTDT,x.ReconcileDate,isnull(x.RECONUNIQ,'')
					,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
					,CAST (0.00 as numeric(15,2)) as LastBookDeposit,CAST (0.00 as numeric(15,2)) as DepNotPost
					,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
					,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
					,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
					,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
					,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
			from	bkrecon	
					inner join BANKS on banks.BK_UNIQ = bkrecon.BK_UNIQ
					LEFT OUTER JOIN (SELECT	CAST(ISNULL(ShipBill.ShipTo,' ') as CHAR(35)) as ShipTo,CheckDate,CheckNo,CheckAmt,apchkmst.BK_UNIQ  
											,ApChk_Uniq,Reconcilestatus,ReconcileDate,APCHKMST.ReconUniq
											,CASE WHEN Reconcilestatus=' ' THEN cast(0 as bit)WHEN Reconcilestatus='C' THEN cast(1 as bit) END AS Cleared
											,VOIDDATE
									 FROM	ApChkMst 
											LEFT OUTER JOIN  ShipBill ON ApChkMst.R_Link = ShipBill.LinkAdd 
											LEFT OUTER JOIN BKRECON ON APCHKMST.reconuniq = BKRECON.RECONUNIQ 																			 
									 WHERE	ApChkMst.BK_Uniq = @lcBk_Uniq   
											AND CHARINDEX('Void',ApChkMst.Status)=0  
											AND DATEDIFF(day,ApChkMst.CheckDate,@ldStmtDate) >=0
											AND APCHKMST.reconuniq = @lcReconUniq) AS X ON BKRECON.BK_UNIQ = X.BK_UNIQ
			where	@lcReconUniq = bkrecon.RECONUNIQ
			order by ReconcileDate	
		--ClearCks End
			
	--Gathers Oustanding Checks
		--OsCks Begin
		insert into @results
 			select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
					,CAST('Checks' as CHAR(25)) as RecordTyp,isnull(x.CHECKDATE,'') as [Date],isnull(x.CHECKNO,'') as Reference,isnull(x.CHECKAMT,0.00) as Amount
/*04/25/2014 DRP: Removed this and replaced with the following*/--,isnull(x.ShipTo,'') as ReasonPayee					
					,case when x.voidDate IS null then ltrim(x.ShipTo) 
						else (rtrim(LTRIM(x.shipto)) + '  *VoidDt: ' + CAST((MONTH(x.voiddate))AS CHAR(2))+'/'+CAST(DAY(X.VOIDDATE)AS CHAR(2))+'/'+CAST(YEAR(X.VOIDDATE)AS CHAR(4)))+'*' end as ReasonPayee
					,CAST(0 as bit) as Cleared,/*04/25/2014 DRP: ADDED VoidDate*/ cast(x.VOIDDATE as date) as VoidDate,bkrecon.LASTSTMTDT,x.ReconcileDate,x.RECONUNIQ
					,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
					,CAST (0.00 as numeric(15,2)) as LastBookDeposit,CAST (0.00 as numeric(15,2)) as DepNotPost
					,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
					,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
					,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
					,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
					,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
			from	bkrecon	
					inner join BANKS on banks.BK_UNIQ = bkrecon.BK_UNIQ
					LEFT OUTER JOIN (SELECT	CAST(ISNULL(ShipBill.ShipTo,' ') as CHAR(35)) as ShipTo,CheckDate,CheckNo,CheckAmt,apchkmst.BK_UNIQ  
											,ApChk_Uniq,Reconcilestatus,ReconcileDate,APCHKMST.ReconUniq
											,CASE WHEN Reconcilestatus=' ' THEN cast(0 as bit)WHEN Reconcilestatus='C' THEN cast(1 as bit) END AS Cleared
											,VOIDDATE
									 FROM	ApChkMst 
											LEFT OUTER JOIN  ShipBill ON ApChkMst.R_Link = ShipBill.LinkAdd 
											LEFT OUTER JOIN BKRECON ON APCHKMST.reconuniq = BKRECON.RECONUNIQ 								 
									 WHERE	ApChkMst.BK_Uniq = @lcBk_Uniq   
/*03/13/2014 drp:							--AND CHARINDEX('Void',ApChkMst.Status)=0  */
/*03/13/2014 drp:  added*/					AND CHARINDEX('Voiding Entry',ApChkMst.Status)=0  
/*03/13/2014 drp:  added*/					and (DATEDIFF(day,apchkmst.VOIDDATE,@ldStmtDate) <=0 or apchkmst.VOIDDATE is null )
											AND DATEDIFF(day,ApChkMst.CheckDate,@ldStmtDate) >=0
/*03/28/2014 drp:  added*/					and apchkmst.CHECKAMT <> 0.00
											AND APCHKMST.reconuniq <> @lcReconUniq
											-- 07/18/19 VL found the code added on 04/11/19 would remove those not cleared records that have not have Bkrecon record yet.  Added ApchkMst.Reconuniq='' to include those not cleared records but filter out those records marked as reconciled but didn't really reconcilied, #5520
											-- 04/11/19 YS/VL added BKRECON.STMTDATE IS NOT NULL criteria, so if the record didn't have associated Bkrecon record, it won't show, sometimes we fix data by assigning a value in reconuniq field, but no Bkrecon record is created
											--and ((reconciledate IS NULL and BKRECON.STMTDATE IS NOT NULL)  OR datediff(day,@ldStmtDate , STMTDATE )>0)) AS X ON BKRECON.BK_UNIQ = X.BK_UNIQ
											and ((reconciledate IS NULL AND Apchkmst.ReconUniq='') OR datediff(day,@ldStmtDate , STMTDATE )>0)) AS X ON BKRECON.BK_UNIQ = X.BK_UNIQ
											
			where	@lcReconUniq = bkrecon.RECONUNIQ
			order by ReconcileDate
		--OsCks End
	--**********
	--**********
	--JOURNAL ENTRY DEPOSITS
	--**********
	--Gathers Cleared JE Bank Deposits
		--ClearJeDep Begin
		insert into @results 
			select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
					,CAST('Journal Entry Deposits' as CHAR(25)) as RecordType,isnull(JeD.TRANSDATE,'') as [Date],isnull(JeD.JE_NO,0) as Reference,isnull(JeD.DEBIT,0.00) as Amount
					,isnull(JeD.REASON,'') as ReasonPayee,cast (1 as bit) as Cleared,/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as smalldatetime) as voiddate
					,bkrecon.LASTSTMTDT,JeD.ReconcileDate,isnull(JeD.RECONUNIQ,'')
					,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
					,CAST (0.00 as numeric(15,2)) as DepDeposit,CAST (0.00 as numeric(15,2)) as DepNotPost
					,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
					,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
					,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
					,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
					,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
			from	bkrecon	
					inner join BANKS on banks.BK_UNIQ = bkrecon.BK_UNIQ
					left outer join (SELECT	gljehdr.je_no,gljehdr.TransDate,gljehdr.reason,gljedet.Debit,GL_NBR
											,CASE WHEN gljedet.Reconcilestatus=' ' THEN cast(0 as bit)WHEN gljedet.ReconcileStatus='C' THEN cast(1 as bit) END AS Cleared
											,ReconcileDate,gljedet.ReconUniq
									 FROM	gljehdr 
											INNER JOIN gljedet ON gljehdr.uniqjehead = gljedet.uniqjehead 
											left outer join BKRECON on gljedet.ReconUniq = BKRECON.RECONUNIQ
									 WHERE  gljedet.gl_nbr =@gl_nbr
											AND Debit<>0.00
											AND DATEDIFF(day,GlJeHdr.TRANSDATE,@ldStmtDate) >=0 
											and gljedet.ReconUniq = @lcReconUniq) as JeD on banks.GL_NBR = JeD.gl_nbr
			where	@lcReconUniq = bkrecon.reconuniq
		--ClearJeDep End
	
	--Gathers Outstanding JE Bank Deposits
		--OsJeDep Begin
		insert into @results 
			select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
					,CAST('Journal Entry Deposits' as CHAR(25)) as RecordType,isnull(JeD.TRANSDATE,'') as [Date],isnull(JeD.JE_NO,0) as Reference,isnull(JeD.DEBIT,0.00) as Amount
					,isnull(JeD.REASON,'') as ReasonPayee,CAST (0 as bit) as cleared,/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as smalldatetime) as voiddate
					,bkrecon.LASTSTMTDT,JeD.ReconcileDate,isnull(JeD.RECONUNIQ,'')
					,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
					,CAST (0.00 as numeric(15,2)) as DepDeposit,CAST (0.00 as numeric(15,2)) as DepNotPost
					,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
					,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
					,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
					,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
					,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
			from	bkrecon	
					inner join BANKS on banks.BK_UNIQ = bkrecon.BK_UNIQ
					left outer join (SELECT	gljehdr.je_no,gljehdr.TransDate,gljehdr.reason,gljedet.Debit,GL_NBR
											,CASE WHEN gljedet.Reconcilestatus=' ' THEN cast(0 as bit)WHEN gljedet.ReconcileStatus='C' THEN cast(1 as bit) END AS Cleared
											,ReconcileDate,gljedet.ReconUniq
									 FROM	gljehdr 
											INNER JOIN gljedet ON gljehdr.uniqjehead = gljedet.uniqjehead 
											left outer join BKRECON on gljedet.ReconUniq = bkrecon.RECONUNIQ
									 WHERE  gljedet.gl_nbr =@gl_nbr
											AND Debit<>0.00
											AND DATEDIFF(day,GlJeHdr.TRANSDATE,@ldStmtDate) >=0 
											and gljedet.ReconUniq <> @lcReconUniq
											-- 07/18/19 VL found the code added on 04/11/19 would remove those not cleared records that have not have Bkrecon record yet.  Added ApchkMst.Reconuniq='' to include those not cleared records but filter out those records marked as reconciled but didn't really reconcilied, #5520
											-- 04/11/19 YS/VL added BKRECON.STMTDATE IS NOT NULL criteria, so if the record didn't have associated Bkrecon record, it won't show, sometimes we fix data by assigning a value in reconuniq field, but no Bkrecon record is created
											--and ((reconciledate is null and BKRECON.STMTDATE IS NOT NULL) or  datediff(day,@ldStmtDate , STMTDATE )>0)) as JeD on banks.GL_NBR = JeD.gl_nbr
											and ((reconciledate is null AND GlJedet.ReconUniq='') or  datediff(day,@ldStmtDate , STMTDATE )>0)) as JeD on banks.GL_NBR = JeD.gl_nbr

			where	@lcReconUniq = bkrecon.reconuniq
		--OsJeDep End
	--**********
	--**********
	--JOURNAL ENTRY WITHDRAWALS
	--**********
	--Gathers Cleared JE Bank Withdrawals
		--ClearJeW Begin
		insert into @results
		select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
				,CAST('Journal Entry Withdrawals' as CHAR(25)) as RecordType,isnull(JeW.TRANSDATE,'') as [Date],isnull(JeW.JE_NO,0) as Reference,isnull(JeW.CREDIT,0.00) as Amount
				,isnull(JeW.REASON,'') as ReasonPayee,CAST (1 as bit) as Cleared,/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as smalldatetime) as voiddate
				,bkrecon.LASTSTMTDT,JeW.ReconcileDate,isnull(JeW.RECONUNIQ,'')
				,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
				,CAST (0.00 as numeric(15,2)) as DepPost,CAST (0.00 as numeric(15,2)) as DepNotPost
				,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
				,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
				,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
				,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
				,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
		from	BKRECON
				inner join BANKS on BANKs.BK_UNIQ = Bkrecon.BK_UNIQ
				left outer join (SELECT	gljehdr.je_no,gljehdr.TRANSDATE,gljehdr.reason,gljedet.credit,gl_nbr
										,CASE WHEN GlJeDet.Reconcilestatus=' ' THEN cast(0 as bit) WHEN GlJeDet.ReconcileStatus='C' THEN cast(1 as bit) END AS Cleared
										,ReconcileDate,gljedet.ReconUniq
								 FROM	gljehdr 
										INNER JOIN gljedet ON gljehdr.uniqjehead = gljedet.uniqjehead
										left outer join BKRECON on gljedet.ReconUniq = BKRECON.RECONUNIQ
								 WHERE	gljedet.gl_nbr =@gl_nbr
										AND CREDIT<>0.00
										AND DATEDIFF(day,GlJeHdr.TRANSDATE ,@ldStmtDate) >=0 
										and gljedet.ReconUniq = @lcReconUniq) as JeW on Banks.gl_nbr = JeW.Gl_nbr
		where	@lcReconUniq = bkrecon.RECONUNIQ
		--ClearJeW End
	
	--Gathers Outstanding JE Bank Withdrawals
		--OsJeW Begin
		insert into @results
		select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
				,CAST('Journal Entry Withdrawals' as CHAR(25)) as RecordType,isnull(JeW.TRANSDATE,'') as [Date],isnull(JeW.JE_NO,0) as Reference,isnull(JeW.CREDIT,0.00) as Amount
				,isnull(JeW.REASON,'') as ReasonPayee,isnull(Jew.Cleared,0),/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as smalldatetime) as voiddate
				,bkrecon.LASTSTMTDT,JeW.ReconcileDate,isnull(JeW.RECONUNIQ,'')
				,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
				,CAST (0.00 as numeric(15,2)) as DepPost,CAST (0.00 as numeric(15,2)) as DepNotPost
				,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
				,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
				,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
				,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
				,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
		from	BKRECON
				inner join BANKS on BANKs.BK_UNIQ = Bkrecon.BK_UNIQ
				left outer join (SELECT	gljehdr.je_no,gljehdr.TRANSDATE,gljehdr.reason,gljedet.credit,gl_nbr
										,CASE WHEN GlJeDet.Reconcilestatus=' ' THEN cast(0 as bit) WHEN GlJeDet.ReconcileStatus='C' THEN cast(1 as bit) END AS Cleared
										,ReconcileDate,gljedet.ReconUniq
								 FROM	gljehdr 
										INNER JOIN gljedet ON gljehdr.uniqjehead = gljedet.uniqjehead
										left outer join BKRECON on gljedet.ReconUniq = bkrecon.RECONUNIQ
								 WHERE	gljedet.gl_nbr =@gl_nbr
										AND CREDIT<>0.00
										AND DATEDIFF(day,GlJeHdr.TRANSDATE ,@ldStmtDate) >=0 
										and gljedet.ReconUniq <> @lcReconUniq
										-- 07/18/19 VL found the code added on 04/11/19 would remove those not cleared records that have not have Bkrecon record yet.  Added ApchkMst.Reconuniq='' to include those not cleared records but filter out those records marked as reconciled but didn't really reconcilied, #5520
										-- 04/11/19 YS/VL added BKRECON.STMTDATE IS NOT NULL criteria, so if the record didn't have associated Bkrecon record, it won't show, sometimes we fix data by assigning a value in reconuniq field, but no Bkrecon record is created
										--and ((reconciledate is null and BKRECON.STMTDATE IS NOT NULL) or  datediff(day,@ldStmtDate , STMTDATE )>0)) as JeW on Banks.gl_nbr = JeW.Gl_nbr
										and ((reconciledate is null AND Gljedet.ReconUniq = '') or  datediff(day,@ldStmtDate , STMTDATE )>0)) as JeW on Banks.gl_nbr = JeW.Gl_nbr
		where	@lcReconUniq = bkrecon.RECONUNIQ
		--OsJeW End
	--**********
	--**********
	--NSF
	--**********
	--Gathers the Cleared NSF
		--ClearNsf Begin
	insert into @results
		select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
				,CAST('NSF' as CHAR(25)) as RecordType,isnull(nsf.Date,'') as [Date],isnull(nsf.REC_ADVICE,'') as Reference,isnull(nsf.REC_AMOUNT,0.00) as Amount
				,isnull(nsf.CustName,'') as ReasonPayee,CAST (1 as bit) as Cleared,/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as smalldatetime) as voiddate
				,bkrecon.LASTSTMTDT,nsf.ReconcileDate,isnull(nsf.RECONUNIQ,'')
				,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
				,CAST (0.00 as numeric(15,2)) as DepPost,CAST (0.00 as numeric(15,2)) as DepNotPost
				,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
				,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
				,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
				,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
				,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
		from	BKRECON
				inner join BANKS on BANKs.BK_UNIQ = Bkrecon.BK_UNIQ
				left outer join (SELECT	ARRETCK.Ret_Date as [Date],ARRETDET.REC_ADVICE,ArretDet.Rec_Amount,ISNULL(Customer.CUSTNAME,SPACE(35)) as CustName,DEPOSITS.BK_UNIQ
										,CASE WHEN ARRETDET.Reconcilestatus=' ' THEN CAST(0 as bit)WHEN ARRETDET.Reconcilestatus='C' THEN CAST(1 as bit) END  as Cleared
										,ReconcileDate,arretdet.ReconUniq
								 FROM	ArRetCk 
										INNER JOIN Deposits ON Arretck.Dep_no=Deposits.Dep_no
										INNER JOIN Arretdet ON ArretCk.UniqRetNo = ARRETDET.UniqRetno
										LEFT OUTER JOIN Customer ON Arretdet.Custno=Customer.CUSTNO 
										left outer join BKRECON on arretdet.ReconUniq = bkrecon.RECONUNIQ
								 where	(Deposits.Bk_Uniq = @lcbk_Uniq) 
										AND DATEDIFF(day,Ret_Date,@ldStmtDate) >=0 
										and arretdet.ReconUniq = @lcReconUniq) as NSF on BKRECON.BK_UNIQ = NSF.BK_UNIQ
		where	@lcReconUniq = bkrecon.RECONUNIQ
		--ClearNsf End

	--Gathers the Outstanding NSF 
		--OsNsf Begin
		insert into @results
		select	bkrecon.reconuniq,Banks.bank,banks.BK_ACCT_NO,banks.accttitle,stmtdate,recondate,bkrecon.bk_uniq,LASTSTMBAL,StmtTotalDep,StmtWithdrawl,IntEarned,SVCCHGS,DepCorr,WITHDRCORR
				,CAST('NSF' as CHAR(25)) as RecordType,isnull(nsf.Date,'') as [Date],isnull(nsf.REC_ADVICE,'') as Reference,isnull(nsf.REC_AMOUNT,0.00) as Amount
				,isnull(nsf.CustName,'') as ReasonPayee,isnull(Nsf.Cleared,0),/*04/25/2014 DRP: ADDED VoidDate*/ cast (null as smalldatetime) as voiddate
				,bkrecon.LASTSTMTDT,nsf.ReconcileDate,isnull(nsf.RECONUNIQ,'')
				,CAST (0.00 as numeric(15,2)) as LastPostBookTotal,CAST (0.00 as numeric(15,2)) as LastNotPostBookTotal
				,CAST (0.00 as numeric(15,2)) as DepPost,CAST (0.00 as numeric(15,2)) as DepNotPost
				,cast (0.00 as numeric (15,2)) as ChkPost,cast (0.00 as numeric (15,2)) as ChkNotPost 
				,cast (0.00 as numeric (15,2)) as JeDebitPost,cast (0.00 as numeric(15,2)) as JeDebitNotPost
				,cast (0.00 as numeric (15,2)) as JeCreditPost,cast (0.00 as numeric (15,2)) as JeCreditNotPost
				,cast (0.00 as numeric (15,2)) as NsfPost,cast (0.00 as numeric(15,2)) as NsfNotPost
				,CAST (0.00 as numeric (15,2)) as PostBookTotal,CAST(0.00 as numeric(15,2)) as NotPostBookTotal
		from	BKRECON
				inner join BANKS on BANKs.BK_UNIQ = Bkrecon.BK_UNIQ
				left outer join (SELECT	ARRETCK.Ret_Date as [Date],ARRETDET.REC_ADVICE,ArretDet.Rec_Amount,ISNULL(Customer.CUSTNAME,SPACE(35)) as CustName,DEPOSITS.BK_UNIQ
										,CASE WHEN ARRETDET.Reconcilestatus=' ' THEN CAST(0 as bit)WHEN ARRETDET.Reconcilestatus='C' THEN CAST(1 as bit) END  as Cleared
										,ReconcileDate,arretdet.ReconUniq
								 FROM	ArRetCk 
										INNER JOIN Deposits ON Arretck.Dep_no=Deposits.Dep_no
										INNER JOIN Arretdet ON ArretCk.UniqRetNo = ARRETDET.UniqRetno
										LEFT OUTER JOIN Customer ON Arretdet.Custno=Customer.CUSTNO 
										left outer join BKRECON on arretdet.ReconUniq = bkrecon.RECONUNIQ
								 where	(Deposits.Bk_Uniq = @lcbk_Uniq) 
										AND DATEDIFF(day,Ret_Date,@ldStmtDate) >=0 
										and arretdet.ReconUniq <> @lcReconUniq
										-- 07/18/19 VL found the code added on 04/11/19 would remove those not cleared records that have not have Bkrecon record yet.  Added ApchkMst.Reconuniq='' to include those not cleared records but filter out those records marked as reconciled but didn't really reconcilied, #5520
										-- 04/11/19 YS/VL added BKRECON.STMTDATE IS NOT NULL criteria, so if the record didn't have associated Bkrecon record, it won't show, sometimes we fix data by assigning a value in reconuniq field, but no Bkrecon record is created
										--and ((reconciledate is null and BKRECON.STMTDATE IS NOT NULL) or  datediff(day,@ldStmtDate , STMTDATE )>0)) as NSF on BKRECON.BK_UNIQ = NSF.BK_UNIQ
										and ((reconciledate is null AND Arretdet.ReconUniq = '') or  datediff(day,@ldStmtDate , STMTDATE )>0)) as NSF on BKRECON.BK_UNIQ = NSF.BK_UNIQ
		where	@lcReconUniq = bkrecon.RECONUNIQ
		--OsNsf End
	--**********
	
	
	--12/16/2013 THEN UPDATED THE RESULTS TABLE WITH THE VALUES
	update @results set LastPostBookTotal =  (ISNULL(@ldPriorDepPost,0.00) + ISNULL(@ldPriorjeDebitPost,0.00)) -(ISNULL(@ldPriorChkPost,0.00)+ ISNULL(@ldPriorJeCreditPost,0.00)+ ISNULL(@ldPriorNsfPost,0.00))
	update @results set LastNotPostBookTotal = (ISNULL(@ldPriorDepNotPost,0.00) + ISNULL(@ldPriorjeDebitNotPost,0.00)) - (ISNULL(@ldPriorChkNotPost,0.00) + ISNULL(@ldPriorjeCreditNotPost,0.00)+ISNULL(@ldPriorNsfNotPost,0.00))
	update @results set PostBookTotal = (ISNULL(@ldDepPost,0.00) + ISNULL(@ldjeDebitPost,0.00)) -(ISNULL(@ldChkPost,0.00)+ ISNULL(@ldJeCreditPost,0.00)+ ISNULL(@ldNsfPost,0.00))
	update @results set NotPostBookTotal = (ISNULL(@ldDepNotPost,0.00) + ISNULL(@ldjeDebitNotPost,0.00)) - (ISNULL(@ldChkNotPost,0.00) + ISNULL(@ldjeCreditNotPost,0.00)+ISNULL(@ldNsfNotPost,0.00))
	update @results set DepPost  = ISNULL(@ldDepPost,0.00)
	update @results set DepNotPost = isnull(@ldDepNotPost,0.00)
	update @results set ChkPost = isnull(@ldChkPost,0.00)
	update @results set ChkNotPost = ISNULL(@ldChkNotPost,0.00)
	update @results set JeDebitPost = isnull(@ldJeDebitPost,0.00)
	UPDATE @results SET JeDebitNotPost = ISNULL(@ldJeDebitNotPost,0.00)
	update @results set JeCreditPost = isnull(@ldJeCreditPost,0.00)
	update @results set JeCreditNotPost = isnull(@ldJeCreditNotPost,0.00)
	update @results set NsfPost = ISNULL(@ldNsfPost,0.00)
	Update @results set NsfNotPost = ISNULL(@ldNsfNotPost,0.00)
	

	--**********
	--**********

	select * from @results order by RecordType,cleared,Date,Reference
	End