
-- =============================================
-- Author:		Debbie
-- Create date: 08/02/2012
-- Description:	Created for the Income Statement ~ Current Period / Prior Year
-- Reports Using Stored Procedure:  glincst4.rpt
-- Modified:	12/10/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
----					05/07/2015 DRP:  added @userId . . . Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division.
----									 removed lic_name from the results.  I can gather that info on the report itself.
----									 replaced the @lcShowAll = 'No' and @lcShowAll = 'Yes' sections with a different select statement so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
--06/23/15 YS optimize the "where" and remove "*" and change fiscalyrs file
-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
-- Changed to not link to it, so all the FY/Period can be updated later
-- =============================================
CREATE PROCEDURE [dbo].[rptGlIncStmtCurrPriorYr]

--declare
		 @lcFy as char(4) = ''
		,@lcPer as int = ''
		,@lcShowAll as char(3) = 'no'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

	
as 
begin

		
----This table will be used to compile the Select Fiscal Year and Period Balance information
declare @GLInc as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13)
						,glTypeDesc char(20),LONG_DESCR char(52),FiscalYear char(4),Period numeric(2),Amt numeric(14,2),EndDate smalldatetime,PriorFy char (4)
						,PriorPeriod numeric (2),PriorAmt numeric (14,2),PriorEndDate smalldatetime)
						--,LIC_NAME CHAR(40))	--05/07/2015 DRP: Removed

--*****GATHER GL ACCOUNT NUMBER INFORMATION*****
	--This section will gather the gl account detail and insert It into the table above
	insert	@GLInc								
			Select	tot_start,tot_end,norm_bal,gltypes.GLTYPE,Gl_descr,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr,Gltypes.Gltypedesc,gl_nbrs.LONG_DESCR
					,null as FiscalYear,null as Period, CAST (0.00 as numeric(14,2))as Amt,null as EndDate,NULL AS PriorFy,null as PriorPeriod
					,cast(0.00 as numeric(14,2)) as Prioramt,null as PriorEndDate
					--,CAST('' as CHAR(40))	--05/07/2015 DRP:  Removed

			FROM	Gl_nbrs, Gltypes 

			WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
					AND Gl_nbrs.stmt = 'INC' 
					--06/23/15 YS optimize the "where" and remove "*"
					and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
					--and 1 = case when @lcDiv is null OR @lcDiv = '*'  or @lcDiv = ''  then 1 else  
					-- case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.  
			order by gl_nbr

					
	--Declared the below table in order to get the true Prior Period/Fiscal Year based on what was selected
	--06/23/15 YS added sequencenumber
	declare @fyrs as table	(fk_fy_uniq char(10),FiscalYear char(4),Period numeric(2),EndDate date,fydtluniq uniqueidentifier,Pfk_fy_uniq char(10),PriorFy char(4)
							,PriorPeriod numeric (2),PriorEndDate date,Pfydtluniq uniqueidentifier,sequencenumber int)
	--Below will insert into the above @fyrs table the FY and Period the user selected and the Prior Period and/or Fiscal Year.  
	--We had to do this in case they have 13 periods or if the entry is for the first Period of the FY
	DECLARE @T as dbo.AllFYPeriods 
	--06/23/15 Ys get fy starting with the prior year
	INSERT INTO @T EXEC GlFyrstartEndView @lcFy 
	--06/23/15 YS use sequencenumber
		
	insert @fyrs 
	select tcurrent.fk_fy_uniq,tcurrent.FiscalYr,tcurrent.Period,tcurrent.ENDDATE,tcurrent.fyDtlUniq
				,tprior.fk_fy_uniq as Pfk_fy_uniq,tprior.FiscalYr as PriorFY,tprior.Period as PriorPeriod,tprior.enddate as PriorEndDate,
				tprior.fyDtlUniq as Pfydtluniq,tprior.sequencenumber
				from @t tcurrent left outer join @t tprior on tcurrent.sequencenumber-1=tprior.sequencenumber and tcurrent.Period=tprior.Period
				where tcurrent.FiscalYr=@lcFy and tcurrent.Period=@lcPer
	--;
	--WITH tSeq 
	--	AS
	--	(
	--	select *,ROW_NUMBER() OVER (ORDER BY sequencenumber,Period) as nSeq from @T
	--	)

	--	,
	--	zFys as(
	--	SELECT	t3.fk_fy_uniq,t3.FiscalYr,t3.Period,t3.ENDDATE,t3.fyDtlUniq
	--			,t2.fk_fy_uniq as Pfk_fy_uniq,t2.FiscalYr as PriorFY,t2.Period as PriorPeriod,t2.enddate as PriorEndDate,t2.fyDtlUniq as Pfydtluniq 
	--			FROM tSeq t2,tSeq t3
	--	WHERE t2.nSeq = (SELECT nSeq FROM tSeq t1 where t1.FiscalYr=@lcFy-1 and t1.Period=@lcPer)
	--	--and t2.FiscalYr = @lcFy -1
	--	and t3.nSeq = (select nSeq from tSeq t1 where t1.FiscalYr=@lcFy and t1.Period = @lcPer)

	--	)
	--insert @fyrs select * from zFys	



