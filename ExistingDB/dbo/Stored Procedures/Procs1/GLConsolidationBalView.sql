-- =============================================
-- Author:		<Nilesh Sa>
-- Create date: <27/12/2017>
-- Description:	View for the GL Consolidation For Balance sheet
-- exec [dbo].[GLConsolidationBalView] 'Monthly/Period','2016','10'
-- Nilesh Sa 1/5/2018 No need of parameter
-- Nilesh Sa 1/5/2018 Rename the parameter @StartSequenceNumber to @SequenceNumber
-- Nilesh Sa 1/8/2018 Avoid description here grouping issue occures
-- Nilesh Sa 1/8/2018 Created temp table and Added outer apply to display description
-- Nilesh Sa 1/8/2018 set Description as null for grouping issue occures
-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter
-- =============================================
CREATE PROCEDURE [dbo].[GLConsolidationBalView]
	--DECLARE
	--@SequenceNumber INT = 0, -- Nilesh Sa 1/5/2018 Rename the parameter @StartSequenceNumber to @SequenceNumber
	--@StartPeriod NUMERIC(2,0) = 0,
	----@EndSequenceNumber INT = 0, -- Nilesh Sa 1/5/2018 No need of @EndSequenceNumber parameter
	--@EndPeriod NUMERIC(2,0) = 0 
	-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter
	 @viewBy VARCHAR(MAX) ='Monthly/Period',
	 @fiscalYear CHAR(4)='',
	 @period NUMERIC(2,0)=0,
	 @quarter NUMERIC(1,0)=0
