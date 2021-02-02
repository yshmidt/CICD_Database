CREATE TABLE [dbo].[GL_NBRS] (
    [GL_NBR]     CHAR (13)       CONSTRAINT [DF__GL_NBRS__GL_NBR__709E980D] DEFAULT ('') NOT NULL,
    [GL_CLASS]   CHAR (7)        CONSTRAINT [DF__GL_NBRS__GL_CLAS__7192BC46] DEFAULT ('') NOT NULL,
    [GL_DESCR]   CHAR (30)       CONSTRAINT [DF__GL_NBRS__GL_DESC__7286E07F] DEFAULT ('') NOT NULL,
    [LONG_DESCR] CHAR (52)       CONSTRAINT [DF__GL_NBRS__LONG_DE__737B04B8] DEFAULT ('') NOT NULL,
    [GLTYPE]     CHAR (3)        CONSTRAINT [DF__GL_NBRS__GLTYPE__746F28F1] DEFAULT ('') NOT NULL,
    [STMT]       CHAR (3)        CONSTRAINT [DF__GL_NBRS__STMT__75634D2A] DEFAULT ('') NOT NULL,
    [STATUS]     CHAR (8)        CONSTRAINT [DF__GL_NBRS__STATUS__76577163] DEFAULT ('') NOT NULL,
    [GL_NOTE]    TEXT            CONSTRAINT [DF__GL_NBRS__GL_NOTE__774B959C] DEFAULT ('') NOT NULL,
    [TOT_START]  CHAR (13)       CONSTRAINT [DF__GL_NBRS__TOT_STA__7A280247] DEFAULT ('') NOT NULL,
    [TOT_END]    CHAR (13)       CONSTRAINT [DF__GL_NBRS__TOT_END__7B1C2680] DEFAULT ('') NOT NULL,
    [CURR_BAL]   NUMERIC (14, 2) CONSTRAINT [DF__GL_NBRS__CURR_BA__7C104AB9] DEFAULT ((0)) NOT NULL,
    [MTD_BAL]    NUMERIC (14, 2) CONSTRAINT [DF__GL_NBRS__MTD_BAL__7D046EF2] DEFAULT ((0)) NOT NULL,
    [GLIS_POST]  BIT             CONSTRAINT [DF__GL_NBRS__GLIS_PO__232A17DA] DEFAULT ((0)) NOT NULL,
    [IsQbSync]   BIT             CONSTRAINT [DF__GL_NBRS__IsQbSyn__35CB185E] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [GL_NBRS_PK] PRIMARY KEY CLUSTERED ([GL_NBR] ASC)
);


GO
CREATE NONCLUSTERED INDEX [GLIS_POST]
    ON [dbo].[GL_NBRS]([GLIS_POST] ASC);


GO
Create TRIGGER [dbo].[GL_NBRS_Update] 
   ON  [dbo].[GL_NBRS] 
   AFTER UPDATE
AS 
BEGIN

	  Update GL_NBRS SET 
					isQBSync= 
						     CASE WHEN (I.isQBSync = 1 and D.isQBSync = 1) THEN 0
						       WHEN (I.isQBSync = 1 and D.isQBSync = 0) THEN 1
						ELSE 0 END	
					FROM inserted I inner join deleted D on i.isQBSync=d.isQBSync
					where I.GL_NBR =GL_NBRS.GL_NBR  
