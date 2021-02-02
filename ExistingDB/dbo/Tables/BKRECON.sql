CREATE TABLE [dbo].[BKRECON] (
    [RECONUNIQ]       CHAR (10)       CONSTRAINT [DF__BKRECON__RECONUN__63A3C44B] DEFAULT ('') NOT NULL,
    [RECONDATE]       SMALLDATETIME   CONSTRAINT [DF_BKRECON_RECONDATE] DEFAULT (getdate()) NOT NULL,
    [STMTDATE]        SMALLDATETIME   NULL,
    [BK_UNIQ]         CHAR (10)       CONSTRAINT [DF__BKRECON__BK_UNIQ__6497E884] DEFAULT ('') NOT NULL,
    [StmtTotalDep]    NUMERIC (12, 2) CONSTRAINT [DF_BKRECON_StmtTotalDep] DEFAULT ((0)) NOT NULL,
    [StmtWithdrawl]   NUMERIC (12, 2) CONSTRAINT [DF_BKRECON_StmtWithdrawl] DEFAULT ((0)) NOT NULL,
    [SVCCHGS]         NUMERIC (7, 2)  CONSTRAINT [DF__BKRECON__SVCCHGS__6774552F] DEFAULT ((0)) NOT NULL,
    [INTEARNED]       NUMERIC (7, 2)  CONSTRAINT [DF__BKRECON__INTEARN__68687968] DEFAULT ((0)) NOT NULL,
    [RECONSTATUS]     CHAR (10)       CONSTRAINT [DF__BKRECON__RECONST__6B44E613] DEFAULT ('') NOT NULL,
    [RECONNOTE]       TEXT            CONSTRAINT [DF__BKRECON__RECONNO__6C390A4C] DEFAULT ('') NOT NULL,
    [INIT]            CHAR (8)        CONSTRAINT [DF__BKRECON__INIT__70099B30] DEFAULT ('') NOT NULL,
    [EDITDT]          SMALLDATETIME   NULL,
    [EDITHIST]        TEXT            CONSTRAINT [DF__BKRECON__EDITHIS__70FDBF69] DEFAULT ('') NOT NULL,
    [EDITREASON]      CHAR (25)       CONSTRAINT [DF__BKRECON__EDITREA__71F1E3A2] DEFAULT ('') NOT NULL,
    [ThisStmtBalance] NUMERIC (12, 2) CONSTRAINT [DF__BKRECON__BANK_BA__72E607DB] DEFAULT ((0)) NOT NULL,
    [DEPCORR]         NUMERIC (12, 2) CONSTRAINT [DF__BKRECON__DEPCORR__74CE504D] DEFAULT ((0)) NOT NULL,
    [DEPNOTE]         TEXT            CONSTRAINT [DF__BKRECON__DEPNOTE__75C27486] DEFAULT ('') NOT NULL,
    [WITHDRCORR]      NUMERIC (12, 2) CONSTRAINT [DF__BKRECON__CHKCORR__76B698BF] DEFAULT ((0)) NOT NULL,
    [WITHDRNOTE]      TEXT            CONSTRAINT [DF__BKRECON__CHKNOTE__77AABCF8] DEFAULT ('') NOT NULL,
    [LASTSTMBAL]      NUMERIC (12, 2) CONSTRAINT [DF__BKRECON__LASTSTM__7B7B4DDC] DEFAULT ((0)) NOT NULL,
    [LASTSTMTDT]      SMALLDATETIME   NULL,
    CONSTRAINT [BKRECON_PK] PRIMARY KEY CLUSTERED ([RECONUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BK_UNIQ]
    ON [dbo].[BKRECON]([BK_UNIQ] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/06/2014
-- Description:	Update trigger. if bank statement date is changed ned to check if any of the transactions were made after the statement date.
-- =============================================
CREATE TRIGGER BkRecon_Update
   ON BkRecon
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    -- update all tables with 'reconciledate' column
	--APCHKMST            
	--ARCREDIT            
	--ARRETDET            
	--GLJEDET     
	UPDATE APCHKMST SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' FROM DELETED INNER JOIN Inserted ON deleted.RECONUNIQ =inserted.reconuniq  
					WHERE Apchkmst.ReconUniq =Deleted.RECONUNIQ and Deleted.STMTDATE<>Inserted.STMTDATE and DATEDIFF(day,Inserted.STMTDATE,ApChkMst.CheckDate) >=0           
	
	UPDATE ARCREDIT SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' FROM DELETED INNER JOIN Inserted ON deleted.RECONUNIQ =inserted.reconuniq 
					INNER JOIN ARCREDIT ON ARCREDIT.ReconUniq =Deleted.RECONUNIQ 
					INNER JOIN Deposits ON Deposits.DEP_NO =Arcredit.DEP_NO  
					WHERE Deleted.STMTDATE<>Inserted.STMTDATE 
					and DATEDIFF(day,Inserted.STMTDATE,Deposits.[Date]) >=0 

					
	           
	UPDATE ARRETDET SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' FROM DELETED INNER JOIN Inserted ON deleted.RECONUNIQ =inserted.reconuniq 
					INNER JOIN ARRETDET ON ARRETDET.ReconUniq =Deleted.RECONUNIQ 
					INNER JOIN ARRETCK  ON ARRETCK.UNIQRETNO=Arretdet.UNIQRETNO   
						WHERE Deleted.STMTDATE<>Inserted.STMTDATE 
					and DATEDIFF(day,Inserted.STMTDATE,ARRETCK.RET_DATE) >=0 
	
	           
	UPDATE GLJEDET  SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' FROM DELETED INNER JOIN Inserted ON deleted.RECONUNIQ =inserted.reconuniq 
					INNER JOIN GLJEDET ON GLJEDET.ReconUniq=Deleted.RECONUNIQ 
					INNER JOIN gljehdr ON gljehdr.uniqjehead = gljedet.uniqjehead 
				WHERE Deleted.STMTDATE<>Inserted.STMTDATE 
					and DATEDIFF(day,Inserted.STMTDATE,GlJeHdr.TRANSDATE ) >=0 
	                  
	

END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/06/2014
-- Description:	Delete trigger. When data is removed from the bank reconciliation table clear all the dates and flags in the transaction tables
-- =============================================
CREATE TRIGGER BkRecon_Delete
   ON BkRecon
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    -- update all tables with 'reconciledate' column
	--APCHKMST            
	--ARCREDIT            
	--ARRETDET            
	--GLJEDET     
	UPDATE APCHKMST SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' WHERE Apchkmst.ReconUniq IN (SELECT Reconuniq from deleted)             
	UPDATE ARCREDIT SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' WHERE ARCREDIT.ReconUniq IN (SELECT Reconuniq from deleted)           
	UPDATE ARRETDET SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' WHERE ARRETDET.ReconUniq IN (SELECT Reconuniq from deleted)            
	UPDATE GLJEDET  SET ReconcileDate=null,ReconcileStatus=' ',ReconUniq=' ' WHERE GLJEDET.ReconUniq IN (SELECT Reconuniq from deleted)                    
	

END