AS
BEGIN
 SET NOCOUNT ON;
	DECLARE @GLBal AS TABLE (AccountNumber CHAR(7),GL_DESCRIPT CHAR(30) ,Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),gl_descr char(30),
	gl_class char(7),gl_nbr char(13),End_Bal numeric(14,2),Beg_BalPR numeric(14,2), End_BalPR numeric(14,2))

	DECLARE @groupedAccountList AS TABLE(AccountNumber NVARCHAR(MAX),GL_DESCR CHAR(30),End_Bal NUMERIC(14,2)) -- Nilesh Sa 1/8/2018 Created temp table and Added outer apply to display description

	-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter
	DECLARE @SequenceNumber AS INT,@StartPeriod AS NUMERIC(2,0),@EndPeriod AS NUMERIC(2,0),@FyUniq AS CHAR(10)

	-- Get fiscal year record
	SELECT @FyUniq= FY_UNIQ, @SequenceNumber=sequenceNumber FROM GLFISCALYRS WHERE FISCALYR= @fiscalYear

	IF @viewBy = 'Yearly'
	  BEGIN
		SELECT TOP 1 @StartPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq ORDER BY PERIOD -- SELECT First Period
		SELECT TOP 1 @EndPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq ORDER BY PERIOD DESC -- SELECT Last Period
	  END
    ELSE IF @viewBy ='Quarterly'
	  BEGIN
	    SELECT TOP 1 @StartPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq AND nQtr = @quarter ORDER BY PERIOD -- SELECT First Period
		SELECT TOP 1 @EndPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq AND nQtr = @quarter ORDER BY PERIOD DESC -- SELECT Last Period
	  END
    ELSE
	  BEGIN
	    SELECT TOP 1 @EndPeriod =PERIOD, @StartPeriod = PERIOD FROM GLFYRSDETL WHERE FK_FY_UNIQ= @FyUniq AND PERIOD= @period -- SELECT First & last Period
	  END
	-- Nilesh Sa 2/1/2018 Change in implementation based on year,month and quarter added following new parameter

	Insert @GLBal
	SELECT 
	DBO.PADL(RTRIM(CAST(gl_acct.gl_nbr AS CHAR(7))),7,'0') AS AccountNumber,Gl_nbrs.GL_DESCR AS GL_DESCRIPT,
	TOT_START,TOT_END,NORM_BAL,GL_DESCR,gl_nbrs.GL_CLASS,GL_NBRS.GL_NBR,gl_Acct.End_Bal,gl_Acct.BEG_BALPR,gl_Acct.END_BALPR
	FROM gl_acct 
	INNER JOIN GL_NBRS ON Gl_acct.gl_nbr=Gl_nbrs.gl_nbr AND gl_nbrs.STMT ='BAL'
	INNER JOIN GLTYPES ON GL_NBRS.GLTYPE =GLTYPEs.GLTYPE 
	INNER JOIN glFyrsDetl ON gl_acct.fk_fydtluniq=glFyrsDetl.FyDtlUniq 
	INNER JOIN glFiscalyrs ON  glFyrsDetl.fk_fy_uniq=glFiscalyrs.Fy_uniq AND GLFISCALYRS.sequenceNumber = @SequenceNumber -- Nilesh Sa 1/5/2018 Rename the parameter @StartSequenceNumber to @SequenceNumber
	LEFT OUTER JOIN Fcused PF ON GL_ACCT.PrFcused_uniq = PF.Fcused_uniq	
	LEFT OUTER JOIN Fcused FF ON GL_ACCT.FuncFcused_uniq = FF.Fcused_uniq
	WHERE 
	DBO.PADL(RTRIM(CAST(Period as CHAR(2))),2,'0')
	BETWEEN  DBO.PADL(RTRIM(CAST(@StartPeriod AS CHAR(2))),2,'0')
	AND DBO.PADL(RTRIM(CAST(@EndPeriod AS CHAR(2))),2,'0')
	
	--The below section should calculate the Ending Balance for the Closing Account
	;with closingAccountDr as
				(
				SELECT	SUM(END_BAL) AS TotAmt,SUM(END_BALPR) AS TotAmtPR
				from	@GLBal as A  
				where	Norm_Bal = 'DR'
				)
	,
	closingAccountCr as
				(			
				Select	SUM(end_bal) as TotAmt,SUM(End_BalPR) as TotAmtPR
				from	@GLBal as B
				where Norm_Bal = 'CR'	
				)
			
	--This section is taking the calculated Ending Balance for the Closing Account and updating it into the Delcared table above
	--note that if the Norm_Bal = CR then the value will be reversed on the Balance Sheet report			
	update @GLBal set End_Bal = -(isnull(closingAccountDr.totAmt,0.00) + isnull(closingAccountCr.totamt,0.00)),
	End_BalPR = -(isnull(closingAccountDr.totAmtPR,0.00) + isnull(closingAccountCr.totamtPR,0.00)) 
	from closingAccountDr,closingAccountCr,glsys where gl_class = 'Closing' and gl_nbr = glsys.CUR_EARN


	--This section below is calculating the total by gltype
	;with
	totalByGlTypeCr as
				(				
				select	GL_NBR,tot_start,Tot_end
				from	@GLBal as C 
				where	gl_class = 'Total'
				)
	,
	totalByGlTypeDr2 as
				(
				select	totalByGlTypeCr.gl_nbr,SUM(end_bal) as TotAmtDr,SUM(end_balPR) as TotAmtDrPR
				from	@GLBal as D,totalByGlTypeCr
				where	Norm_Bal = 'DR'
						and D.gl_nbr between totalByGlTypeCr.tot_start and totalByGlTypeCr.tot_end
						and gl_class <> 'Total'
				GROUP BY totalByGlTypeCr.gl_nbr		
				)	
			
				,
	totalByGlTypeCr2 as
				(
				select	totalByGlTypeCr.gl_nbr,SUM(end_bal) as TotAmtCr,SUM(end_balPR) as TotAmtCrPR
				from	@GLBal as E,totalByGlTypeCr
				where	Norm_Bal = 'CR'
						and E.gl_nbr between totalByGlTypeCr.Tot_Start and totalByGlTypeCr.Tot_End
						and gl_class <> 'Total'
				GROUP BY totalByGlTypeCr.gl_nbr		
				)

				--This section is taking the calculated Ending Balance per the GLType			
	-- Note that if the Norm_bal = CR the value will be reversed on the Balance Sheet report.
	update @GLBal set End_bal = ISNULL(totalByGlTypeDr2.totamtdr,0.00)+ISNULL(totalByGlTypeCr2.totamtcr,0.00),End_balPR = ISNULL(totalByGlTypeDr2.totamtdrPR,0.00)+ISNULL(totalByGlTypeCr2.totamtcrPR,0.00)  
	 FROM totalByGlTypeCr LEFT OUTER JOIN  totalByGlTypeDr2 ON totalByGlTypeCr.gl_nbr=totalByGlTypeDr2.gl_nbr
	LEFT OUTER JOIN totalByGlTypeCr2 on totalByGlTypeCr.gl_nbr=totalByGlTypeCr2.gl_nbr 
	INNER JOIN @GLBal as F on totalByGlTypeCr.GL_NBR=F.gl_nbr 


	INSERT INTO @groupedAccountList
	SELECT AccountNumber,NUll AS GL_DESCR ,SUM(END_BAL) As END_BAL   -- Nilesh Sa 1/8/2018 set Description as null for grouping issue occures
	FROM(
		  SELECT DBO.PADL(RTRIM(CAST(gl_nbr AS CHAR(7))),7,'0') as AccountNumber,gl_descr,
				 CASE WHEN Norm_Bal = 'DR' THEN End_Bal ELSE -End_Bal END AS End_Bal
				 FROM @GLBal
	) Accounts 
	--OUTER APPLY(SELECT TOP 1 * FROM GL_NBRS g1 WHERE g1.GL_NBR = CONCAT(Accounts.AccountNumber,'-','00','-','00')) GL_NBRS_Desc -- Get the description of 00-00  accounts
	GROUP BY AccountNumber--,ISNULL(GL_NBRS_Desc.GL_DESCR,GL_NBRS_Desc.GL_DESCR)  -- Nilesh Sa 1/8/2018 Avoid description here grouping issue occures

	 -- Nilesh Sa 1/8/2018 Created temp table and Added outer apply to display description
	 UPDATE @groupedAccountList
	 SET  GL_DESCR = Descrption.GL_DESCR
	 FROM @groupedAccountList  
	 OUTER APPLY (SELECT Top 1 GL_DESCR FROM GL_NBRS  WHERE GL_NBR like '%'+ AccountNumber +'%' order by GL_NBR)  AS Descrption  
 
	 SELECT * FROM @groupedAccountList ORDER BY AccountNumber
END