--***PRIOR YEAR***--	
	--This section will gather all of the detailed information for the GL Balance sheet and insert it into the above declared table
	-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
	-- Changed to not link to it, so all the FY/Period can be updated later
	declare @AllTransPr as table	(FiscalYear char(4),Period numeric(2),gl_nbr char(13),gl_class char(7),Amt numeric(14,2),gl_descr char(30))
									--,FyBegDate smalldatetime,EndDate smalldatetime)

	;With
	ZAllTrans as
		(
		SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType,
				gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
				,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
					ELSE CAST('' as varchar(60)) end as JEtype
					-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
					-- Changed to not link to it, so all the FY/Period can be updated later					
					--,GLFISCALYRS.dBeginDate,GLFYRSDETL.ENDDATE
	
		FROM	GLTRANSHEADER  
				inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
				inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
				inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
				-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
				-- Changed to not link to it, so all the FY/Period can be updated later
				--left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
				--inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
				-- 01/29/21 VL changed to link by Fiscalyear and period, not by fydtluniq
				--INNER JOIN @fyrs AS f1 ON GLFYRSDETL.FYDTLUNIQ = F1.Pfydtluniq
				INNER JOIN @fyrs AS f1 ON GLTRANSHEADER.FY = F1.PriorFy AND GLTRANSHEADER.PERIOD = F1.PriorPeriod
							
		wherE gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				--06/23/15 YS optimize the "where" and remove "*"
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = ''  then 1 else  
				--	 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.  
		) 
	-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
	-- Changed to not link to it, so all the FY/Period can be updated later
	insert	@AllTransPr 
			select	FY,PERIOD,GL_NBR,gl_Class,SUM(Debit-credit) as Amt,GL_DESCR--,dBeginDate,ENDDATE 
			from	ZAllTrans 
			where	JEtype <> 'CLOSE' 
			group by FY,PERIOD,GL_NBR,gl_Class,GL_DESCR--,dBeginDate,ENDDATE
			order by GL_NBR

	--This will update the above @GLInc1 table with the calculated totals
		update @GLinc set PriorAmt = (isnull(a1.Amt,0.00))from  @AllTransPr as A1,@GLInc as B where A1.gl_nbr = B.gl_nbr 

	--This section will calculate the Closing Value for Prior Year	
		;
		with
		ZPClosingNbrs as
					(				
					select	GL_NBR,tot_start,Tot_end
					from	gl_nbrs  
					where	gl_class = 'Closing'
							and gl_nbrs.STMT = 'INC'
					)
					,
		ZPClose as
					(
					select	ZPClosingNbrs.gl_nbr,SUM(PriorAmt) as TotAmt
					from	@GLInc as P1,ZPClosingNbrs
					where	P1.gl_nbr between ZPClosingNbrs.tot_start and ZPClosingNbrs.tot_end
							and gl_class <> 'Title' 
							and gl_class <> 'Closing'
					GROUP BY ZPClosingNbrs.gl_nbr		
					)

		update	@GLInc set PriorAmt = ISNULL(zPclose.TotAmt,0.00) 
		from	zPclosingnbrs 
				left outer join ZPClose on ZPClosingNbrs.gl_nbr = ZPClose.gl_nbr 
				inner join @GLInc as P2 on ZPClosingNbrs.gl_nbr = P2.gl_nbr 

				
		--This below section will calculate the Totaling value for Prior Year
			;
				with
				ZPTotNbrs as
							(				
						select	GL_NBR,tot_start,Tot_end
							from	gl_nbrs 
							where	gl_class = 'Total'
									and gl_nbrs.STMT = 'INC'
							)
							,
				ZPTotDr as
							(
							select	zPTotNbrs.gl_nbr,sum(prioramt) as TotAmtDr
							from	@GLInc as P3,ZPTotNbrs
							where	P3.gl_nbr between ZpTotNbrs.tot_start and ZpTotNbrs.tot_end
									and Norm_Bal = 'DR'
									and gl_class <> 'Total'
									and gl_class <> 'Closing'
							group by zptotnbrs.gl_nbr
							)		

							,
				zPTotCr as
							(
							select	zPTotNbrs.gl_nbr,sum(Prioramt) as TotAmtCr
							from	@GLInc as P4, ZPTotNbrs
							where	P4.gl_nbr between ZPTotNbrs.tot_start and ZPTotNbrs.tot_end
									and Norm_Bal = 'CR'
									and gl_class <> 'Total'
									and gl_class <> 'Closing'
							group by zPtotnbrs.gl_nbr 
							)	


				update	@GLInc set PriorAmt = (ISNULL(zPtotdr.TotAmtdr,0.00)) + (ISNULL(zPtotcr.totamtcr,0.00))  
				from	ZPTotNbrs 
						left outer join ZPTotDr on ZPTotNbrs.gl_nbr = ZPTotDr.gl_nbr
						left outer join zPTotCr on ZPTotNbrs.gl_nbr = zPtotcr.gl_nbr
						left outer join @GLInc as P5 on ZPTotNbrs.gl_nbr = P5.gl_nbr 


