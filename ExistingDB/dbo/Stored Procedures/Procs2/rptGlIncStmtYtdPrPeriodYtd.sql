
-- =============================================
-- Author:		Debbie
-- Create date: 08/03/2012
-- Description:	Created for the Income Statement ~ YTD / Prior Period YTD
-- Reports Using Stored Procedure:  glincst6.rpt
-- Modified:	12/10/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
--					05/07/2015 DRP:  added @userId . . . Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division.
--									 removed lic_name from the results.  I can gather that info on the report itself.
--									 replaced the @lcShowAll = 'No' and @lcShowAll = 'Yes' sections with a different select statement so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
-- 06/23/15 YS modified to use new sequencenumber and more
-- 06/24/15 YS more changes
-- 06/26/15 YS and DRP:   removed @fyrs it should not have been used
-- =============================================
CREATE PROCEDURE [dbo].[rptGlIncStmtYtdPrPeriodYtd]
--declare
		@lcFy as char(4) = ''
		,@lcPer as int = ''
		,@lcShowAll as char(3) = 'No'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null


as
begin


--*****DECLARES THE TABLE WHERE THE YTD TOTALS WILL BE INSERTED*****
	--This table will gather the totals for the Year to Date values
	declare @GLYTD as table (Norm_Bal char(2),gl_class char(7),gl_nbr char(13),BegDate smalldatetime,YTDAmt numeric(14,2),PrBegDate smalldatetime,PrPeriodYTDAmt numeric (14,2))	

--*****DECLARE TABLE WHERE THE FISCAL YEAR DETAIL INFORMATION	*****	
	--Declared the below table in order to get the true Prior Period/Fiscal Year based on what was selected
	--06/23/15 YS added sequencenumber
		--declare @fyrs as table	(fk_fy_uniq char(10),FiscalYear char(4),Period numeric(2),FyBegDate smalldatetime,PerBegDate smalldatetime,PerEndDate smalldatetime,fydtluniq uniqueidentifier
		--,Pfk_fy_uniq char(10),PriorFy char(4),PriorPeriod numeric (2),PrFyBegDate smalldatetime,PrPerBegDate smalldatetime,PrPerEndDate smalldatetime,Pfydtluniq uniqueidentifier,sequenceNumber int)
		
--*****DECLARES THE TABLE WHERE THE FINAL REPORTS RESULTS WILL BE INSERTED*****
	--This table will gather detailed information for the final results
	declare @GLInc1 as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13),glTypeDesc char(20)
							,LONG_DESCR char(52),FiscalYear char(4),Period numeric(2),YTDAmt numeric(14,2),FyBegDate smalldatetime,EndDate smalldatetime
							,PrPeriodFy char(4),PrPeriod numeric(2),PrYTDAmt numeric(14,2), PrEndDate smalldatetime) 
							--,Lic_name char(40))

		
	--Gathers the GL Account detailed information for the YTD and inserts it into the @GLYTD table declared above
			insert	@GLyTD								
					Select	GLTYPES.NORM_BAL,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr, null as BegDate,CAST (0.00 as numeric(14,2))as YTDAmt,null as PrBegDate, CAST (0.00 as numeric (14,2)) as PrPeriodYTDAmt
					FROM	Gl_nbrs, Gltypes 

					WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
							AND Gl_nbrs.stmt = 'INC' 
							and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
										case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
					order by gl_nbr


