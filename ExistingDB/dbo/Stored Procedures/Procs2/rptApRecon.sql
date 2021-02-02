-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/19/2015
-- Description:	AP Reconciliation report (APAGING tag) (VFP report form ApRecon)
-- Modification:
-- 02/06/17 VL Added functional currency code and separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[rptApRecon]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
-- 02/06/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
		--- AP
		declare @tReportApRecon Table (UniqApHead char(10), SupName varchar(50), BalAmt numeric(12,2), Due_Date smalldatetime, InvNo varchar(20), 
			InvDate smalldatetime, InvAmount numeric(12,2), Phone varchar(30), Terms char(15),Trans_dt smalldatetime, TotalCost numeric(12,2), 
			Ponum char(15), nRelGL numeric(12,2),nNotRelGl numeric(12,2),nNotRelCks numeric(12,2),is_rel_gl bit)
	
		-- get ap items with balance and no prepay or items with 0 balance but not released
		INSERT INTO @tReportApRecon (UniqApHead , SupName , BalAmt, Due_Date , InvNo , 
			InvDate , InvAmount , Phone , Terms ,Trans_dt , TotalCost , 
			Ponum , nRelGL ,nNotRelGl ,nNotRelCks ,is_rel_gl)
		SELECT ApMaster.UniqApHead, SupInfo.SupName, InvAmount - ApPmts - Disc_Tkn AS BalAmt, Due_Date, InvNo, 
			InvDate, InvAmount, Phone, ApMaster.Terms,ApMaster.Trans_dt, cast(0.00 as numeric(12,2)) as TotalCost, 
			Ponum, 
			CASE WHEN ApMaster.is_rel_gl=1 THEN InvAmount - ApPmts - Disc_Tkn ELSE cast(0.00 as numeric(12,2)) END as nRelGL, 
			CASE WHEN ApMaster.is_rel_gl=0 THEN InvAmount ELSE cast(0.00 as numeric(12,2)) END  as nNotRelGl, 
			cast(0.00 as numeric(12,2)) AS nNotRelCks ,is_rel_gl
			FROM ApMaster INNER JOIN SupInfo ON SupInfo.UniqSupNo = ApMaster.UniqSupNo 
			-- where balance and not prepay or balance paid but not released to gl
			WHERE (((InvAmount - ApPmts - Disc_Tkn) <> 0.00 AND Apmaster.lPrepay=0) OR (InvAmount - ApPmts - Disc_Tkn) = 0.00 and is_rel_gl=0)
			AND ApStatus <> 'Deleted' 

		--select * from @treportApRecon

		-- checks
		MERGE @tReportApRecon AS t 
		USING (SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
			ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
			ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
			ApChkmst.CheckDate as Trans_dt,  ApMaster.Ponum, cast(0.00 as numeric(12,2)) as nRelGL ,
			cast(0.00 as numeric(12,2)) as nNotRelGl,
			Apchkdet.Aprpay + ApchkDet.Disc_tkn as nNotRelCks,ApChkmst.IS_REL_GL
			FROM ApMaster INNER JOIN APCHKDET ON ApMaster.UniqApHead = Apchkdet.UniqApHead
			INNER JOIN APCHKMST ON  ApchkDet.ApChk_Uniq = ApchkMst.ApChk_Uniq
			INNER JOIN SupInfo ON SupInfo.UniqSupNo = ApchkMst.UniqSupNo 
			INNER JOIN Apsetup ON Apsetup.AP_GL_NO=ApchkDet.GL_NBR 
			WHERE ApchkMst.Status <> 'Void'
				AND YEAR(ApMaster.Due_Date) > 2001  
				AND ApChkMst.Is_Rel_Gl =0
			UNION ALL	
			SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
			ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
			ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
			ApChkmst.CheckDate as Trans_dt,  ApMaster.Ponum, cast(0.00 as numeric(12,2)) as nRelGL ,
			cast(0.00 as numeric(12,2)) as nNotRelGl,
			Apchkdet.Aprpay + ApchkDet.Disc_tkn as nNotRelCks,ApChkmst.IS_REL_GL
			FROM ApMaster INNER JOIN APCHKDET ON ApMaster.UniqApHead = Apchkdet.UniqApHead
			INNER JOIN APCHKMST ON  ApchkDet.ApChk_Uniq = ApchkMst.ApChk_Uniq
			INNER JOIN SupInfo ON SupInfo.UniqSupNo = ApchkMst.UniqSupNo 
			INNER JOIN Apsetup ON Apsetup.AP_GL_NO=ApchkDet.GL_NBR 
			inner join GLRELEASED on GLRELEASED.cSubDrill=apchkdet.APCKD_UNIQ 
			and Apsetup.AP_GL_NO=GLRELEASED.GL_NBR
			and glreleased.TransactionType='CHECKS' 
			WHERE ApchkMst.Status <> 'Void'
			and Glreleased.SourceTable='APCHKMST' and glreleased.SourceSubTable = 'APCHKDET' and cSubIdentifier='APCKD_UNIQ'
			) AS S  ON (S.uniqaphead=T.uniqAphead)
			WHEN MATCHED THEN UPDATE SET T.nNotRelCks = T.nNotRelCks + S.nNotRelCks
			WHEN NOT MATCHED BY TARGET THEN
			INSERT (UniqApHead , SupName , BalAmt, Due_Date , InvNo , 
				InvDate , InvAmount , Phone , Terms ,Trans_dt ,  
				Ponum , nRelGL ,nNotRelGl ,nNotRelCks ,is_rel_gl) VALUES 
				(s.uniqaphead,s.supname,s.BalAmt, s.Due_Date , s.InvNo , 
				s.InvDate , s.InvAmount , s.Phone , s.Terms ,s.Trans_dt ,  
				s.Ponum , s.nRelGL ,s.nNotRelGl ,s.nNotRelCks ,s.is_rel_gl) ;


		--select * from @tReportApRecon

		-- debit memos	
		MERGE @tReportApRecon AS t 
		USING
		(
		SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
			ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
			ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
			dmemos.DMDATE as Trans_dt,  ApMaster.Ponum, 
			DmTotal as nNotRelCks,dmemos.is_rel_gl
			FROM ApMaster INNER JOIN Dmemos ON ApMaster.UniqApHead = Dmemos.UniqApHead 
			INNER JOIN SupInfo ON SupInfo.UniqSupNo = Dmemos.UniqSupNo
			WHERE Dmemos.DmStatus = 'Posted to AP'
			AND  dmemos.IS_REL_GL =0
		UNION
		-- Now Get the DM's that have been released, but not posted
		SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
		ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
		ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
		Dmemos.DMDATE as Trans_dt,  ApMaster.Ponum, 
		GLRELEASED.Debit as nNotRelCks,Dmemos.Is_rel_gl
		FROM ApMaster INNER JOIN  SupInfo ON SupInfo.UniqSupNo = ApMaster.UniqSupNo
		INNER JOIN Dmemos on Apmaster.uniqaphead=dmemos.uniqaphead
		INNER JOIN GLRELEASED ON GLRELEASED.cSubDrill=Dmemos.uniqdmhead
		WHERE GlReleased.transactiontype='DM' and Glreleased.SourceTable='DMEMOS' and glreleased.SourceSubTable = 'DMEMOS' and cSubIdentifier='UniqDmHead') S
		ON (S.uniqaphead=T.uniqAphead)
		WHEN MATCHED THEN UPDATE SET T.nNotRelCks = T.nNotRelCks + S.nNotRelCks
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (UniqApHead , SupName , BalAmt, Due_Date , InvNo , 
			InvDate , InvAmount , Phone , Terms ,Trans_dt ,  
			Ponum , nNotRelCks ,is_rel_gl) VALUES 
			(s.uniqaphead,s.supname,s.BalAmt, s.Due_Date , s.InvNo , 
			s.InvDate , s.InvAmount , s.Phone , s.Terms ,s.Trans_dt ,  
			s.Ponum , s.nNotRelCks ,s.is_rel_gl) ;

		select * from @tReportApRecon ORDER BY Trans_dt
	END
