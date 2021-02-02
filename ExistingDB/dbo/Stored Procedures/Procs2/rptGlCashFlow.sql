-- =============================================
-- Author:		Debbie	
-- Create date:	02/23/2016
-- Reports:		cashflow
-- Description:	procedure is used to compile the CashFlow statement information 
-- Modified:	
-- =============================================
create PROCEDURE [dbo].[rptGlCashFlow] 


--declare
		@lcFy as char(4) = '2016'
		,@lcPer as int = '5'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin



/***GATHER FISCAL YEAR DETAILS***/					
	--Declared the below table in order to get the true Prior Period/Fiscal Year based on what was selected
	declare @fyrs as table	(fk_fy_uniq char(10),FiscalYear char(4),Period numeric(2),EndDate date,fydtluniq uniqueidentifier,Pfk_fy_uniq char(10),PriorFy char(4)
							,PriorPeriod numeric (2),PriorEndDate date,Pfydtluniq uniqueidentifier)
	--Below will insert into the above @fyrs table the FY and Period the user selected and the Prior Period and/or Fiscal Year.  
	--We had to do this in case they have 13 periods or if the entry is for the first Period of the FY
	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView 
	;
	WITH tSeq 
		AS
		(
		select *,ROW_NUMBER() OVER (ORDER BY FiscalYr,Period) as nSeq from @T
		)
		,
		zFys as(
		SELECT	t3.fk_fy_uniq,t3.FiscalYr,t3.Period,t3.ENDDATE,t3.fyDtlUniq
				,t2.fk_fy_uniq as Pfk_fy_uniq,t2.FiscalYr as PriorFY,t2.Period as PriorPeriod,t2.enddate as PriorEndDate,t2.fyDtlUniq as Pfydtluniq 
				FROM tSeq t2,tSeq t3
		WHERE t2.nSeq = (SELECT nSeq-1 FROM tSeq t1 where t1.FiscalYr=@lcFy and t1.Period=@lcPer)
		and t3.nSeq = (select nSeq from tSeq t1 where t1.FiscalYr=@lcFy and t1.Period = @lcPer)

		)
	insert @fyrs select * from zFys	

	--select * from @fyrs

	declare @fy char(4),@period int,@enddate smalldatetime,@fyDtlUniq uniqueidentifier,@PriorEndDate smalldatetime,@PriorPeriod int,@PriorFy char(4)
				select  @fy = fiscalyear,@Period = period,@PriorPeriod = PriorPeriod,@PriorFy = PriorFy ,@enddate=EndDate,@fyDtlUniq =FyDtlUniq,@PriorEndDate = PriorEndDate from @fyrs where FiscalYear =@lcfy and Period=@lcper 




/***GL ACCT DETAIL***/
	declare @GLInc1 as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13),glTypeDesc char(20)
							,LONG_DESCR char(52),AMT NUMERIC (14,2),PriorAmt numeric(14,2))

	--This section will gather the gl account detail and insert It into the table above
	insert	@GLInc1								
			Select	tot_start,tot_end,norm_bal,gltypes.GLTYPE,Gl_descr,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr,Gltypes.Gltypedesc,gl_nbrs.LONG_DESCR
					, CAST (0.00 as numeric(14,2))as Amt,CAST (0.00 AS NUMERIC(14,2)) as PriorAmt
			FROM	Gl_nbrs, Gltypes 
			WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
					  AND Gl_nbrs.stmt = 'INC' 
					  and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
			order by gl_nbr



