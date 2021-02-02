
-- =============================================
-- Author:		Debbie
-- Create date: 06/01/2012
-- Description:	Created for the Balance Sheet ~ Prior/Current Comparative
-- Reports Using Stored Procedure:  glbalsh3.rpt
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
-- 12/10/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter
-- 05/05/2015 DPR:  Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division.
--			   replaced the @lcShowAll = 'No' and @lcShowAll = 'Yes' sections with a different select statement so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
-- 06/23/15 YS added sequencenumber to fiscalyer table
-- 04/07/17 DRP:  If a GL number was recently added and did not exist in the prior year it would fall off of the report
-- 05/02/17 DRP:  Added Functional Currency Changes.
-- =============================================
CREATE PROCEDURE [dbo].[rptGlBalSheetPriorCurr]
--declare
		 @lcFy as char(4) = ''
		,@lcPer as int = ''
		,@lcShowAll as char(3) = 'No'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division.  
		,@userId uniqueidentifier=null

as
begin		
--This table will be used to compile the Prior Year Balance values
declare @PBal as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),gl_class char(7),gl_nbr char(13),PriorAmt numeric(14,2),FSymbol char(3)
						,PriorFY char(4),PriorPeriod numeric(2),PriorEndDate smalldatetime,PriorAmtPR numeric(14,2),PSymbol char(3))


----This table will be used to compile the Select Fiscal Year and Period Balance information
declare @GLBal as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13),Beg_Bal numeric(14,2)
						,Debit numeric(14,2), credit numeric (14,2),End_Bal numeric(14,2),FSymbol char(3)
						,LONG_DESCR char(52),glTypeDesc char(20),FiscalYear char(4),Period numeric(2),EndDate smalldatetime,IsClosed bit
						,Beg_BalPR numeric(14,2),DebitPR numeric(14,2),creditPR numeric (14,2),End_BalPR numeric(14,2),PSymbol char(3))
						
						

--***PRIOR PERIOD***--						
	--Declared the below table in order to get the true Prior Period/Fiscal Year based on what was selected
	--06/23/15 YS added sequencenumber to fiscalyer table
	declare @fyrs as table	(fk_fy_uniq char(10),FiscalYear char(4),Period numeric(2),fydtluniq uniqueidentifier,Pfk_fy_uniq char(10),PriorFy char(4)
							,PriorPeriod numeric (2),Pfydtluniq uniqueidentifier)
	--Below will insert into the above @fyrs table the FY and Period the user selected and the Prior Period and/or Fiscal Year.  
	--We had to do this in case they have 13 periods or if the entry is for the first Period of the FY
	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView 
	-- 06/23/15 ys do not need tSeql @T table already have sequence number
	;
	WITH tSeq 
		AS
		(
		select *,ROW_NUMBER() OVER (ORDER BY sequenceNumber,Period) as nSeq from @T
		)
		,
	
		zFys as(
		SELECT	t3.fk_fy_uniq,t3.FiscalYr,t3.Period,t3.fyDtlUniq
				,t2.fk_fy_uniq as Pfk_fy_uniq,t2.FiscalYr as PriorFY,t2.Period as PriorPeriod,t2.fyDtlUniq as Pfydtluniq
				FROM tSeq t2,tSeq t3
		WHERE t2.nSeq = (SELECT nseq-1 FROM tSeq t1 where t1.FiscalYr=@lcFy and t1.Period=@lcPer)
		and t3.nseq = (select nseq from tSeq t1 where t1.FiscalYr=@lcFy and t1.Period = @lcPer)
		)
	insert @fyrs select * from zFys	