--select * from @glytd

	--This section will gather the gl account detail and insert It into the table above
		insert	@GLInc1								
				Select	tot_start,tot_end,norm_bal,gltypes.GLTYPE,Gl_descr,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr,Gltypes.Gltypedesc,gl_nbrs.LONG_DESCR
						,null as FiscalYear,null as Period, CAST (0.00 as numeric(14,2))as Amt,NULL AS FyBegDate,null as EndDate--,CAST('' as CHAR(40))
						,null as PrPeriodfy,null as PrPeriod,CAST(0.00 as numeric(14,2)) as PrYtdAmt,null as PrEndDate 

				FROM	Gl_nbrs, Gltypes 

				WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
						AND Gl_nbrs.stmt = 'INC' 
						and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
									case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
				order by gl_nbr

			--select * from @GLInc1

	--Below will insert into the above @fyrs table the FY and Period the user selected and the Prior Period and/or Fiscal Year.  
	--We had to do this in case they have 13 periods or if the entry is for the first Period of the FY
		DECLARE @T as dbo.AllFYPeriods
		--06/23/15 YS retreive all records from the prior fy. 
		INSERT INTO @T EXEC GlFyrstartEndView @lcFy
		--select * from @t

		declare @PriorFY char(4),@PriorFyStartDate date,@SelectedFyStartDate date,
				@selectedPeriodStartDate date,@selectedPeriodEndDate date,
				@priorPeriodStartDate date,@priorPeriodEndDate date,
				@priorPeriod int
		
		SELECT	@priorFy = FyInfo.priorFiscalYr ,@PriorFyStartDate=FyInfo.PriorFyStartDate,
			@SelectedFyStartDate=FyInfo.SelectedFyStartDate,
			@selectedPeriodStartDate = FyInfo.selectedPeriodStartDate,
			@selectedPeriodEndDate = FyInfo.selectedPeriodEndDate,
			@priorPeriodStartDate = FyInfo.priorPeriodStartDate,
			@priorPeriodEndDate = FyInfo.priorPeriodEndDate,
			@priorPeriod = priorPeriod
			FROM (SELECT ISNULL(T0.FiscalYr,' ') as priorFiscalYr ,
				G0.dBeginDate as PriorFyStartDate,
				G.dBeginDate as SelectedFyStartDate,
				T.StartDate as selectedPeriodStartDate,
				T.EndDate as selectedPeriodEndDate,
				T0.StartDate as priorPeriodStartDate,
				T0.EndDate as priorPeriodEndDate,
				T0.Period as  PriorPeriod
			FROM @T T LEFT OUTER JOIN  @T T0 ON T.rn=T0.rn +1 
			LEFT OUTER JOIN GLFISCALYRS G0 on T0.fk_fy_uniq=G0.FY_UNIQ 
			INNER JOIN GLFISCALYRS G on T.fk_fy_uniq=G.FY_UNIQ 
			where T.FiscalYr=@lcFy and t.period=@lcPer) FyInfo 

			--select @PriorFY as PriorFY ,@PriorFyStartDate as PriorFyStartDate ,@SelectedFyStartDate as SelectedFyStartDate,
			--	@selectedPeriodStartDate as selectedPeriodStartDate ,@selectedPeriodEndDate as selectedPeriodEndDate,
			--	@priorPeriodStartDate as priorPeriodStartDate,@priorPeriodEndDate as priorperiodenddate,
			--	@priorPeriod as priorperiod

		--insert @fyrs 
		--SELECT	tcurrent.fk_fy_uniq,tcurrent.FiscalYr,tcurrent.Period,g1.dBeginDate,tcurrent.StartDate as fyBegDate,tcurrent.ENDDATE,tcurrent.fyDtlUniq
		--		,tprior.fk_fy_uniq as Pfk_fy_uniq,tprior.FiscalYr as PriorFY,tprior.Period as PriorPeriod
		--		,g2.dBeginDate as PrPerBegDate,tprior.StartDate as PriorBegDate,tprior.enddate as PriorEndDate,tprior.fyDtlUniq as Pfydtluniq,tprior.sequenceNumber 
		--from @t tcurrent left outer join @t tprior on tcurrent.rn-1=tprior.rn and tcurrent.Period=tprior.Period
		--inner join GLFISCALYRS g1 on tcurrent.sequenceNumber=g1.sequenceNumber
		--left outer join GLFISCALYRS g2 on tprior.sequenceNumber=g2.sequenceNumber
		--where tcurrent.FiscalYr=@lcFy and tcurrent.Period=@lcPer

		--;
		--WITH tSeq 
		--	AS
		--	(
		--	select *,ROW_NUMBER() OVER (ORDER BY FiscalYr,Period) as nSeq from @T
		--	)
		--	,
		--	zFys as	(
		--			SELECT	t3.fk_fy_uniq,t3.FiscalYr,t3.Period,g1.dBeginDate,t3.StartDate as fyBegDate,t3.ENDDATE,t3.fyDtlUniq
		--					,t2.fk_fy_uniq as Pfk_fy_uniq,t2.FiscalYr as PriorFY,t2.Period as PriorPeriod
		--					,g2.dBeginDate as PrPerBegDate,t2.StartDate as PriorBegDate,t2.enddate as PriorEndDate,t2.fyDtlUniq as Pfydtluniq 
		--			FROM	tSeq t2,tSeq t3,GLFISCALYRS as G1,GLFISCALYRS as G2
		--			WHERE	t2.nSeq = (SELECT nSeq-1 FROM tSeq t1 where t1.FiscalYr=@lcFy and t1.Period=@lcPer)
		--					and t3.nSeq = (select nSeq from tSeq t1 where t1.FiscalYr=@lcFy and t1.Period = @lcPer)
		--					and t3.fk_fy_uniq = G1.FY_UNIQ
		--					and t2.fk_fy_uniq = G2.FY_UNIQ
		--			)
		--insert @fyrs select * from zFys	