---****SELECTED PERIOD/FISCAL YEAR INFO****	

	--This section will sum the debit and credit together from the gltransaction information and then update It into the declared table above
	-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
	-- Changed to not link to it, so all the FY/Period can be updated later
	declare @AllTrans as table	(FiscalYear char(4),Period numeric(2),gl_nbr char(13),gl_class char(7),Amt numeric(14,2),gl_descr char(30))
								--,FyBegDate smalldatetime,EndDate smalldatetime)
	  
	;With
	ZAllTrans as
		(
		SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType,
				gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
				,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
					ELSE CAST('' as varchar(60)) end as JEtype
				-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
				-- Changed to not link to it, so all the FY/Period can be updated later					
				--,GLFISCALYRS.dBeginDate,GLFYRSDETL.ENDDATE 

		FROM	GLTRANSHEADER  
				inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
				inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
				inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
				-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
				-- Changed to not link to it, so all the FY/Period can be updated later
				--left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
				--inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
					
		where	@lcFy = GLTRANSHEADER.FY
				and @lcPer = GLTRANSHEADER.period
				and gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				--06/23/15 YS optimize the "where" and remove "*"
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = ''  then 1 else  
				--	 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.  
		) 
	-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
	-- Changed to not link to it, so all the FY/Period can be updated later		
	insert	@AllTrans 
			select	FY,PERIOD,GL_NBR,gl_Class,SUM(Debit-credit) as Amt,GL_DESCR--,dBeginDate,ENDDATE 
			from	ZAllTrans 
			where	JEtype <> 'CLOSE' 
			group by FY,PERIOD,GL_NBR,gl_Class,GL_DESCR--,dBeginDate,ENDDATE 
			order by GL_NBR

	--This will update the above @GLInc1 table with the calculated totals
		update @GLinc set Amt = (isnull(a1.Amt,0.00))from  @AllTrans as A1,@GLInc as B where A1.gl_nbr = B.gl_nbr 
	