-- 05/02/17 DRP added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
	
	--This will insert the data into the Prior Period Table based on the information that was populated into the @fyrs tables as for as the current and Prior Period
		Insert @PBal
		select	TOT_START,TOT_END,NORM_BAL,gl_nbrs.GL_CLASS,GL_NBRS.GL_NBR,gl_Acct.End_Bal,isnull(FF.Symbol,'') AS FSymbol,f1.PriorFy as FiscalYear,glfyrsdetl.period,GLFYRSDETL.EndDate,gl_Acct.End_BalPR,isnull(PF.Symbol,'') AS PSymbol
			
		from	GL_ACCT	
				left outer join GL_NBRS on gl_acct.GL_NBR = GL_NBRS.GL_NBR
				left outer join GLTYPES on GL_NBRS.GLTYPE = gltypes.GLTYPE
				inner join GLFYRSDETL on gl_acct.FK_FYDTLUNIQ = glfyrsdetl.FYDTLUNIQ
				inner join @fyrs as F1 on glfyrsdetl.FYDTLUNIQ = f1.Pfydtluniq 
				left outer JOIN Fcused PF ON GL_ACCT.PrFcused_uniq = PF.Fcused_uniq		--05/02/17 DRP:  added
				left outer JOIN Fcused FF ON GL_ACCT.FuncFcused_uniq = FF.Fcused_uniq	--05/02/17DRP:  added

		where	gl_nbrs.STMT = 'BAL'
		--06/23/15 YS optimize the "where" and remove "*"
		and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
				--	case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
		
			--The below section should calculate the Ending Balance for the Closing Account Selected Priod/Year		

				;
		with 
		zbstotdrP as
					(
					SELECT	SUM(PriorAmt) AS TotAmt,SUM(PriorAmtPR) AS TotAmtPR
					from	@Pbal as A  
					where	Norm_Bal = 'DR'
					)

		,
		zbstotcrP as
					(			
					Select	SUM(PriorAmt) as TotAmt,SUM(PriorAmtPR) as TotAmtPR
					from	@PBal as B
					where Norm_Bal = 'CR'
					)
		update @PBal set PriorAmt = -(isnull(zbstotdrP.totAmt,0.00) + isnull(zbstotcrP.totamt,0.00)),PriorAmtPR = -(isnull(zbstotdrP.TotAmtPR,0.00) + isnull(zbstotcrP.TotAmtPR,0.00)) from zbstotdrP,zbstotcrP,glsys where gl_class = 'Closing' and gl_nbr = glsys.CUR_EARN		
		
		
				--This section below is calculating the total by gltype
		;
		with
		ZGlTotalNbrsP as
					(				
					select	GL_NBR,tot_start,Tot_end
					from	@PBal as C 
					where	gl_class = 'Total'
					)
					,
		Zbstotdr2P as
					(
					select	ZGlTotalNbrsP.gl_nbr,SUM(PriorAmt) as TotAmtDr,SUM(PriorAmtPR) as TotAmtDrPR
					from	@PBal as D,ZGlTotalNbrsP
					where	Norm_Bal = 'DR'
							and D.gl_nbr between ZGlTotalNbrsP.tot_start and ZGlTotalNbrsP.tot_end
							and gl_class <> 'Total'
					GROUP BY ZGlTotalNbrsP.gl_nbr		
					)	
					,
		Zbstotcr2P as
					(
					select	ZGlTotalNbrsP.gl_nbr,SUM(PriorAmt) as TotAmtCr,SUM(PriorAmtPR) as TotAmtCrPR
					from	@PBal as E,ZGlTotalNbrsP
					where	Norm_Bal = 'CR'
							and E.gl_nbr between ZGlTotalNbrsP.Tot_Start and ZGlTotalNbrsP.Tot_End
							and gl_class <> 'Total'
					GROUP BY ZGlTotalNbrsP.gl_nbr		
					)
					
		--This section is taking the calculated Ending Balance per the GLType and update the table for the Prior FY/Period			
		-- Note that if the Norm_bal = CR the value will be reversed on the Balance Sheet report.			
		update @PBal set PriorAmt =ISNULL(zbstotdr2P.totamtdr,0.00)+ISNULL(zbstotcr2P.totamtcr,0.00),PriorAmtPR =ISNULL(zbstotdr2P.TotAmtDrPR,0.00)+ISNULL(zbstotcr2P.TotAmtCrPR,0.00) FROM ZGlTotalNbrsP 
		LEFT OUTER JOIN  zbstotdr2P ON ZGlTotalNbrsP.gl_nbr=zbstotdr2P.gl_nbr
		LEFT OUTER JOIN zbstotcr2P on ZGlTotalNbrsP.gl_nbr=zbstotcr2P.gl_nbr 
		INNER JOIN @PBal as F on ZGlTotalNbrsP.GL_NBR=F.gl_nbr 
		--select * from @PBal order by gl_nbr
		
		--***SELECTED FY/PERIOD***--
		--This section will gather all of the detailed information for the GL Balance sheet and insert it into the above declared table
		Insert @GLBal
		select	TOT_START,TOT_END,NORM_BAL,gl_nbrs.GLTYPE,GL_DESCR,gl_nbrs.GL_CLASS,GL_NBRS.GL_NBR,gl_Acct.Beg_Bal,gl_acct.DEBIT,gl_acct.credit,gl_Acct.End_Bal,isnull(FF.Symbol,'') AS FSymbol
				,GL_NBRS.LONG_DESCR,GLTYPEDESC,glfiscalyrs.FISCALYR,glfyrsdetl.period,GLFYRSDETL.EndDate,GLFYRSDETL.lClosed
				,gl_Acct.Beg_BalPR,gl_acct.DEBITPR,gl_acct.creditPR,gl_Acct.End_BalPR,isnull(PF.Symbol,'') AS PSymbol
				
		from	GL_ACCT		
				left outer join GL_NBRS on gl_acct.GL_NBR = GL_NBRS.GL_NBR
				left outer join GLTYPES on GL_NBRS.GLTYPE = gltypes.GLTYPE
				inner join GLFYRSDETL on gl_acct.FK_FYDTLUNIQ = glfyrsdetl.FYDTLUNIQ
				inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
				left outer JOIN Fcused PF ON GL_ACCT.PrFcused_uniq = PF.Fcused_uniq		--05/02/17 DRP:  added
				left outer JOIN Fcused FF ON GL_ACCT.FuncFcused_uniq = FF.Fcused_uniq	--05/02/17DRP:  added


		where	@lcFy = glfiscalyrs.FISCALYR
				and @lcPer = glfyrsdetl.period
				and gl_nbrs.STMT = 'BAL'
				--06/23/15 YS change to optimize the "where" and remove "*"
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
				--			case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				
				--			case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end

		--The below section should calculate the Ending Balance for the Closing Account Selected Priod/Year

		;
		with zbstotdr as
					(
					SELECT	SUM(END_BAL) AS TotAmt,SUM(End_BalPR) AS TotAmtPR
					from	@GLBal as A  
					where	Norm_Bal = 'DR'
					)
		,
		zbstotcr as
					(			
					Select	SUM(end_bal) as TotAmt,SUM(end_balPR) as TotAmtPR
					from	@GLBal as B
					where Norm_Bal = 'CR'	
					)
					
					
		--This section is taking the calculated Ending Balance for the Closing Account and updating it into the Delcared table above for Selected FY/Period
		--note that if the Norm_Bal = CR then the value will be reversed on the Balance Sheet report			
		update @GLBal set End_Bal = -(isnull(zbstotdr.totAmt,0.00) + isnull(zbstotcr.totamt,0.00)),End_BalPR = -(isnull(zbstotdr.totAmtPR,0.00) + isnull(zbstotcr.totamtPR,0.00)) from zbstotdr,zbstotcr,glsys where gl_class = 'Closing' and gl_nbr = glsys.CUR_EARN

		--This section below is calculating the total by gltype
		;
		with
		ZGlTotalNbrs as
					(				
					select	GL_NBR,tot_start,Tot_end
					from	@GLBal as C 
					where	gl_class = 'Total'
					)
					,
		Zbstotdr2 as
					(
					select	ZGlTotalNbrs.gl_nbr,SUM(end_bal) as TotAmtDr,SUM(end_balPR) as TotAmtDrPR
					from	@GLBal as D,ZGlTotalNbrs
					where	Norm_Bal = 'DR'
							and D.gl_nbr between ZGlTotalNbrs.tot_start and ZGlTotalNbrs.tot_end
							and gl_class <> 'Total'
					GROUP BY ZGlTotalNbrs.gl_nbr		
					)	
					,
		Zbstotcr2 as
					(
					select	ZGlTotalNbrs.gl_nbr,SUM(end_bal) as TotAmtCr,SUM(end_balPR) as TotAmtCrPR
					from	@GLBal as E,ZGlTotalNbrs
					where	Norm_Bal = 'CR'
							and E.gl_nbr between ZGlTotalNbrs.Tot_Start and ZGlTotalNbrs.Tot_End
							and gl_class <> 'Total'
					GROUP BY ZGlTotalNbrs.gl_nbr		
					)
		--This section is taking the calculated Ending Balance per the GLType and update the table for the Select FY/Period			
		-- Note that if the Norm_bal = CR the value will be reversed on the Balance Sheet report.
		update @GLBal set End_bal =ISNULL(zbstotdr2.totamtdr,0.00)+ISNULL(zbstotcr2.totamtcr,0.00),End_balPR =ISNULL(zbstotdr2.TotAmtDrPR,0.00)+ISNULL(zbstotcr2.TotAmtCrPR,0.00) FROM ZGlTotalNbrs 
		LEFT OUTER JOIN  zbstotdr2 ON ZGlTotalNbrs.gl_nbr=zbstotdr2.gl_nbr
		LEFT OUTER JOIN zbstotcr2 on ZGlTotalNbrs.gl_nbr=zbstotcr2.gl_nbr 
		INNER JOIN @GLBal as F on ZGlTotalNbrs.GL_NBR=F.gl_nbr 