--**********PRIOR PERIOD YTD**********
	declare @AllTransPr as table (FiscalYear char(4),gl_nbr char(13),gl_class char(7),PrPeriodYTDAmt numeric(14,2),PrBegdate smalldatetime)
	--This section will sum the debit and credit together from the gltransaction information and then update It into the declared table above  
	;With
	ZAllTransPr as
(
		SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType,
				gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
				,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
					ELSE CAST('' as varchar(60)) end as JEtype
					--,F1.PrFyBegDate
	
		FROM	GLTRANSHEADER  
				inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
				inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
				inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
				--06/23/15 YS yse data avaialbale in @fyrs
				--06/24/15 YS use variables
				--left outer join @fyrs f1 on GLTRANSHEADER.fy = f1.PriorFy
				--left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
				--inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
				--INNER JOIN @fyrs AS f1 ON GLFYRSDETL.FK_FY_UNIQ = F1.pfk_fy_uniq
							
		wherE gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				--06/24/15 YS use variables
				and GLTRANSHEADER.fy=@priorFy
				--and F1.pRIORpERIOD >= GLTRANSHEADER.period
				and GLTRANSHEADER.period<=@priorPeriod
				--06/23/15 YS optimize the "where" and remove "*"
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
				--	 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
	) 
	
	insert	@AllTransPr 
			select	fy,GL_NBR,gl_Class,SUM(Debit-credit) as PrPeriodYTDAmt ,@PriorFyStartDate as PrBegDate
			from	ZAllTransPr
			where	JEtype <> 'CLOSE'
			group by FY,GL_NBR,gl_Class order by GL_NBR


--select * from @AllTransPr order by gl_nbr,FiscalYear
	update @GLYTD set PrPeriodYTDAmt = (isnull(YTD2.PrPeriodYTDAmt,0.00)) from  @AllTransPr as YTD2,@GLytd as B where YTD2.gl_nbr = B.gl_nbr 

	--This below section will calculate the Closing values for Year To Date
			;
			with
			ZYTDClosingNbrs as
						(				
						select	GL_NBR,tot_start,Tot_end
						from	GL_NBRS
						where	gl_class = 'Closing'
								and gl_nbrs.STMT = 'INC'
								and gl_nbrs.STATUS = 'Active'
								--06/23/15 YS optimize the "where" and remove "*"
								and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
								--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
								--			case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
						)
			,
			ZYTDClose as
						(
						select	ZYTDClosingNbrs.gl_nbr,SUM(PrPeriodYTDAmt) as TotAmt
						from	@GLYTD as YTD1,ZYTDClosingNbrs
						where	YTD1.gl_nbr between ZYTDClosingNbrs.tot_start and ZYTDClosingNbrs.tot_end
								and gl_class <> 'Title' 
								and gl_class <> 'Closing'
						GROUP BY ZYTDClosingNbrs.gl_nbr		
						)	

	update	@GLYTD set PrPeriodYTDAmt = ISNULL(zYTDclose.TotAmt,0.00) 
			from	zYTDclosingnbrs 
					left outer join ZYTDClose on ZYTDClosingNbrs.gl_nbr = ZYTDClose.gl_nbr 
					inner join @GLYTD as YTD2 on ZYTDClosingNbrs.gl_nbr = YTD2.gl_nbr 

	--This below section will calculate the Totaling value for Year To Date
				;
					with
					ZYTDTotNbrs as
								(				
							select	GL_NBR,tot_start,Tot_end
								from	gl_nbrs 
								where	gl_class = 'Total'
										and gl_nbrs.STMT = 'INC'
										and gl_nbrs.STATUS = 'Active'
										--06/23/15 YS optimize the "where" and remove "*"
										and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
										--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
										--			case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
								)
								,
					ZYTDTotDr as
								(
								select	zYTDTotNbrs.gl_nbr,sum(PrPeriodYTDAmt) as TotAmtDr
								from	@GLYTD as YTD3,ZYTDTotNbrs
								where	YTD3.gl_nbr between ZYTDTotNbrs.tot_start and ZYTDTotNbrs.tot_end
										and Norm_Bal = 'DR'
										and gl_class <> 'Total'
										and gl_class <> 'Closing'
								group by zYTDtotnbrs.gl_nbr
								)		

								,
					zYTDTotCr as
								(
								select	zYTDTotNbrs.gl_nbr,sum(PrPeriodYTDAmt) as TotAmtCr
								from	@GLYTD as YTD4, ZYtdTotNbrs
								where	YTD4.gl_nbr between ZYTDTotNbrs.tot_start and ZYTDTotNbrs.tot_end
										and Norm_Bal = 'CR'
										and gl_class <> 'Total'
										and gl_class <> 'Closing'
								group by zYTDtotnbrs.gl_nbr 
								)	


					update	@GLYTD set PrPeriodYTDAmt = (ISNULL(zYTDtotdr.TotAmtdr,0.00)) + (ISNULL(zYTDtotcr.totamtcr,0.00))  
					from	ZYTDTotNbrs 
							left outer join ZYTDTotDr on ZYTDTotNbrs.gl_nbr = ZYTDTotDr.gl_nbr
							left outer join zYTDTotCr on ZYTDTotNbrs.gl_nbr = zYTDtotcr.gl_nbr
							left outer join @GLYTD as YTD5 on ZYTDTotNbrs.gl_nbr = YTD5.gl_nbr 