ELSE
	BEGIN
		--- AP
		declare @tReportApReconFC Table (UniqApHead char(10), SupName varchar(50), BalAmt numeric(12,2), Due_Date smalldatetime, InvNo varchar(20), 
			InvDate smalldatetime, InvAmount numeric(12,2), Phone varchar(30), Terms char(15),Trans_dt smalldatetime, TotalCost numeric(12,2), 
			Ponum char(15), nRelGL numeric(12,2),nNotRelGl numeric(12,2),nNotRelCks numeric(12,2),is_rel_gl bit,
			-- 02/06/17 VL added functional currency code
			BalAmtPR numeric(12,2), InvAmountPR numeric(12,2),TotalCostPR numeric(12,2),
			nRelGLPR numeric(12,2),nNotRelGlPR numeric(12,2),nNotRelCksPR numeric(12,2),
			TSymbol char(3), PSymbol char(3), FSymbol char(3))
	
		-- get ap items with balance and no prepay or items with 0 balance but not released
		INSERT INTO @tReportApReconFC (UniqApHead , SupName , BalAmt, Due_Date , InvNo , 
			InvDate , InvAmount , Phone , Terms ,Trans_dt , TotalCost , 
			Ponum , nRelGL ,nNotRelGl ,nNotRelCks ,is_rel_gl,
			-- 02/06/17 VL added functional currency code
			BalAmtPR, InvAmountPR, TotalCostPR, nRelGLPR, nNotRelGlPR, nNotRelCksPR, TSymbol, PSymbol, FSymbol)
		SELECT ApMaster.UniqApHead, SupInfo.SupName, InvAmount - ApPmts - Disc_Tkn AS BalAmt, Due_Date, InvNo, 
			InvDate, InvAmount, Phone, ApMaster.Terms,ApMaster.Trans_dt, cast(0.00 as numeric(12,2)) as TotalCost, 
			Ponum, 
			CASE WHEN ApMaster.is_rel_gl=1 THEN InvAmount - ApPmts - Disc_Tkn ELSE cast(0.00 as numeric(12,2)) END as nRelGL, 
			CASE WHEN ApMaster.is_rel_gl=0 THEN InvAmount ELSE cast(0.00 as numeric(12,2)) END  as nNotRelGl, 
			cast(0.00 as numeric(12,2)) AS nNotRelCks ,is_rel_gl,
			-- 02/06/17 VL added functional currency code
			InvAmountPR - ApPmtsPR - Disc_TknPR AS BalAmtPR, InvAmountPR, cast(0.00 as numeric(12,2)) as TotalCostPR,
			CASE WHEN ApMaster.is_rel_gl=1 THEN InvAmountPR - ApPmtsPR - Disc_TknPR ELSE cast(0.00 as numeric(12,2)) END as nRelGLPR, 
			CASE WHEN ApMaster.is_rel_gl=0 THEN InvAmountPR ELSE cast(0.00 as numeric(12,2)) END  as nNotRelGlPR, 
			cast(0.00 as numeric(12,2)) AS nNotRelCksPR,
			TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM ApMaster 
			-- 02/06/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON ApMaster.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ApMaster.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON ApMaster.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN SupInfo ON SupInfo.UniqSupNo = ApMaster.UniqSupNo 
			-- where balance and not prepay or balance paid but not released to gl
			WHERE (((InvAmount - ApPmts - Disc_Tkn) <> 0.00 AND Apmaster.lPrepay=0) OR (InvAmount - ApPmts - Disc_Tkn) = 0.00 and is_rel_gl=0)
			AND ApStatus <> 'Deleted' 

		--select * from @treportApRecon

		-- checks
		MERGE @tReportApReconFC AS t 
		USING (SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
			ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
			ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
			ApChkmst.CheckDate as Trans_dt,  ApMaster.Ponum, cast(0.00 as numeric(12,2)) as nRelGL ,
			cast(0.00 as numeric(12,2)) as nNotRelGl,
			Apchkdet.Aprpay + ApchkDet.Disc_tkn as nNotRelCks,ApChkmst.IS_REL_GL,
			-- 02/06/17 VL added functional currency code
			ApMaster.InvAmountPR - ApMaster.ApPmtsPR - ApMaster.Disc_tknPR AS BalAmtPR,
			ApMaster.InvAmountPR,cast(0.00 as numeric(12,2)) as nRelGLPR ,
			cast(0.00 as numeric(12,2)) as nNotRelGlPR,
			Apchkdet.AprpayPR + ApchkDet.Disc_tknPR as nNotRelCksPR,
			TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM ApMaster 
			-- 02/06/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON ApMaster.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ApMaster.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON ApMaster.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN APCHKDET ON ApMaster.UniqApHead = Apchkdet.UniqApHead
			INNER JOIN APCHKMST ON  ApchkDet.ApChk_Uniq = ApchkMst.ApChk_Uniq
			INNER JOIN SupInfo ON SupInfo.UniqSupNo = ApchkMst.UniqSupNo 
			INNER JOIN Apsetup ON Apsetup.AP_GL_NO=ApchkDet.GL_NBR 
			WHERE ApchkMst.Status <> 'Void'
				AND YEAR(ApMaster.Due_Date) > 2001  
				AND ApChkMst.Is_Rel_Gl =0
			UNION ALL	
			SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
			ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
			ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
			ApChkmst.CheckDate as Trans_dt,  ApMaster.Ponum, cast(0.00 as numeric(12,2)) as nRelGL ,
			cast(0.00 as numeric(12,2)) as nNotRelGl,
			Apchkdet.Aprpay + ApchkDet.Disc_tkn as nNotRelCks,ApChkmst.IS_REL_GL,
			-- 02/06/17 VL added functional currency code
			ApMaster.InvAmountPR - ApMaster.ApPmtsPR - ApMaster.Disc_tknPR AS BalAmtPR,
			ApMaster.InvAmountPR,cast(0.00 as numeric(12,2)) as nRelGLPR ,
			cast(0.00 as numeric(12,2)) as nNotRelGlPR,
			Apchkdet.AprpayPR + ApchkDet.Disc_tknPR as nNotRelCksPR,
			TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM ApMaster 
			-- 02/06/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON ApMaster.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ApMaster.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON ApMaster.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN APCHKDET ON ApMaster.UniqApHead = Apchkdet.UniqApHead
			INNER JOIN APCHKMST ON  ApchkDet.ApChk_Uniq = ApchkMst.ApChk_Uniq
			INNER JOIN SupInfo ON SupInfo.UniqSupNo = ApchkMst.UniqSupNo 
			INNER JOIN Apsetup ON Apsetup.AP_GL_NO=ApchkDet.GL_NBR 
			inner join GLRELEASED on GLRELEASED.cSubDrill=apchkdet.APCKD_UNIQ 
			and Apsetup.AP_GL_NO=GLRELEASED.GL_NBR
			and glreleased.TransactionType='CHECKS' 
			WHERE ApchkMst.Status <> 'Void'
			and Glreleased.SourceTable='APCHKMST' and glreleased.SourceSubTable = 'APCHKDET' and cSubIdentifier='APCKD_UNIQ'
			) AS S  ON (S.uniqaphead=T.uniqAphead)
			WHEN MATCHED THEN UPDATE SET T.nNotRelCks = T.nNotRelCks + S.nNotRelCks
			WHEN NOT MATCHED BY TARGET THEN
			-- 02/06/17 VL added functional currency code
			INSERT (UniqApHead , SupName , BalAmt, Due_Date , InvNo , 
				InvDate , InvAmount , Phone , Terms ,Trans_dt ,  
				Ponum , nRelGL ,nNotRelGl ,nNotRelCks ,is_rel_gl,
				BalAmtPR, InvAmountPR, nRelGLPR ,nNotRelGlPR ,nNotRelCksPR,TSymbol, PSymbol, FSymbol) VALUES 
				(s.uniqaphead,s.supname,s.BalAmt, s.Due_Date , s.InvNo , 
				s.InvDate , s.InvAmount , s.Phone , s.Terms ,s.Trans_dt ,  
				s.Ponum , s.nRelGL ,s.nNotRelGl ,s.nNotRelCks ,s.is_rel_gl,
				s.BalAmtPR, s.InvAmountPR, s.nRelGLPR ,s.nNotRelGlPR ,s.nNotRelCksPR,s.TSymbol, s.PSymbol, s.FSymbol) ;


		--select * from @tReportApRecon

		-- debit memos	
		MERGE @tReportApReconFC AS t 
		USING
		(
		SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
			ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
			ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
			dmemos.DMDATE as Trans_dt,  ApMaster.Ponum, 
			DmTotal as nNotRelCks,dmemos.is_rel_gl,
			-- 02/06/17 VL added functional currency code
			ApMaster.InvAmountPR - ApMaster.ApPmtsPR - ApMaster.Disc_tknPR AS BalAmtPR,
			ApMaster.InvAmountPR, DmTotalPR as nNotRelCksPR, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM ApMaster 
			-- 02/06/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON ApMaster.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ApMaster.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON ApMaster.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN Dmemos ON ApMaster.UniqApHead = Dmemos.UniqApHead 
			INNER JOIN SupInfo ON SupInfo.UniqSupNo = Dmemos.UniqSupNo
			WHERE Dmemos.DmStatus = 'Posted to AP'
			AND  dmemos.IS_REL_GL =0
		UNION
		-- Now Get the DM's that have been released, but not posted
		SELECT ApMaster.UniqSupNo, SupINfo.SupName, Phone,ApMaster.UniqApHead, 
		ApMaster.InvAmount - ApMaster.ApPmts - ApMaster.Disc_tkn AS BalAmt, 
		ApMaster.Due_date, ApMaster.InvNo, 	ApMaster.InvDate, ApMaster.InvAmount, ApMaster.Terms, 
		Dmemos.DMDATE as Trans_dt,  ApMaster.Ponum, 
		GLRELEASED.Debit as nNotRelCks,Dmemos.Is_rel_gl,
		-- 02/06/17 VL added functional currency code
		ApMaster.InvAmountPR - ApMaster.ApPmtsPR - ApMaster.Disc_tknPR AS BalAmtPR,
		ApMaster.InvAmountPR, GLRELEASED.DebitPR as nNotRelCksPR,
		TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
		FROM ApMaster 
		-- 02/06/17 VL changed criteria to get 3 currencies
		INNER JOIN Fcused PF ON ApMaster.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON ApMaster.FuncFcused_uniq = FF.Fcused_uniq			
		INNER JOIN Fcused TF ON ApMaster.Fcused_uniq = TF.Fcused_uniq			
		INNER JOIN  SupInfo ON SupInfo.UniqSupNo = ApMaster.UniqSupNo
		INNER JOIN Dmemos on Apmaster.uniqaphead=dmemos.uniqaphead
		INNER JOIN GLRELEASED ON GLRELEASED.cSubDrill=Dmemos.uniqdmhead
		WHERE GlReleased.transactiontype='DM' and Glreleased.SourceTable='DMEMOS' and glreleased.SourceSubTable = 'DMEMOS' and cSubIdentifier='UniqDmHead') S
		ON (S.uniqaphead=T.uniqAphead)
		WHEN MATCHED THEN UPDATE SET T.nNotRelCks = T.nNotRelCks + S.nNotRelCks
		WHEN NOT MATCHED BY TARGET THEN
		-- 02/06/17 VL added functional currency code
		INSERT (UniqApHead , SupName , BalAmt, Due_Date , InvNo , 
			InvDate , InvAmount , Phone , Terms ,Trans_dt ,  
			Ponum , nNotRelCks ,is_rel_gl,
			BalAmtPR, InvAmountPR, nNotRelCksPR, TSymbol, PSymbol, FSymbol) VALUES 
			(s.uniqaphead,s.supname,s.BalAmt, s.Due_Date , s.InvNo , 
			s.InvDate , s.InvAmount , s.Phone , s.Terms ,s.Trans_dt ,  
			s.Ponum , s.nNotRelCks ,s.is_rel_gl,
			s.BalAmtPR, s.InvAmountPR, s.nNotRelCksPR, s.TSymbol, s.PSymbol, s.FSymbol) ;

		select * from @tReportApReconFC ORDER BY Trans_dt
	END
END