--This below section will calculate the Closing values for Period/Fiscal Year Selected
		;
		with
		ZGlClosingNbrs as
					(				
					select	GL_NBR,tot_start,Tot_end
					from	@GLInc as C 
					where	gl_class = 'Closing'
					
					)			
					,
		ZIncClose as
					(
					select	ZGlClosingNbrs.gl_nbr,SUM(Amt) as TotAmt
					from	@GLInc as D,ZGlClosingNbrs
					where	D.gl_nbr between ZGlClosingNbrs.tot_start and ZGlClosingNbrs.tot_end
							and gl_class <> 'Title' 
							and gl_class <> 'Closing'
					GROUP BY ZGlClosingNbrs.gl_nbr		
					)	
					

		update	@GLInc set Amt = ISNULL(zincclose.TotAmt,0.00) 
		from	zglclosingnbrs 
				left outer join ZIncClose on ZGlClosingNbrs.gl_nbr = ZIncClose.gl_nbr 
				inner join @GLInc as E on ZGlClosingNbrs.gl_nbr = e.gl_nbr 


--This below section will calculate the Total value for Period/Fiscal Year Selected			
				;
				with
				ZIncTotNbrs as
							(				
							select	GL_NBR,tot_start,Tot_end
							from	@GLInc as F 
							where	gl_class = 'Total'
							)	
							,
				ZIncTotDr as
							(
							select	zIncTotNbrs.gl_nbr,sum(amt) as TotAmtDr
							from	@GLInc as G,ZIncTotNbrs
							where	G.gl_nbr between ZIncTotNbrs.tot_start and ZIncTotNbrs.tot_end
									and Norm_Bal = 'DR'
									and gl_class <> 'Total'
									and gl_class <> 'Closing'
							group by zinctotnbrs.gl_nbr
							)		
							,
				zIncTotCr as
							(
							select	zIncTotNbrs.gl_nbr,sum(amt) as TotAmtCr
							from	@GLInc as H, ZIncTotNbrs
							where	H.gl_nbr between ZIncTotNbrs.tot_start and ZIncTotNbrs.tot_end
									and Norm_Bal = 'CR'
									and gl_class <> 'Total'
									and gl_class <> 'Closing'
							group by zinctotnbrs.gl_nbr 
							)	

				update	@GLInc set Amt = (ISNULL(zinctotdr.TotAmtdr,0.00)) + (ISNULL(zinctotcr.totamtcr,0.00))  
				from	ZIncTotNbrs 
						left outer join ZIncTotDr on ZIncTotNbrs.gl_nbr = ZIncTotDr.gl_nbr
						left outer join zIncTotCr on ZIncTotNbrs.gl_nbr = zinctotcr.gl_nbr
						inner join @GLInc as I on ZIncTotNbrs.gl_nbr = I.gl_nbr 				

	--Inserts the Period/Fiscal Year Selected values into the main table above
	update @GLInc set FiscalYear = f1.FiscalYear,Period = f1.Period,EndDate = f1.EndDate,PriorFy = f1.PriorFy,PriorPeriod = f1.PriorPeriod,PriorEndDate = f1.PriorEndDate
			--,LIC_NAME = micssys.LIC_NAME  
			from @fyrs as F1 
			--06/23/15 ys remove micssys
			--cross join MICSSYS

--The below will gather the information from the Declared table (@GLINC1) and put them into the final results
/*05/07/2015 DRP:
--if (@lcShowAll = 'No')
--	begin
--	select	t1.Tot_Start,T1.tot_end,t1.Norm_Bal,t1.GLTYPE,t1.gl_descr,t1.gl_class,t1.GL_NBR,t1.Amt,t1.long_descr,t1.glTypeDesc,t1.FiscalYear,t1.Period,t1.EndDate
--			,t1.PriorAmt,t1.PriorFY,t1.PriorPeriod,t1.PriorEndDate--,t1.LIC_NAME
--	from	(
--			select	gb1.tot_start,gb1.tot_end,gb1.Norm_Bal,gb1.GLTYPE,gl_descr,gb1.gl_class,gb1.GL_NBR,Amt,long_descr,glTypeDesc,FiscalYear,Period,EndDate,PriorAmt,PriorFY,PriorPeriod,PriorEndDate--,LIC_NAME
--			from	@GLInc as GB1
--			) T1 
--	where t1.Amt+t1.PriorAmt <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
--	order by gl_nbr
--end

--	else if (@lcShowAll = 'Yes')
--	select	gb1.tot_start,gb1.tot_end,gb1.Norm_Bal,gb1.GLTYPE,gl_descr,gb1.gl_class,gb1.GL_NBR,Amt,long_descr,glTypeDesc,FiscalYear,Period,EndDate,PriorAmt,PriorFY,PriorPeriod,PriorEndDate--,LIC_NAME
--	from	@GLInc as GB1

--	order by gl_nbr
05/07/2015 DRP:  Replaced by the below*/