BEGIN
IF @lFCInstalled = 0
	begin
		if (@lcShowAll = 'No')
		Begin
		select	t1.Tot_Start,T1.tot_end,t1.Norm_Bal,t1.GLTYPE,t1.gl_descr,t1.gl_class,t1.GL_NBR
				,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as  End_Bal --,t1.End_bal	05/05/2015 DRP 
				,t1.long_descr,t1.glTypeDesc,t1.FiscalYear,t1.Period,t1.EndDate,t1.IsClosed
				,case when Norm_Bal = 'DR' then isnull(PriorAmt,0.00) else isnull(-PriorAmt,0.00) end as PriorAmt --,t1.PriorAmt 05/05/2015 DRP
				,isnull(t1.PriorFY,'') as PriorFY,isnull(t1.PriorPeriod,0) as PriorPeriod,isnull(t1.PriorEndDate,'') as PriorEndDate
		from	(
				select	gb1.tot_start,gb1.tot_end,gb1.Norm_Bal,gb1.GLTYPE,gl_descr,gb1.gl_class,gb1.GL_NBR,End_bal,long_descr,glTypeDesc,FiscalYear,Period,EndDate,IsClosed
				--PriorAmt,PriorFY,PriorPeriod,PriorEndDate	--04/07/17 DRP:  replaced with that below, the null value was causing the new GL #'s to fall off of the results
						,isnull(PriorAmt,0.00) as PriorAmt,isnull(PriorFY,'') as PriorFY,isnull(PriorPeriod,0) as PriorPeriod,isnull(PriorEndDate,'') as PriorEndDate	
				from	@GLBal as GB1
						left outer join  @PBal as PB1 on gb1.gl_nbr = pb1.gl_nbr
			--			outer apply @PBal as PB1	--04/07/17 DRP:  the below was replaced by the above left outer join. 
			--  where	gb1.gl_nbr = pb1.gl_nbr
				) T1 
		where t1.End_Bal+t1.PriorAmt <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
		end

		else if (@lcShowAll = 'Yes')
		select	T1.tot_start,T1.tot_end,T1.Norm_Bal,T1.GLTYPE,gl_descr,T1.gl_class,T1.GL_NBR
				,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as  End_Bal	--,End_bal  05/05/2015 DRP
				,long_descr,glTypeDesc,FiscalYear,Period,EndDate,IsClosed
				,case when Norm_Bal = 'DR' then PriorAmt else -PriorAmt end as PriorAmt --,t1.PriorAmt 05/05/2015 DRP
				,PriorFY,PriorPeriod,PriorEndDate
		from	(
				select	gb1.tot_start,gb1.tot_end,gb1.Norm_Bal,gb1.GLTYPE,gl_descr,gb1.gl_class,gb1.GL_NBR,End_bal,long_descr,glTypeDesc,FiscalYear,Period,EndDate,IsClosed
				--PriorAmt,PriorFY,PriorPeriod,PriorEndDate	--04/07/17 DRP:  replaced with that below, the null value was causing the new GL #'s to fall off of the results
						,isnull(PriorAmt,0.00) as PriorAmt,isnull(PriorFY,'') as PriorFY,isnull(PriorPeriod,0) as PriorPeriod,isnull(PriorEndDate,'') as PriorEndDate	
				from	@GLBal as GB1
						left outer join  @PBal as PB1 on gb1.gl_nbr = pb1.gl_nbr
			--			outer apply @PBal as PB1	--04/07/17 DRP:  the below was replaced by the above left outer join. 
			--  where	gb1.gl_nbr = pb1.gl_nbr
				) T1
		order by gl_nbr

