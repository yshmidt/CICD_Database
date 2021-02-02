
-- =============================================  
-- Author:  Nilesh Sa  
-- Create date: 3/04/2019  
-- Description: Check account Dependency if user is changing the account info
-- exec CheckAcctDependency '2100000-00-00'
-- =============================================  
CREATE PROCEDURE [dbo].[CheckAcctDependency] @glNbr char(13)
AS
BEGIN
  -- SET NOCOUNT ON added to prevent extra result sets from  
  -- interfering with SELECT statements.  
  SET NOCOUNT ON;

  SELECT
    gluniq_key
  FROM GlTrans
  WHERE @glNbr <> ' '
  AND Gl_nbr = @glNbr
  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number that had postings cannot be deleted!. This operation will be cancelled.', 1, 1);
    RETURN;
  END
  -- Double check Gl_Acct for setup balances  
  SELECT
    UniqueRec
  FROM Gl_Acct
  WHERE Gl_nbr = @glNbr
  AND @glNbr <> ' '
  AND (beg_bal <> 0.00
  OR end_bal <> 0.00)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number that had postings cannot be deleted!. This operation will be cancelled.', 1, 1);
    RETURN;
  END
  -- Checking Setups  
  SELECT
    Micssys.UniqueRec
  FROM MicsSys
  WHERE @glNbr <> ' '
  AND (Inv_gl_no = @glNbr
  OR Wip_gl_no = @glNbr
  OR Fig_gl_no = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one of the system setup files and cannot be deleted!', 1, 1); ;
    RETURN;
  END
  -- GlSys  
  SELECT
    GlSys.UniqGlSys
  FROM GlSys
  WHERE @glNbr <> ' '
  AND (Ret_earn = @glNbr
  OR Cur_earn = @glNbr
  OR Post_susp = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the General Ledger setup and cannot be deleted!', 1, 1); ;
    RETURN;
  END
  -- Tax Tables  
  SELECT
    TaxUnique
  FROM taxTabl
  WHERE @glNbr <> ' '
  AND (Gl_nbr_in = @glNbr
  OR Gl_Nbr_out = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the tax table setup and cannot be deleted!', 1, 1);
    RETURN;
  END

  SELECT
    InvStdTxUniq
  FROM InvStdtx
  WHERE @glNbr <> ' '
  AND (Gl_nbr_in = @glNbr
  OR Gl_Nbr_out = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the tax table setup and cannot be deleted!', 1, 1);
    RETURN;
  END
  -- Inventory Setup  
  SELECT
    UNIQINVSET
  FROM InvSetup
  WHERE @glNbr <> ' '
  AND ([RAWM_GL_NO] = @glNbr
  OR [WORK_GL_NO] = @glNbr
  OR [FINI_GL_NO] = @glNbr
  OR [PURC_GL_NO] = @glNbr
  OR [CONF_GL_NO] = @glNbr
  OR [MANU_GL_NO] = @glNbr
  OR [SHRI_GL_NO] = @glNbr
  OR [IADJ_GL_NO] = @glNbr
  OR [INST_GL_NO] = @glNbr
  OR [MAT_V_GL] = @glNbr
  OR [LAB_V_GL] = @glNbr
  OR [OVER_V_GL] = @glNbr
  OR [OTH_V_GL] = @glNbr
  OR [UNRECON_GL_NO] = @glNbr
  OR [USERDEF_GL] = @glNbr
  OR [STDCOSTADJGLNO] = @glNbr
  OR [RUNDVAR_GL] = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the Inventory Setup (InvSetup) and cannot be deleted!', 1, 1);
    RETURN;
  END
  -- Accounts Payable  
  SELECT
    [UNIQAPSET]
  FROM [APSETUP]
  WHERE @glNbr <> ' '
  AND ([AP_GL_NO] = @glNbr
  OR [CK_GL_NO] = @glNbr
  OR [DISC_GL_NO] = @glNbr
  OR [PO_REC_HOLD] = @glNbr
  OR [VDISC_GL_NO] = @glNbr
  OR [FRT_GL_NO] = @glNbr
  OR [PU_GL_NO] = @glNbr
  OR [RET_GL_NO] = @glNbr
  OR [STAX_GL_NO] = @glNbr
  OR [PREPAYGLNO] = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the Accounts Payable Setup (ApSetup) and cannot be deleted!', 1, 1);
    RETURN;
  END
  -- Accounts Receivable  
  SELECT
    [UNIQARSET]
  FROM ARSETUP
  WHERE @glNbr <> ' '
  AND ([AR_GL_NO] = @glNbr
  OR [DEP_GL_NO] = @glNbr
  OR [DISC_GL_NO] = @glNbr
  OR [PC_GL_NO] = @glNbr
  OR [OC_GL_NO] = @glNbr
  OR [OT_GL_NO] = @glNbr
  OR [FRT_GL_NO] = @glNbr
  OR [FC_GL_NO] = @glNbr
  OR [CUDEPGL_NO] = @glNbr
  OR [ST_GL_NO] = @glNbr
  OR [AL_GL_NO] = @glNbr
  OR [BD_GL_NO] = @glNbr
  OR [RET_GL_NO] = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the Accounts Receivable Setup (ArSetup) and cannot be deleted!', 1, 1);
    RETURN;
  END

  -- Sales Setup  
  SELECT
    Uniquenum
  FROM SaleType
  WHERE @glNbr <> ' '
  AND (SaleType.Gl_nbr = @glNbr
  OR Cog_Gl_Nbr = @glNbr)


  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the Sales Type Setup (SaleType) and cannot be deleted!', 1, 1);
    RETURN;
  END
  -- Purchasing and Inventory handling  
  SELECT
    [UNIQFIELD]
  FROM InvtGls
  WHERE gl_nbr = @glNbr
  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the Purchase MRO And Inventory Handling GL Setup (InvtGls) and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- Warehouse Setup  
  SELECT
    Wh_gl_nbr
  FROM Warehous
  WHERE @glNbr <> ' '
  AND (Wh_gl_nbr = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the Warehouse Setup (Warehous) and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- Banks  
  SELECT
    Bk_uniq
  FROM Banks
  WHERE @glNbr <> ' '
  AND (Banks.gl_nbr = @glNbr
  OR Bc_gl_nbr = @glNbr
  OR int_gl_nbr = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in the Banks Setup (Banks) and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- Check Journal Entries  
  SELECT
    Gl_nbr
  FROM GlJeDeto
  WHERE Gl_nbr = @glNbr

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in a General Journal Entry and cannot be deleted!', 1, 1)
    RETURN;
  END
  SELECT
    Gl_nbr
  FROM GlJeDet,
       GlJeHdr
  WHERE Gl_nbr = @glNbr
  AND GlJeDet.uniqjehead = GlJeHdr.uniqjehead
  AND Status <> 'POSTED'


  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in a General Journal Entry that has not been posted  and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- now check poitschd  
  SELECT
    UniqDetNo
  FROM PoItSchd
  WHERE Gl_Nbr = @glNbr
  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more POs and cannot be deleted!', 1, 1)
    RETURN;
  END

  -- accounts payable records  
  SELECT
    UniqApDetl
  FROM ApDetail
  WHERE Gl_Nbr = @glNbr

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more AP records and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- PO Receiving Unreconciled  

  SELECT
    UniqRecRel
  FROM PorecRelGl
  WHERE @glNbr <> ' '
  AND (Raw_Gl_Nbr = @glNbr
  OR Unrecon_Gl_Nbr = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more PO receiving records as un-reconciled or raw material account and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- Sales Order and Packing List  
  -- Sales Order  
  SELECT
    PlPricelnk
  FROM SoPrices
  WHERE @glNbr <> ' '
  AND (Pl_gl_nbr = @glNbr
  OR Cog_gl_nbr = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN

    RAISERROR ('GL Account number is used in one or more Sales order records and cannot be deleted!', 1, 1)
    RETURN;
  END

  -- Packing list  
  SELECT
    PackListNo
  FROM PlMain
  WHERE @glNbr <> ' '
  AND (Cog_gl_nbr = @glNbr
  OR wip_gl_nbr = @glNbr
  OR Al_gl_no = @glNbr
  OR CuDepGl_no = @glNbr
  OR Ot_gl_no = @glNbr
  OR Frt_gl_no = @glNbr
  OR Fc_gl_no = @glNbr
  OR Disc_Gl_no = @glNbr
  OR Ar_gl_no = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN

    RAISERROR ('GL Account number is used in one or more Packing list records and cannot be deleted!', 1, 1)
    RETURN;
  END

  SELECT
    PlUniqLnk
  FROM PlPrices
  WHERE @glNbr <> ' '
  AND (Pl_gl_nbr = @glNbr
  OR Cog_gl_nbr = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Packing list records and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- Credit Memo  
  SELECT
    CmPrUniq
  FROM CmPrices
  WHERE @glNbr <> ' '
  AND (Pl_gl_nbr = @glNbr
  OR Cog_gl_nbr = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN

    RAISERROR ('GL Account number is used in one or more Credit Memo records and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- Deposits  
  SELECT
    Uniqdetno
  FROM Arcredit
  WHERE Gl_nbr = @glNbr

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Account Receivable Deposits records and cannot be deleted!', 1, 1)
    RETURN;
  END

  -- Debit Memos  
  SELECT
    UniqDmDetl
  FROM ApDmDetl
  WHERE Gl_nbr = @glNbr


  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Debit Memo records and cannot be deleted!', 1, 1)
    RETURN;
  END

  -- Checks  
  SELECT
    ApCkD_uniq
  FROM ApChkDet
  WHERE Gl_nbr = @glNbr


  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Check records and cannot be deleted!', 1, 1)
    RETURN;
  END

  -- Returned Checks  
  SELECT
    ArRetDetUniq
  FROM ArRetDet
  WHERE Gl_nbr = @glNbr


  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Return Check records and cannot be deleted!', 1, 1)
    RETURN;
  END
  -- Inventory s  
  -- Receipts  
  SELECT
    InvtRec_no
  FROM invt_rec
  WHERE @glNbr <> ' '
  AND (Invt_rec.Gl_nbr = @glNbr
  OR Gl_nbr_inv = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Inventory Receipt records and cannot be deleted!', 1, 1)
    RETURN;
  END

  -- Issues  
  SELECT
    InvtIsu_no
  FROM invt_Isu
  WHERE @glNbr <> ' '
  AND (Invt_isu.Gl_nbr = @glNbr
  OR Gl_nbr_inv = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Inventory Issue records and cannot be deleted!', 1, 1)
    RETURN;
  END

  -- Transfers  
  SELECT
    InvtXfer_n
  FROM invtTrns
  WHERE @glNbr <> ' '
  AND (InvtTrns.Gl_nbr = @glNbr
  OR Gl_nbr_inv = @glNbr)

  IF @@ROWCOUNT <> 0
  BEGIN
    RAISERROR ('GL Account number is used in one or more Inventory transfer records and cannot be deleted!', 1, 1);
    RETURN;
  END

  ---- if we got here we can remove all the records from gl_acct for the deleted account(s)  
  DELETE FROM Gl_acct
  WHERE gl_nbr = @glNbr;
END