--**********CURRENT PERIOD YTD**********
	declare @AllTrans as table (FiscalYear char(4),gl_nbr char(13),gl_class char(7),YTDAmt numeric(14,2),Begdate smalldatetime)
	--This section will sum the debit and credit together from the gltransaction information and then update It into the declared table above  
	;With
	ZAllTrans as
(
		SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType,
				gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
				,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
					ELSE CAST('' as varchar(60)) end as JEtype

	
		FROM	GLTRANSHEADER  
				inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
				inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
				inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
				--06/24/15 YS use variables
				--06/23/15 YS use data avaialbale in @fyrs
				--left outer join @fyrs f1 on GLTRANSHEADER.fy = f1.FiscalYear
				--left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
				--inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
				--INNER JOIN @fyrs AS f1 ON GLFYRSDETL.FK_FY_UNIQ = F1.fk_fy_uniq
							
		wherE gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				--06/24/15 YS use variables
				and GLTRANSHEADER.fy=@lcFy
				and GLTRANSHEADER.period<=@lcPer
				--06/23/15 YS optimize the "where" and remove "*"
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
				--	 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
		) 
		-- 06/26/15 YS removed @fyrs is not used
	insert	@AllTrans
			select	fy,GL_NBR,gl_Class,SUM(Debit-credit) as YTDAmt ,@selectedPeriodStartDate as BegDate
			from	ZAllTrans
			where	JEtype <> 'CLOSE'
			group by FY,GL_NBR,gl_Class order by GL_NBR


	update @GLYTD set YTDAmt = (isnull(YTD2.YTDAmt,0.00)) from  @AllTrans as YTD2,@GLytd as B where YTD2.gl_nbr = B.gl_nbr 

	--This below section will calculate the Closing values for Year To Date
			;
			with
			ZYTDClosingNbrs as
						(				
						select	GL_NBR,tot_start,Tot_end
						from	GL_NBRS
						where	gl_class = 'Closing'
								and gl_nbrs.STMT = 'INC'
								and gl_nbrs.STATUS = 'Active'
								--06/23/15 YS optimize the "where" and remove "*"
								and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
								--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
								--			 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
						)
			,
			ZYTDClose as
						(
						select	ZYTDClosingNbrs.gl_nbr,SUM(YTDAmt) as TotAmt
						from	@GLYTD as YTD1,ZYTDClosingNbrs
						where	YTD1.gl_nbr between ZYTDClosingNbrs.tot_start and ZYTDClosingNbrs.tot_end
								and gl_class <> 'Title' 
								and gl_class <> 'Closing'
						GROUP BY ZYTDClosingNbrs.gl_nbr		
						)	

	update	@GLYTD set YTDAmt = ISNULL(zYTDclose.TotAmt,0.00) 
			from	zYTDclosingnbrs 
					left outer join ZYTDClose on ZYTDClosingNbrs.gl_nbr = ZYTDClose.gl_nbr 
					inner join @GLYTD as YTD2 on ZYTDClosingNbrs.gl_nbr = YTD2.gl_nbr 

	--This below section will calculate the Totaling value for Year To Date
				;
					with
					ZYTDTotNbrs as
								(				
							select	GL_NBR,tot_start,Tot_end
								from	gl_nbrs 
								where	gl_class = 'Total'
										and gl_nbrs.STMT = 'INC'
										and gl_nbrs.STATUS = 'Active'
										--06/23/15 YS optimize the "where" and remove "*"
										and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
										--and 1 = case when @lcDiv is null OR @lcDiv = '*'or @lcDiv = '' then 1 else  
										--			case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
								)
								,
					ZYTDTotDr as
								(
								select	zYTDTotNbrs.gl_nbr,sum(ytdamt) as TotAmtDr
								from	@GLYTD as YTD3,ZYTDTotNbrs
								where	YTD3.gl_nbr between ZYTDTotNbrs.tot_start and ZYTDTotNbrs.tot_end
										and Norm_Bal = 'DR'
										and gl_class <> 'Total'
										and gl_class <> 'Closing'
								group by zYTDtotnbrs.gl_nbr
								)		

								,
					zYTDTotCr as
								(
								select	zYTDTotNbrs.gl_nbr,sum(ytdamt) as TotAmtCr
								from	@GLYTD as YTD4, ZYtdTotNbrs
								where	YTD4.gl_nbr between ZYTDTotNbrs.tot_start and ZYTDTotNbrs.tot_end
										and Norm_Bal = 'CR'
										and gl_class <> 'Total'
										and gl_class <> 'Closing'
								group by zYTDtotnbrs.gl_nbr 
								)	


					update	@GLYTD set YTDAmt = (ISNULL(zYTDtotdr.TotAmtdr,0.00)) + (ISNULL(zYTDtotcr.totamtcr,0.00))  
					from	ZYTDTotNbrs 
							left outer join ZYTDTotDr on ZYTDTotNbrs.gl_nbr = ZYTDTotDr.gl_nbr
							left outer join zYTDTotCr on ZYTDTotNbrs.gl_nbr = zYTDtotcr.gl_nbr
							left outer join @GLYTD as YTD5 on ZYTDTotNbrs.gl_nbr = YTD5.gl_nbr 