END

else

/**************************/
/*FOREIGN CURRENCY SECTION*/
/**************************/
	BEGIN 
		if (@lcShowAll = 'No')
			begin
			select	t1.Tot_Start,T1.tot_end,t1.Norm_Bal,t1.GLTYPE,t1.gl_descr,t1.gl_class,t1.GL_NBR
					,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as  End_Bal,FSymbol 
					,t1.long_descr,t1.glTypeDesc,t1.FiscalYear,t1.Period,t1.EndDate,t1.IsClosed
					,case when Norm_Bal = 'DR' then isnull(PriorAmt,0.00) else isnull(-PriorAmt,0.00) end as PriorAmt
					,isnull(t1.PriorFY,'') as PriorFY,isnull(t1.PriorPeriod,0) as PriorPeriod,isnull(t1.PriorEndDate,'') as PriorEndDate
					,case when Norm_Bal = 'DR' then End_BalPR else -End_BalPR end as  End_BalPR
					,case when Norm_Bal = 'DR' then isnull(PriorAmtPR,0.00) else isnull(-PriorAmtPR,0.00) end as PriorAmtPR
					
					,PSymbol
			from	(
					select	gb1.tot_start,gb1.tot_end,gb1.Norm_Bal,gb1.GLTYPE,gl_descr,gb1.gl_class,gb1.GL_NBR,End_bal,long_descr,glTypeDesc,FiscalYear,Period,EndDate,IsClosed
					--PriorAmt,PriorFY,PriorPeriod,PriorEndDate	--04/07/17 DRP:  replaced with that below, the null value was causing the new GL #'s to fall off of the results
							,isnull(PriorAmt,0.00) as PriorAmt,isnull(PriorFY,'') as PriorFY,isnull(PriorPeriod,0) as PriorPeriod,isnull(PriorEndDate,'') as PriorEndDate
							,GB1.FSymbol,End_BalPR,isnull(PriorAmtPR,0.00) as PriorAmtPR,gb1.PSymbol
					from	@GLBal as GB1
							left outer join  @PBal as PB1 on gb1.gl_nbr = pb1.gl_nbr
				--			outer apply @PBal as PB1	--04/07/17 DRP:  the below was replaced by the above left outer join. 
				--  where	gb1.gl_nbr = pb1.gl_nbr
					) T1 
			where t1.End_Bal+t1.PriorAmt <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
			end

			else if (@lcShowAll = 'Yes')
			select	T1.tot_start,T1.tot_end,T1.Norm_Bal,T1.GLTYPE,gl_descr,T1.gl_class,T1.GL_NBR
					,case when Norm_Bal = 'DR' then End_Bal else -End_Bal end as  End_Bal,FSymbol
					,long_descr,glTypeDesc,FiscalYear,Period,EndDate,IsClosed,case when Norm_Bal = 'DR' then PriorAmt else -PriorAmt end as PriorAmt
					,PriorFY,PriorPeriod,PriorEndDate
					,case when Norm_Bal = 'DR' then End_BalPR else -End_BalPr end as  End_BalPR
					,case when Norm_Bal = 'DR' then PriorAmtPR else -PriorAmtPR end as PriorAmtPR,PSymbol
			from	(
					select	gb1.tot_start,gb1.tot_end,gb1.Norm_Bal,gb1.GLTYPE,gl_descr,gb1.gl_class,gb1.GL_NBR,End_bal,long_descr,glTypeDesc,FiscalYear,Period,EndDate,IsClosed
					--PriorAmt,PriorFY,PriorPeriod,PriorEndDate	--04/07/17 DRP:  replaced with that below, the null value was causing the new GL #'s to fall off of the results
							,isnull(PriorAmt,0.00) as PriorAmt,isnull(PriorFY,'') as PriorFY,isnull(PriorPeriod,0) as PriorPeriod,isnull(PriorEndDate,'') as PriorEndDate	
							,GB1.FSymbol,End_BalPR,isnull(PriorAmtPR,0.00) as PriorAmtPR,GB1.PSymbol
					from	@GLBal as GB1
							left outer join  @PBal as PB1 on gb1.gl_nbr = pb1.gl_nbr
				--			outer apply @PBal as PB1	--04/07/17 DRP:  the below was replaced by the above left outer join. 
				--  where	gb1.gl_nbr = pb1.gl_nbr
					) T1
			order by gl_nbr
		end
	end
end