END
GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/10/09>
-- Description:	<Insert trigger for the gl_nbrs will insert new records ito gl_acct >
--- starting with current FY
-- modified: 06/22/15 YS use new sequencenumber column to identify next year
-- =============================================
CREATE TRIGGER [dbo].[Gl_Nbrs_Insert]
   ON [dbo].[GL_NBRS]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	--DECLARE @lcCur_Fy char(4),@lcLast_Fy char(4)
	--06/22/15 YS use new sequencenumber column to identify next year
	DECLARE @lcCur_Fy char(4),@CurrentSequenceNumber int, @LastSequenceNumber int

	
			
	-- this table has only one record
	SELECT @lcCur_Fy=cur_fy FROM glSys;
	--SELECT @lcLast_Fy=MAX(FiscalYr) FROM GlFiscalYrs
	--06/22/15 YS use new sequencenumber column 
	select @CurrentSequenceNumber=y.sequencenumber ,
		@LastSequenceNumber=A.LastSequenceNumber
		from glfiscalyrs Y  cross apply (select top 1 sequencenumber as LastSequenceNumber from glfiscalyrs M order by sequencenumber desc) A
		where fiscalyr=@lcCur_Fy
	--WHILE @lcCur_Fy<=@lcLast_Fy
	WHILE @CurrentSequenceNumber<=@LastSequenceNumber
		BEGIN
			-- get all the periods for the selected year
			--INSERT INTO Gl_acct (Gl_nbr,Fk_fyDtlUniq) SELECT Inserted.Gl_nbr,FyDtlUniq 
			--		FROM glfYrsDetl,glfiscalYrs CROSS JOIN Inserted where Fk_Fy_uniq=glfiscalYrs.Fy_uniq
			--		AND FiscalYr=@lcCur_Fy ORDER BY FiscalYr,Period
			--06/22/15 YS use new sequencenumber column to identify a year
			INSERT INTO Gl_acct (Gl_nbr,Fk_fyDtlUniq) SELECT Inserted.Gl_nbr,FyDtlUniq 
					FROM glfYrsDetl,glfiscalYrs CROSS JOIN Inserted where Fk_Fy_uniq=glfiscalYrs.Fy_uniq
					AND SequenceNumber=@CurrentSequenceNumber ORDER BY SequenceNumber,Period
			--SET @lcCur_Fy = @lcCur_Fy+1	
			--06/22/15 YS use new sequencenumber column to identify next year
			set @CurrentSequenceNumber= @CurrentSequenceNumber+1			
		END -- while	 @lcCur_Fy<=@lcLast_Fy