-- 06/26/15 YS removed @fyrs
update	@GLYTD 
set		BegDate = @SelectedFyStartDate,PrBegDate = @PriorFyStartDate


-- 06/26/15 YS removed @fyrs
update	@GLInc1 
set		FiscalYear= @lcFy, 
		Period= @lcPer ,
		FyBegDate=   @selectedPeriodStartDate, 
		EndDate= @selectedPeriodEndDate, 
		PrPeriod= @priorPeriod, 
		PrPeriodFy=@PriorFY,
		PrEndDate= @priorPeriodEndDate  
--from	@fyrs F5 


	
--The below will gather the information from the two Declared tables (@GLYTD and @GLINC1) and put them into the final results
/*05/07/2015 DRP: 
--if (@lcShowAll = 'No')
--begin
--	select	Tot_Start,Tot_End,YTD6.Norm_Bal,GLTYPE,gl_descr,J.gl_class,YTD6.GL_NBR,YTD6.YTDAMT,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE
--			,PrPeriodYTDAmt,PrBegDate,J.PrPeriodFy,j.PrPeriod,J.PrEndDate,MICSSYS.Lic_name 
--	from	@GLYTD AS YTD6
--			left outer JOIN @GLInc1 AS J ON YTD6.GL_NBR = J.GL_NBR 
--			cross join MICSSYS
--	where ytd6.ytdAmt+ytd6.PrPeriodYTDAmt <> 0.00 or J.gl_class ='Title' or J.gl_class = 'Heading'
--	order by gl_nbr
--end

--else if (@lcShowAll = 'Yes')
--	select	Tot_Start,Tot_End,YTD7.Norm_Bal,GLTYPE,gl_descr,K.gl_class,YTD7.GL_NBR,YTD7.YTDAMT,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE
--			,PrPeriodYTDAmt,PrBegDate,K.PrPeriodFy,k.PrPeriod,K.PrEndDate,MICSSYS.Lic_name
--	from	@GLYTD AS YTD7
--			Left outer JOIN @GLInc1 AS K ON YTD7.GL_NBR = K.GL_NBR 
--			cross join MICSSYS
--	order by gl_nbr
--05/07/2015 REPLACED BY THE BELOW*/