if (@lcShowAll = 'No')
	begin
	select	t1.Tot_Start,T1.tot_end,t1.Norm_Bal,t1.GLTYPE,t1.gl_descr,t1.gl_class,t1.GL_NBR
			,case when T1.gl_class = 'Posting' then -Amt else
			case when T1.Norm_Bal = 'DR' and T1.gl_class = 'Total  ' then -Amt else 
				case when T1.Norm_Bal = 'CR' and T1.gl_class ='Total' then abs(Amt) else
					case when T1.Norm_Bal = 'DR' and T1.gl_class  = 'Closing' then Amt else
						case when T1.Norm_Bal = 'CR' and T1.gl_class = 'Closing' then -Amt else
							cast(0.00 as numeric(14,2)) end end end end end as Amt
			,t1.long_descr,t1.glTypeDesc,t1.FiscalYear,t1.Period,t1.EndDate
			,case when T1.gl_class = 'Posting' then -PriorAmt else
			case when T1.Norm_Bal = 'DR' and T1.gl_class = 'Total  ' then -PriorAmt else 
				case when T1.Norm_Bal = 'CR' and T1.gl_class ='Total' then abs(PriorAmt) else
					case when T1.Norm_Bal = 'DR' and T1.gl_class  = 'Closing' then PriorAmt else
						case when T1.Norm_Bal = 'CR' and T1.gl_class = 'Closing' then -PriorAmt else
							cast(0.00 as numeric(14,2)) end end end end end as PriorAmt
			,t1.PriorFY,t1.PriorPeriod,t1.PriorEndDate
	from	(
			select	gb1.tot_start,gb1.tot_end,gb1.Norm_Bal,gb1.GLTYPE,gl_descr,gb1.gl_class,gb1.GL_NBR,Amt,long_descr,glTypeDesc,FiscalYear,Period,EndDate,PriorAmt,PriorFY,PriorPeriod,PriorEndDate--,LIC_NAME
			from	@GLInc as GB1
			) T1 
	where t1.Amt+t1.PriorAmt <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
	order by gl_nbr
end

	else if (@lcShowAll = 'Yes')
	select	GB1.Tot_Start,GB1.tot_end,GB1.Norm_Bal,GB1.GLTYPE,GB1.gl_descr,GB1.gl_class,GB1.GL_NBR
			,case when GB1.gl_class = 'Posting' then -Amt else
			case when GB1.Norm_Bal = 'DR' and GB1.gl_class = 'Total  ' then -Amt else 
				case when GB1.Norm_Bal = 'CR' and GB1.gl_class ='Total' then abs(Amt) else
					case when GB1.Norm_Bal = 'DR' and GB1.gl_class  = 'Closing' then Amt else
						case when GB1.Norm_Bal = 'CR' and GB1.gl_class = 'Closing' then -Amt else
							cast(0.00 as numeric(14,2)) end end end end end as Amt
			,GB1.long_descr,GB1.glTypeDesc,GB1.FiscalYear,GB1.Period,GB1.EndDate
			,case when GB1.gl_class = 'Posting' then -PriorAmt else
			case when GB1.Norm_Bal = 'DR' and GB1.gl_class = 'Total  ' then -PriorAmt else 
				case when GB1.Norm_Bal = 'CR' and GB1.gl_class ='Total' then abs(PriorAmt) else
					case when GB1.Norm_Bal = 'DR' and GB1.gl_class  = 'Closing' then PriorAmt else
						case when GB1.Norm_Bal = 'CR' and GB1.gl_class = 'Closing' then -PriorAmt else
							cast(0.00 as numeric(14,2)) end end end end end as PriorAmt
			,GB1.PriorFY,GB1.PriorPeriod,GB1.PriorEndDate
	from	@GLInc as GB1

	order by gl_nbr
 
End
					