/***SELECTED PERIOD CASH FLOW***/	
	declare @AllTrans as table (FiscalYear char(4),Period numeric(2),gl_nbr char(13),gl_class char(7),Amt numeric(14,2),gl_descr char(30))
 
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
		where	(GLTRANSHEADER.FY = @fy and gltransheader.period = @period)
				or (GLTRANSHEADER.FY = @Priorfy and gltransheader.period = @priorPeriod)
				and gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
		) 
		--select * from @AllTrans
		
	
	insert	@AllTrans 
			select	FY,zalltrans.PERIOD,GL_NBR,gl_Class,SUM(Debit-credit) as Amt,GL_DESCR
			from	ZAllTrans 
			where	JEtype <> 'CLOSE' 
			group by FY,zalltrans.PERIOD,GL_NBR,gl_Class,GL_DESCR
			order by GL_NBR



	--This will update the above @GLInc1 table with the calculated totals
		update	@GLinc1 set Amt = (isnull(a1.Amt,0.00))				
		from	@GLInc1 as B
				inner join (select * from @AllTrans A where A.FiscalYear = @fy) A1 on B.gl_nbr = A1.gl_nbr
		where	A1.gl_nbr = B.gl_nbr
				
		update	@GLinc1 set PriorAmt = (isnull(C1.Amt,0.00))
		from	@GLInc1 as B
				inner join (select * from @alltrans C where C.FiscalYear = @PriorFy) C1 on B.gl_nbr = C1.gl_nbr 
		where	C1.gl_nbr = B.gl_nbr
	



	--This below section will calculate the Closing value
			;
			with
			ZGlClosingNbrs as
						(				
						select	GL_NBR,tot_start,Tot_end
						from	@GLInc1 as C 
						where	gl_class = 'Closing'
						)
			,
			ZIncClose as
						(
						select	ZGlClosingNbrs.gl_nbr,SUM(Amt) as TotAmt,Sum(PriorAmt) as PriorTotAmt
						from	@GLInc1 as D,ZGlClosingNbrs
						where	D.gl_nbr between ZGlClosingNbrs.tot_start and ZGlClosingNbrs.tot_end
								and gl_class <> 'Title' 
								and gl_class <> 'Closing'
						GROUP BY ZGlClosingNbrs.gl_nbr		
						)	
	update	@GLInc1 set Amt = ISNULL(zincclose.TotAmt,0.00),PriorAmt = ISNULL(zincclose.PriorTotAmt,0.00) 
	from	zglclosingnbrs 
			left outer join ZIncClose on ZGlClosingNbrs.gl_nbr = ZIncClose.gl_nbr 
			inner join @GLInc1 as E on ZGlClosingNbrs.gl_nbr = e.gl_nbr 
	
	
	declare @Results as table (gltypedesc char(20),IsUse numeric (1),cashActName nvarchar (50),cashFlowActCode numeric(1),seqNumber numeric(1),Amt numeric(14,2),category char(50)
								,FiscalYear char(4),Period numeric(2),EndDate date,GroupId char(1),PriorAmt numeric(14,2),PriorEndDate date,PriorPeriod numeric(2),PriorFy char(4)
								,lo_limit char(13),hi_limit char(13))


	/**NOW I GENERATED CASH FLOW STRUCTURE**/
	insert into @Results 
	select	gltypedesc,isuse,cashActName,m.cashFlowActCode,seqNumber,0.00 as Amt
			,case when m.cashFlowActCode between 1 and 3 then cast ('Cash flows from operating activities' as char(50)) 
					when m.cashFlowActCode = 4 then cast ('Cash flows from investing activities' as char(50))
						when m.cashFlowActCode = 5 then cast ('Cash flows from financing activities' as char(50)) end as Category
			,@fy,@period,@enddate 
				,case when m.cashFlowActCode between 0 and 3 then cast ('A' as char(1)) 
					when m.cashFlowActCode = 4 then cast ('B' as char(1))
						when m.cashFlowActCode = 5 then cast ('C' as char(1)) end as GroupId
			,0.00 as PriorAmt, @PriorEndDate,@PriorPeriod,@Priorfy,LO_LIMIT,HI_LIMIT
	from	gltypes 
			inner join mnxcashFlowActivities M on gltypes.cashflowactcode = m.cashFlowActCode 
	where	gltypes.cashflowactcode <> 0 
	order by cashflowactcode, lo_limit



declare @CashFlow as table (fy char(4),period int,Ctotal numeric(14,2),LO_LIMIT CHAR(13),HI_LIMIT CHAR(13))
	
	;with zCashFlow as (
						SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType
								,gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
								,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
									ELSE CAST('' as varchar(60)) end as JEtype
								,m.cashActName,m.cashflowactcode,m.isUse,m.seqNumber,gltypes.gltypedesc,LO_LIMIT,HI_LIMIT
						FROM	GLTRANSHEADER  
								inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
								inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
								inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
								inner join gltypes on gltrans.gl_nbr between GLTYPES.LO_LIMIT and gltypes.HI_LIMIT
								inner join mnxcashflowactivities M on gltypes.cashflowactcode = m.cashFlowActCode 
						where	
								(GLTRANSHEADER.FY = @fy and gltransheader.period = @period)
								or (GLTRANSHEADER.FY = @Priorfy and gltransheader.period = @priorPeriod)
								and GL_CLASS = 'Posting'
								and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
					)
			,Zgrp as 
					(
					select	fy,Period,sum(A.Debit-A.Credit) as CTotal,LO_LIMIT,HI_LIMIT
					from	zCashFlow A
					group by Fy,Period,LO_LIMIT,HI_LIMIT
					)

	insert into @CashFlow select * from Zgrp