if (@lcShowAll = 'No')
begin
	select	Tot_Start,Tot_End,YTD6.Norm_Bal,GLTYPE,gl_descr,J.gl_class,YTD6.GL_NBR
			,case when J.gl_class = 'Posting' then -YTD6.YTDAMT else
			case when J.Norm_Bal = 'DR' and J.gl_class = 'Total  ' then -YTD6.YTDAMT else 
				case when J.Norm_Bal = 'CR' and J.gl_class ='Total' then abs(YTD6.YTDAMT) else
					case when J.Norm_Bal = 'DR' and J.gl_class  = 'Closing' then YTD6.YTDAMT else
						case when J.Norm_Bal = 'CR' and J.gl_class = 'Closing' then -YTD6.YTDAMT else
							cast(0.00 as numeric(14,2)) end end end end end as YTDAMT
			
			,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE
			,case when J.gl_class = 'Posting' then -PrPeriodYTDAmt else
			case when J.Norm_Bal = 'DR' and J.gl_class = 'Total  ' then -PrPeriodYTDAmt else 
				case when J.Norm_Bal = 'CR' and J.gl_class ='Total' then abs(PrPeriodYTDAmt) else
					case when J.Norm_Bal = 'DR' and J.gl_class  = 'Closing' then PrPeriodYTDAmt else
						case when J.Norm_Bal = 'CR' and J.gl_class = 'Closing' then -PrPeriodYTDAmt else
							cast(0.00 as numeric(14,2)) end end end end end as PrPeriodYTDAmt 
			
			,PrBegDate,J.PrPeriodFy,j.PrPeriod,J.PrEndDate
	from	@GLYTD AS YTD6
			left outer JOIN @GLInc1 AS J ON YTD6.GL_NBR = J.GL_NBR 
	where ytd6.ytdAmt+ytd6.PrPeriodYTDAmt <> 0.00 or J.gl_class ='Title' or J.gl_class = 'Heading'
	order by gl_nbr
end

else if (@lcShowAll = 'Yes')
	select	Tot_Start,Tot_End,YTD7.Norm_Bal,GLTYPE,gl_descr,K.gl_class,YTD7.GL_NBR
			,case when K.gl_class = 'Posting' then -YTD7.YTDAMT else
			case when K.Norm_Bal = 'DR' and K.gl_class = 'Total  ' then -YTD7.YTDAMT else 
				case when K.Norm_Bal = 'CR' and K.gl_class ='Total' then abs(YTD7.YTDAMT) else
					case when K.Norm_Bal = 'DR' and K.gl_class  = 'Closing' then YTD7.YTDAMT else
						case when K.Norm_Bal = 'CR' and K.gl_class = 'Closing' then -YTD7.YTDAMT else
							cast(0.00 as numeric(14,2)) end end end end end as YTDAMT
			,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE
			,case when K.gl_class = 'Posting' then -PrPeriodYTDAmt else
			case when K.Norm_Bal = 'DR' and K.gl_class = 'Total  ' then -PrPeriodYTDAmt else 
				case when K.Norm_Bal = 'CR' and K.gl_class ='Total' then abs(PrPeriodYTDAmt) else
					case when K.Norm_Bal = 'DR' and K.gl_class  = 'Closing' then PrPeriodYTDAmt else
						case when K.Norm_Bal = 'CR' and K.gl_class = 'Closing' then -PrPeriodYTDAmt else
							cast(0.00 as numeric(14,2)) end end end end end as PrPeriodYTDAmt 
			,PrBegDate,K.PrPeriodFy,k.PrPeriod,K.PrEndDate
	from	@GLYTD AS YTD7
			Left outer JOIN @GLInc1 AS K ON YTD7.GL_NBR = K.GL_NBR 
	order by gl_nbr

end