END
GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/10/09>
-- Description:	<Delete trigger for GL_NBRS table >
-- Test for the account use prior removing and 
-- remove all associated records from Gl_acct table
-- 02/21/17 YS remove cog_gl_no from arsetup. Using Sales type for that
-- =============================================
CREATE TRIGGER [dbo].[GL_NBRS_DELETE] 
   ON [dbo].[GL_NBRS]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	-- Check first to see if there are any tranactions in GLTrans
	--07/11/12 YS check only if gl_nbr<>' '. If empty just remove
	
	 
	SELECT gluniq_key 
		FROM GlTrans
		WHERE Gl_nbr IN (SELECT GL_NBR FROM Deleted where GL_NBR<>' ')
	IF @@ROWCOUNT<>0 
		BEGIN
			RAISERROR('GL Account number that had postings cannot be deleted!. This operation will be cancelled.',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END
	-- Double check Gl_Acct for setup balances
	SELECT UniqueRec 
		FROM Gl_Acct 
		WHERE Gl_nbr IN (SELECT GL_NBR FROM Deleted WHERE Deleted.Gl_nbr<>' ' )
		AND (beg_bal<>0.00 OR end_bal<>0.00)
	
	IF @@ROWCOUNT<>0 
		BEGIN 
			RAISERROR('GL Account number that had postings cannot be deleted!. This operation will be cancelled.',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END
	-- Checking Setups
	SELECT Micssys.UniqueRec 
		FROM MicsSys,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Inv_gl_no = Deleted.Gl_nbr OR Wip_gl_no = Deleted.Gl_nbr OR Fig_gl_no = Deleted.Gl_nbr)
		
	IF @@ROWCOUNT<>0 
		BEGIN	
			RAISERROR('GL Account number is used in one of the system setup files and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END
	-- GlSys
	SELECT GlSys.UniqGlSys
		FROM GlSys,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Ret_earn = Deleted.Gl_nbr OR Cur_earn = Deleted.Gl_nbr OR Post_susp = Deleted.Gl_nbr)
	
	IF @@ROWCOUNT<>0 
		BEGIN	
			RAISERROR('GL Account number is used in the General Ledger setup and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END
	-- Tax Tables
	SELECT TaxUnique
		FROM taxTabl,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Gl_nbr_in = Deleted.Gl_Nbr OR Gl_Nbr_out = Deleted.Gl_Nbr ) 
		
	IF @@ROWCOUNT<>0 
		BEGIN
			RAISERROR('GL Account number is used in the tax table setup and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END	
	
	SELECT InvStdTxUniq
		FROM InvStdtx,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Gl_nbr_in = Deleted.Gl_Nbr OR Gl_Nbr_out = Deleted.Gl_Nbr ) 
		
	IF @@ROWCOUNT<>0 
		BEGIN
			RAISERROR('GL Account number is used in the tax table setup and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END	
	-- Inventory Setup
	SELECT UNIQINVSET
		FROM InvSetup,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND ([RAWM_GL_NO]= Deleted.Gl_nbr OR 
				[WORK_GL_NO]= Deleted.Gl_nbr OR
				[FINI_GL_NO]= Deleted.Gl_nbr OR
				[PURC_GL_NO]= Deleted.Gl_nbr OR
				[CONF_GL_NO]= Deleted.Gl_nbr OR
				[MANU_GL_NO]= Deleted.Gl_nbr OR
				[SHRI_GL_NO]= Deleted.Gl_nbr OR
				[IADJ_GL_NO]= Deleted.Gl_nbr OR
				[INST_GL_NO]= Deleted.Gl_nbr OR
				[MAT_V_GL]= Deleted.Gl_nbr OR
				[LAB_V_GL]= Deleted.Gl_nbr OR
				[OVER_V_GL]= Deleted.Gl_nbr OR
				[OTH_V_GL]= Deleted.Gl_nbr OR
				[UNRECON_GL_NO]= Deleted.Gl_nbr OR
				[USERDEF_GL]= Deleted.Gl_nbr OR
				[STDCOSTADJGLNO]= Deleted.Gl_nbr OR
				[RUNDVAR_GL]= Deleted.Gl_nbr )
	
	IF @@ROWCOUNT<>0 
		BEGIN
 			RAISERROR('GL Account number is used in the Inventory Setup (InvSetup) and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END	
	-- Accounts Payable
	SELECT [UNIQAPSET]
		FROM [APSETUP],Deleted
		WHERE Deleted.Gl_nbr<>' ' AND ([AP_GL_NO]= Deleted.Gl_nbr OR
		[CK_GL_NO]= Deleted.Gl_nbr OR
		[DISC_GL_NO]= Deleted.Gl_nbr OR
		[PO_REC_HOLD]= Deleted.Gl_nbr OR
        [VDISC_GL_NO]= Deleted.Gl_nbr OR
        [FRT_GL_NO]= Deleted.Gl_nbr OR
        [PU_GL_NO]= Deleted.Gl_nbr OR
        [RET_GL_NO]= Deleted.Gl_nbr OR
        [STAX_GL_NO]= Deleted.Gl_nbr OR
		[PREPAYGLNO]= Deleted.Gl_nbr)
	
	IF @@ROWCOUNT<>0 
		BEGIN
 			RAISERROR('GL Account number is used in the Accounts Payable Setup (ApSetup) and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END	
	-- Accounts Receivable
	SELECT  [UNIQARSET]
		FROM ARSETUP,Deleted   
	WHERE Deleted.Gl_nbr<>' ' AND ([AR_GL_NO]= Deleted.Gl_nbr OR
		  [DEP_GL_NO]= Deleted.Gl_nbr OR
      [DISC_GL_NO]= Deleted.Gl_nbr OR
      [PC_GL_NO]= Deleted.Gl_nbr OR
      [OC_GL_NO]= Deleted.Gl_nbr OR
      [OT_GL_NO]= Deleted.Gl_nbr OR
      [FRT_GL_NO]= Deleted.Gl_nbr OR
      [FC_GL_NO]= Deleted.Gl_nbr OR
      [CUDEPGL_NO]= Deleted.Gl_nbr OR
      [ST_GL_NO]= Deleted.Gl_nbr OR
      [AL_GL_NO]= Deleted.Gl_nbr OR
      [BD_GL_NO]= Deleted.Gl_nbr OR
      [RET_GL_NO]= Deleted.Gl_nbr )
	  -- 02/21/17 YS remove cog_gl_no from arsetup. Using Sales type for that
	  --OR
      --[COG_GL_NO]= Deleted.Gl_nbr)
    IF @@ROWCOUNT<>0 
		BEGIN
 			RAISERROR('GL Account number is used in the Accounts Receivable Setup (ArSetup) and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END

	-- Sales Setup
	SELECT Uniquenum
		FROM SaleType,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (SaleType.Gl_nbr = Deleted.Gl_nbr OR Cog_Gl_Nbr = Deleted.Gl_nbr) 
		
		
	IF @@ROWCOUNT <> 0
		BEGIN
			RAISERROR('GL Account number is used in the Sales Type Setup (SaleType) and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END		
	 -- Purchasing and Inventory handling
	SELECT [UNIQFIELD]
		FROM InvtGls 
		WHERE gl_nbr IN (SELECT Gl_nbr FROM Deleted WHERE Deleted.Gl_nbr<>' ')
	IF @@ROWCOUNT <> 0
		BEGIN
			RAISERROR('GL Account number is used in the Purchase MRO And Inventory Handling GL Setup (InvtGls) and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END	
	-- Warehouse Setup
	SELECT Wh_gl_nbr 
		FROM Warehous,Deleted
		WHERE Deleted.Gl_nbr<>' ' AND (Wh_gl_nbr = Deleted.Gl_nbr) 
	
	IF @@ROWCOUNT <> 0
		BEGIN
			RAISERROR('GL Account number is used in the Warehouse Setup (Warehous) and cannot be deleted!',1,1)
			ROLLBACK TRANSACTION
			RETURN
	END	
	-- Banks
	SELECT Bk_uniq
		FROM Banks,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Banks.gl_nbr = Deleted.gl_nbr OR Bc_gl_nbr = Deleted.Gl_nbr OR int_gl_nbr = Deleted.Gl_Nbr)

	IF @@ROWCOUNT <> 0
		BEGIN
		RAISERROR('GL Account number is used in the Banks Setup (Banks) and cannot be deleted!',1,1)
		ROLLBACK TRANSACTION	
		RETURN
	END	
	-- Check Journal Entries
	SELECT Gl_nbr 
		FROM GlJeDeto
		WHERE Gl_nbr IN (SELECT Gl_nbr FROM DELETED where Deleted.Gl_nbr<>' ')
		
	IF @@ROWCOUNT <> 0
		BEGIN
		RAISERROR('GL Account number is used in a General Journal Entry and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	END
	SELECT Gl_nbr 
		FROM GlJeDet,GlJeHdr
		WHERE Gl_nbr IN (SELECT Gl_nbr FROM DELETED where Deleted.Gl_nbr<>' ')
		AND GlJeDet.uniqjehead = GlJeHdr.uniqjehead 
		AND Status <> 'POSTED'
		
		
	IF @@ROWCOUNT<>0
		BEGIN
		RAISERROR('GL Account number is used in a General Journal Entry that has not been posted  and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	END	
	-- now check poitschd
	SELECT UniqDetNo 
		FROM PoItSchd 
		WHERE Gl_Nbr IN (SELECT Gl_nbr FROM Deleted where Deleted.Gl_nbr<>' ')
	IF @@ROWCOUNT <> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more POs and cannot be deleted!',1,1)
		ROLLBACK TRANSACTION
		RETURN	
	END		
	
	-- accounts payable records
	SELECT UniqApDetl
		FROM ApDetail 
		WHERE Gl_Nbr IN (SELECT Gl_nbr FROM Deleted where Deleted.Gl_nbr<>' ')
		
	IF @@ROWCOUNT <> 0
		BEGIN
			RAISERROR('GL Account number is used in one or more AP records and cannot be deleted!',1,1)	
			ROLLBACK TRANSACTION
			RETURN
	END	
	-- PO Receiving Unreconciled

	SELECT UniqRecRel
		FROM PorecRelGl,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Raw_Gl_Nbr = Deleted.Gl_nbr OR Unrecon_Gl_Nbr = Deleted.Gl_nbr)
		
	IF @@ROWCOUNT <> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more PO receiving records as un-reconciled or raw material account and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END
	-- Sales Order and Packing List
	-- Sales Order
	SELECT PlPricelnk
		FROM SoPrices,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Pl_gl_nbr = Deleted.Gl_Nbr OR Cog_gl_nbr = Deleted.Gl_Nbr) 
		
	IF @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Sales order records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END

	-- Packing list
	SELECT PackListNo
		FROM PlMain,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Cog_gl_nbr =Deleted.Gl_nbr OR wip_gl_nbr = Deleted.Gl_nbr 
			OR Al_gl_no = Deleted.Gl_nbr OR CuDepGl_no = Deleted.Gl_nbr 
			OR Ot_gl_no = Deleted.Gl_nbr OR Frt_gl_no = Deleted.Gl_nbr 
			OR Fc_gl_no = Deleted.Gl_nbr OR Disc_Gl_no = Deleted.Gl_nbr 
			OR Ar_gl_no = Deleted.Gl_nbr )

	IF @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Packing list records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT PlUniqLnk
		FROM PlPrices,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Pl_gl_nbr = Deleted.Gl_Nbr OR Cog_gl_nbr = Deleted.Gl_Nbr)

	IF @@ROWCOUNT<> 0
		BEGIN		
		RAISERROR('GL Account number is used in one or more Packing list records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END
	-- Credit Memo
	SELECT CmPrUniq 
		FROM CmPrices,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Pl_gl_nbr = Deleted.gl_Nbr OR Cog_gl_nbr = Deleted.Gl_Nbr)

	IF @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Credit Memo records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END
	-- Deposits
	SELECT Uniqdetno
		FROM Arcredit 
		WHERE Gl_nbr IN (SELECT Gl_nbr from Deleted where Deleted.Gl_nbr<>' ')
		
	IF @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Account Receivable Deposits records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END
	-- Debit Memos
	SELECT UniqDmDetl
		FROM ApDmDetl 
		WHERE Gl_nbr IN (SELECT Gl_nbr from Deleted where Deleted.Gl_nbr<>' ')


	IF @@ROWCOUNT<> 0
		BEGIN		
		RAISERROR('GL Account number is used in one or more Debit Memo records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END
	-- Checks
	SELECT ApCkD_uniq 
		FROM  ApChkDet 
		WHERE Gl_nbr IN (SELECT Gl_nbr from Deleted where Deleted.Gl_nbr<>' ')
	

	IF @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Check records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END	
	-- Returned Checks
	SELECT ArRetDetUniq
		FROM  ArRetDet 
		WHERE Gl_nbr IN (SELECT Gl_nbr from Deleted where Deleted.Gl_nbr<>' ')
		

	IF  @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Return Check records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END		
	-- Inventory transactions
	-- Receipts
	SELECT InvtRec_no
		FROM invt_rec,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Invt_rec.Gl_nbr = Deleted.Gl_nbr OR Gl_nbr_inv = Deleted.Gl_nbr)
		
	IF  @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Inventory Receipt records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END				
		
	-- Issues
	SELECT InvtIsu_no 
		FROM invt_Isu,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (Invt_isu.Gl_nbr = Deleted.Gl_nbr OR Gl_nbr_inv = Deleted.Gl_nbr) 

	IF  @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Inventory Issue records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END			

	-- Transfers
	SELECT InvtXfer_n
		FROM invtTrns,Deleted 
		WHERE Deleted.Gl_nbr<>' ' AND (InvtTrns.Gl_nbr =Deleted.Gl_nbr OR Gl_nbr_inv = Deleted.Gl_nbr) 

	IF  @@ROWCOUNT<> 0
		BEGIN
		RAISERROR('GL Account number is used in one or more Inventory transfer records and cannot be deleted!',1,1)	
		ROLLBACK TRANSACTION
		RETURN
	
	END		
	
	---- if we got here we can remove all the records from gl_acct for the deleted account(s)
	BEGIN TRANSACTION
	DELETE FROM Gl_acct where gl_nbr IN (SELECT Gl_nbr from DELETED)
	COMMIT
	

END