/**UPDATE WITH THE CURRENT PERIOD VALUES**/
	update @Results set amt =  case when isuse = 1  then -isnull(Ctotal,0.00) else isnull(Ctotal,0.00) end 	
	from	@Results CR,@cashFlow CF
	where	CF.LO_LIMIT = CR.lo_limit and CF.Hi_limit = CR.Hi_limit
			and CR.FiscalYear = CF.fy
			and Cr.Period = CF.period

/**UPDAE WITH THE PRIOR PERIOD VALUES**/
	update @Results set PriorAmt = case when isuse = 1 then -isnull(Ctotal,0.00) else isnull(Ctotal,0.00) end			
	from	@Results CR2, @cashFlow CF2 
	where	CF2.LO_LIMIT = CR2.lo_limit and CF2.Hi_limit = CR2.Hi_limit
			and CR2.PriorFy = CF2.fy
			and Cr2.PriorPeriod= CF2.period
	
/**ADD THE NET INCOME VALUES**/
	insert into @Results 
		select	glTypeDesc,cast(0 as numeric) as isuse,cast ('Net Income' as nvarchar(50)) as cashActname,cast(0 as numeric) as cashFlowActCode
				,cast (0 as numeric) as seqNumber,A.Amt,cast ('Cash flows from operating activities' as char(50)) as category
				,f2.FiscalYear,F2.Period,F2.eNDDATE 
				,cast ('A' as char(1)) as GroupId
				,PriorAmt, F2.PriorEndDate
				,@PriorPeriod AS PriorPeriod
				,@PriorFy as Priorfy
				,null as lo_limit,null as Hi_limit
		from	@GLInc1 as A 
				cross apply @fyrs F2 
		where	gl_descr = 'Net Income' 




/***CALCULATING THE GROUP TOTALS***/
	;with zAtotalP as (
			select	groupid,sum(Amt) as total,sum(PriorAmt) as Ptotal 
			from	(select groupid,Amt,PriorAmt from @results where GroupId = 'A' and cashFlowActCode <> 0) T1 group by GroupId
			)
			,
			zBtotalP as 
			(
			select	groupid,sum(Amt) as total,sum(PriorAmt) as Ptotal 
			from	(select groupid,Amt,PriorAmt from @results where GroupId = 'B') T2 group by GroupId
			)
			,
			zCtotalP as 
			(
			select	groupid,sum(Amt) as total,sum(PriorAmt) as Ptotal  
			from	(select groupid,Amt,PriorAmt from @results where GroupId = 'C') T3 group by GroupId
			)
			,
			ZGrpTotalP as 
			(
			select R2.*
				,case when cashFlowActCode = 0 then 0.00 else case when ROW_NUMBER() over(partition by r2.GroupId order by r2.GroupId) = 1 then case when R2.groupid = 'A' and cashFlowActCode <> 0 then A2.TOTAL 
					when R2.groupid = 'B' then B2.total 
						when R2.GroupId = 'C' then c2.total 
							else cast (0.00 as numeric(20,2)) end else 0.00 end end  as GrpTotal
				,case when cashFlowActCode = 0 then 0.00 else case when ROW_NUMBER() over(partition by r2.GroupId order by r2.GroupId) = 1 then case when R2.groupid = 'A' and cashFlowActCode <> 0 then A2.Ptotal 
					when R2.groupid = 'B' then B2.Ptotal 
						when R2.GroupId = 'C' then c2.Ptotal 
							else cast (0.00 as numeric(20,2)) end else 0.00 end end  as PGrpTotal
			from	@Results R2 
					LEFT OUTER join zAtotalP A2 on R2.GroupId = A2.GroupId 	
					left outer join zBtotalP B2 on R2.GroupId = B2.GroupId
					left outer join zCtotalP C2 on R2.GroupId = C2.GroupId

			)

	select	zp.gltypedesc,zp.isuse,zp.cashActName,zp.cashFlowActCode,zp.seqnumber,isnull(zp.Amt,0.00) as Amt,zp.category,f.FiscalYear,f.Period,zp.EndDate
			,isnull(zp.grpTotal,0.00) as GroupTotal,zp.GroupId,isnull (zp.prioramt,0.00) as PriorAmt,f.PriorEndDate,@PriorPeriod as PriorPeriod,@PriorFy as PriorFy
			,isnull(zp.PgrpTotal,0.00) as PriorGroupTotal,lo_limit,hi_limit
	from	ZGrpTotalP ZP
			cross apply @fyrs F 
	order by GroupId,cashflowactcode,seqnumber


END