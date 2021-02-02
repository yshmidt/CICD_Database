
-- =============================================
-- Author:		Debbie
-- Create date: 08/01/2012
-- Description:	Created for the Income Statement ~ Current Period/YTD Report
-- Reports Using Stored Procedure:  glincst2.rpt // glincst5.rpt
-- Modifications:  05/06/2014 DRP:  Found that if YTD was 0.00 that it was incorrectly dropping the line even if the Current had a balance.
--				   12/10/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
--					05/07/2015 DRP:  added @userId . . . Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division.
--									 removed lic_name from the results.  I can gather that info on the report itself.
--									 replaced the @lcShowAll = 'No' and @lcShowAll = 'Yes' sections with a different select statement so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
--06/23/15 YS optimize the "where" and remove "*"
-- 08/31/2020 VL:	Debbie talked with a customer that the percentage should not be calcualted by the sum of that group, it should be divided by the sales amount. CAPA 2956
-- 09/08/2020 VL:	Added percentage for YTD column
-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
-- Changed to not link to it, so all the FY/Period can be updated later
-- =============================================
CREATE PROCEDURE [dbo].[rptGlIncStmtCurrentYTD]
--declare
		@lcFy as char(4) = ''
		,@lcPer as int = ''
		,@lcShowAll as char(3) = 'no'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin

--This table will gather the totals for the Year to Date values
declare @GLYTD as table (Norm_Bal char(2),gl_class char(7),gl_nbr char(13),YTDAmt numeric(14,2),Lic_name char(40))	

--This table will gather the Selected Period detailed information and values	
declare @GLInc1 as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13),glTypeDesc char(20)
						,LONG_DESCR char(52),FiscalYear char(4),Period numeric(2),Amt numeric(14,2)
						,FyBegDate smalldatetime,EndDate smalldatetime)
						--,Lic_name char(40))	--05/07/2015 DRP:  Removed

-- 08/31/20 VL added to get the total sales amount to calculate percentage later
-- 09/08/2020 VL:	Added percentage for YTD column, so added @SalesAmountYTD
DECLARE @SalesAmount numeric(14,2), @SalesAmountYTD numeric(14,2)

--****SELECTED PERIOD/FISCAL YEAR INFO****	
	--This section will gather the gl account detail and insert It into the table above
	insert	@GLInc1								
			Select	tot_start,tot_end,norm_bal,gltypes.GLTYPE,Gl_descr,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr,Gltypes.Gltypedesc,gl_nbrs.LONG_DESCR
					,null as FiscalYear,null as Period, CAST (0.00 as numeric(14,2))as Amt,NULL AS FyBegDate,null as EndDate
					--,CAST('' as CHAR(40))

			FROM	Gl_nbrs, Gltypes 

			WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
					AND Gl_nbrs.stmt = 'INC'
					--06/23/15 YS optimize the "where" and remove "*"
					and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
					--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
					-- case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.  
			order by gl_nbr


	--This section will sum the debit and credit together from the gltransaction information and then update It into the declared table above
	-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
	-- Changed to not link to it, so all the FY/Period can be updated later
	declare @AllTrans as table	(FiscalYear char(4),Period numeric(2),gl_nbr char(13),gl_class char(7),Amt numeric(14,2),gl_descr char(30))
								--,FyBegDate smalldatetime,EndDate smalldatetime)
								--,Lic_Name Char(40)) 05/07/2015 DRP: Removed
	  
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
					--,MICSSYS.LIC_NAME 

		FROM	GLTRANSHEADER  
				inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
				inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
				inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
				-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
				-- Changed to not link to it, so all the FY/Period can be updated later
				--left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
				--inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
				--cross join MICSSYS
					
		where	@lcFy = GLTRANSHEADER.FY
				and @lcPer = GLTRANSHEADER.period
				and gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				--06/23/15 YS optimize the "where" and remove "*"
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
				--	 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
		) 

	-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
	-- Changed to not link to it, so all the FY/Period can be updated later
	insert	@AllTrans 
			select	FY,PERIOD,GL_NBR,gl_Class,SUM(Debit-credit) as Amt,GL_DESCR--,dBeginDate,ENDDATE
			--,lic_name 
			from	ZAllTrans 
			where	JEtype <> 'CLOSE' 
			group by FY,PERIOD,GL_NBR,gl_Class,GL_DESCR--,dBeginDate,ENDDATE
			order by GL_NBR

	--This will update the above @GLInc1 table with the calculated totals
		update @GLinc1 set Amt = (isnull(a1.Amt,0.00))from  @AllTrans as A1,@GLInc1 as B where A1.gl_nbr = B.gl_nbr 


	--This below section will calculate the Closing values
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
						select	ZGlClosingNbrs.gl_nbr,SUM(Amt) as TotAmt
						from	@GLInc1 as D,ZGlClosingNbrs
						where	D.gl_nbr between ZGlClosingNbrs.tot_start and ZGlClosingNbrs.tot_end
								and gl_class <> 'Title' 
								and gl_class <> 'Closing'
						GROUP BY ZGlClosingNbrs.gl_nbr		
						)	
	update	@GLInc1 set Amt = ISNULL(zincclose.TotAmt,0.00) 
	from	zglclosingnbrs 
					left outer join ZIncClose on ZGlClosingNbrs.gl_nbr = ZIncClose.gl_nbr 
					inner join @GLInc1 as E on ZGlClosingNbrs.gl_nbr = e.gl_nbr 

	--This below section will calculate the Total value 			
			;
			with
			ZIncTotNbrs as
						(				
						select	GL_NBR,tot_start,Tot_end
						from	@GLInc1 as F 
						where	gl_class = 'Total'
						)	
						,
			ZIncTotDr as
						(
						select	zIncTotNbrs.gl_nbr,sum(amt) as TotAmtDr
						from	@GLInc1 as G,ZIncTotNbrs
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
						from	@GLInc1 as H, ZIncTotNbrs
						where	H.gl_nbr between ZIncTotNbrs.tot_start and ZIncTotNbrs.tot_end
								and Norm_Bal = 'CR'
								and gl_class <> 'Total'
								and gl_class <> 'Closing'
						group by zinctotnbrs.gl_nbr 
						)	

			update	@GLInc1 set Amt = (ISNULL(zinctotdr.TotAmtdr,0.00)) + (ISNULL(zinctotcr.totamtcr,0.00))  
			from	ZIncTotNbrs 
					left outer join ZIncTotDr on ZIncTotNbrs.gl_nbr = ZIncTotDr.gl_nbr
					left outer join zIncTotCr on ZIncTotNbrs.gl_nbr = zinctotcr.gl_nbr
					inner join @GLInc1 as I on ZIncTotNbrs.gl_nbr = I.gl_nbr 



--****YEAR TO DATE INFO****	
	--Gathers the detailed information for the YTD and inserts it into the @GLYTD table declared above
	insert	@GLyTD								
			Select	GLTYPES.NORM_BAL,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr, CAST (0.00 as numeric(14,2))as Amt,CAST('' as CHAR(40))

			FROM	Gl_nbrs, Gltypes 

			WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
					AND Gl_nbrs.stmt = 'INC' 
					--06/23/15 YS optimize the "where" and remove "*"
					and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
					--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
					-- case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
			order by gl_nbr
	
	declare @AllTransYTD as table (gl_class char(7),gl_nbr char(13),YTDAmt numeric(14,2))
									--,Lic_Name Char(40))

	--This section will sum the debit and credit together from the gltransaction information and then update It into the declared table above  
	;With
	ZAllTransYTD as
		(
		SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType,
				gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
				,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
					ELSE CAST('' as varchar(60)) end as JEtype
					-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
					-- Changed to not link to it, so all the FY/Period can be updated later
					--,GLFYRSDETL.ENDDATE
					--,MICSSYS.LIC_NAME 

		FROM	GLTRANSHEADER  
				inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
				inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
				inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
				-- 01/29/21 VL found somehow the FYDTLUNIQ saved in Glfyrsdetl became different from the one saved in Gltransheader, maybe the user re-create FY?
				-- Changed to not link to it, so all the FY/Period can be updated later
				--left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
				--cross join MICSSYS
					
		where	@lcFy = GLTRANSHEADER.FY
				and @lcPer >= GLTRANSHEADER.period
				and gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				--06/23/15 YS optimize the "where" and remove "*"
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
				--	 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
		) 
		
	insert	@AllTransYTD 
			select	gl_Class,gl_nbr,SUM(Debit-credit) as YTDAmt
			--,lic_name 
			from	ZAllTransYTD 
			where	JEtype <> 'CLOSE' 
			group by gl_Class,gl_nbr order by GL_NBR
--select * from @AllTransYTD		
	--This will update the above @GLYTD table with the calculated totals
		update @GLYTD set YTDAmt = (isnull(YTD2.YTDAmt,0.00)) from  @AllTransYTD as YTD2,@GLytd as B where YTD2.gl_nbr = B.gl_nbr 
--select * from @GLYTD
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



--This will update the above table with the FY,Period, FyBegDate and Enddate information 
		-- 01/29/21 VL changed to update FY information not from @AllTrans
		--update @GLInc1 set fiscalyear = a2.fiscalyear,period = a2.period,EndDate = a2.enddate,FyBegDate = a2.FyBegDate from @AllTrans as A2

		--Using the below view to get the Period End date.  
		DECLARE @T as dbo.AllFYPeriods
		INSERT INTO @T EXEC GlFyrstartEndView @lcfy	
		DECLARE @fy char(4),@period int,@enddate smalldatetime,@fyDtlUniq uniqueidentifier
		SELECT @enddate=EndDate,@fyDtlUniq =FyDtlUniq from @t where FiscalYr =@lcfy and Period=@lcper 
		--This will populate the table with the FY, Period and EndDate
		UPDATE @GLInc1 set FiscalYear = @lcFy,Period = @lcPer, EndDate = @enddate
		-- 01/29/21 VL added to update FyBegDate directly from GLFISCALYRS
		UPDATe @GLInc1 SET FyBegDate = dBeginDate FROM GLFISCALYRS WHERE [@GLInc1].FiscalYear = GLFISCALYRS.FISCALYR
			--,Lic_name = MICSSYS.LIC_NAME	--05/07/2015 DRP:  Removed 
			-- 06/23/15 YS remove micssys
			--from MICSSYS

		--update @GLYTD set Lic_name = MICSSYS.LIC_NAME from MICSSYS

						
--The below will gather the information from the two Declared tables (@GLYTD and @GLINC1) and put them into the final results
/*05/07/2015 DRP: 
--if (@lcShowAll = 'No')
--begin
--select	Tot_Start,Tot_End,YTD6.Norm_Bal,GLTYPE,gl_descr,J.gl_class,YTD6.GL_NBR,AMT,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE,YTDAMT
----,ytd6.Lic_name 
--from	@GLYTD AS YTD6
--		LEFT OUTER JOIN @GLInc1 AS J ON YTD6.GL_NBR = J.GL_NBR 
--/*05/06/2014 DRP:  needed to make sure that current would display if YTD had 0.00*/ 
----where YTD6.YTDAmt <> 0.00 or J.gl_class ='Title' or J.gl_class = 'Heading'
--where	(YTD6.YTDAmt <> 0.00 or amt <> 0.00) or J.gl_class ='Title' or J.gl_class = 'Heading'
--order by gl_nbr
--end

--else if (@lcShowAll = 'Yes')
--select	Tot_Start,Tot_End,YTD7.Norm_Bal,GLTYPE,gl_descr,K.gl_class,YTD7.GL_NBR,AMT,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE,YTDAMT
----,ytd7.Lic_name
--from	@GLYTD AS YTD7
--		LEFT OUTER JOIN @GLInc1 AS K ON YTD7.GL_NBR = K.GL_NBR 
--order by gl_nbr
--05/07/2015 REPLACED BY THE BELOW*/

-- 08/31/20 VL copied YS code from income statement current report 
/*  01/28/16 YS new addition for % calcl */
declare @totallevel table  (gl_nbr char(13),gl_descr char(30),gl_class char(7),GlType char(3),stmt char(3),Tot_Start char(13),Tot_End char(13),glevel int,gPath varchar(max),
parentTotal char(13),Parenttot_start char(13),parenttotal_end char(13) );
						
;
with glrange
as
(select	gl_nbr,gl_descr,gl_class,gltype,stmt,tot_start,tot_end,cast(0 as int) as glevel ,cast(gl_nbrs.gl_nbr as varchar(max)) as gPath  
 from	gl_nbrs 
 where	gl_class='Total' 
		and ( @lcdiv is null  or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0) 
		and status='Active' 
		and not exists (select 1 from gl_nbrs g2 where g2.gl_class='Total' and ( @lcdiv is null or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', g2.gl_nbr)<>0) and g2.status='Active'
						and gl_nbrs.gl_nbr<>g2.GL_NBR and gl_nbrs.tot_start between g2.tot_start and g2.tot_end and gl_nbrs.tot_end between g2.tot_start and g2.tot_end)
 UNION ALL
 select	gl_nbrs.gl_nbr,gl_nbrs.gl_descr,gl_nbrs.gl_class,gl_nbrs.gltype,gl_nbrs.stmt,gl_nbrs.tot_start,gl_nbrs.tot_end
		,gr.glevel+1,CAST(RTRIM(LTRIM(gr.gPath))+'/'+gl_nbrs.GL_NBR as varchar(max)) as path 
 from	gl_nbrs  
		inner join glrange gr on gl_nbrs.gl_nbr<>gr.GL_NBR and gl_nbrs.tot_start between gr.tot_start and gr.tot_end and gl_nbrs.tot_end between gr.tot_start and gr.tot_end
 where	gl_nbrs.gl_class='Total' 
		and (@lcdiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0) 
		and gl_nbrs.status='Active'
	)
	
	insert into @totallevel
	select	r.gl_nbr,r.gl_descr,r.gl_class,r.gltype,r.stmt,r.tot_start,r.tot_end,r.glevel,r.gPath,
			--reverse(substring(reverse(substring(r.gPath,1,LEN(r.gPath) - CHARINDEX('/', REVERSE(r.gPath)) + 1)),2,13)) as parentTotal,
			right(rtrim(gPath),13) as parentTotal,p.TOT_START as Parenttot_start,p.TOT_END as parenttotal_end 
			--from glrange R inner join gl_nbrs as P on reverse(substring(reverse(substring(r.gPath,1,LEN(r.gPath) - CHARINDEX('/', REVERSE(r.gPath)) + 1)),2,13))=p.gl_nbr
	from	glrange R 
			inner join gl_nbrs as P on right(rtrim(gPath),13)=p.gl_nbr
	where	exists (select 1 from (select gltype,max(glevel) as mlevel from  glrange r2 group by r2.gltype) T where t.gltype=r.gltype and t.mlevel=r.glevel)

/*  01/28/16 YS end of new addition for % calcl use the result below*/
  
--select T.*,gi.Amt from @totallevel t inner join @glinc1 gi on t.parentTotal=gi.gl_nbr order by gl_nbr

-- 08/31/20 VL get total sales amount
SELECT @SalesAmount = ISNULL(I.Amt,0)
	FROM @GLInc1 I INNER JOIN @totallevel T 
	ON I.GlType = T.GlType 
	AND I.gl_nbr = T.gl_nbr
	WHERE I.GlType = 'SAL'
	AND I.gl_class = 'Total'

-- 09/08/2020 VL:	Added percentage for YTD column
SELECT @SalesAmountYTD = ISNULL(YTDAMT,0)
	FROM @GLYTD Y INNER JOIN @GLInc1 I
	ON I.gl_nbr = Y.Gl_nbr
	INNER JOIN @totallevel T 
	ON I.GlType = T.GlType 
	AND I.gl_nbr = T.gl_nbr
	WHERE I.GlType = 'SAL'
	AND I.gl_class = 'Total'


if (@lcShowAll = 'No')
begin
select	Tot_Start,Tot_End,YTD6.Norm_Bal,GLTYPE,gl_descr,J.gl_class,YTD6.GL_NBR
		,case when J.gl_class = 'Posting' then -Amt else
			case when J.Norm_Bal = 'DR' and J.gl_class = 'Total  ' then -Amt else 
				case when J.Norm_Bal = 'CR' and J.gl_class ='Total' then abs(Amt) else
					case when J.Norm_Bal = 'DR' and J.gl_class  = 'Closing' then Amt else
						case when J.Norm_Bal = 'CR' and J.gl_class = 'Closing' then -Amt else
							cast(0.00 as numeric(14,2)) end end end end end as Amt
		,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE
		,case when J.gl_class = 'Posting' then -YTDAMT else
			case when J.Norm_Bal = 'DR' and J.gl_class = 'Total  ' then -YTDAMT else 
				case when J.Norm_Bal = 'CR' and J.gl_class ='Total' then abs(YTDAMT) else
					case when J.Norm_Bal = 'DR' and J.gl_class  = 'Closing' then YTDAMT else
						case when J.Norm_Bal = 'CR' and J.gl_class = 'Closing' then -YTDAMT else
							cast(0.00 as numeric(14,2)) end end end end end as YTDAMT
		-- 08/31/20 VL use sales amount to calculate percentage
		,CASE WHEN @SalesAmount <> 0 THEN ROUND(ABS((Amt/@SalesAmount)*100),2) ELSE 0.00 END AS Percnt
		-- 09/08/2020 VL:	Added percentage for YTD column
		,CASE WHEN @SalesAmountYTD <> 0 THEN ROUND(ABS((YTDAMT/@SalesAmountYTD)*100),2) ELSE 0.00 END AS PercntYTD
from	@GLYTD AS YTD6
		LEFT OUTER JOIN @GLInc1 AS J ON YTD6.GL_NBR = J.GL_NBR 
/*05/06/2014 DRP:  needed to make sure that current would display if YTD had 0.00*/ 
--where YTD6.YTDAmt <> 0.00 or J.gl_class ='Title' or J.gl_class = 'Heading'
where	(YTD6.YTDAmt <> 0.00 or amt <> 0.00) or J.gl_class ='Title' or J.gl_class = 'Heading'
order by gl_nbr
end

else if (@lcShowAll = 'Yes')
select	Tot_Start,Tot_End,YTD7.Norm_Bal,GLTYPE,gl_descr,K.gl_class,YTD7.GL_NBR
		,case when K.gl_class = 'Posting' then -Amt else
			case when K.Norm_Bal = 'DR' and K.gl_class = 'Total  ' then -Amt else 
				case when K.Norm_Bal = 'CR' and K.gl_class ='Total' then abs(Amt) else
					case when K.Norm_Bal = 'DR' and K.gl_class  = 'Closing' then Amt else
						case when K.Norm_Bal = 'CR' and K.gl_class = 'Closing' then -Amt else
							cast(0.00 as numeric(14,2)) end end end end end as Amt
		,LONG_DESCR,GLTYPEDESC,FISCALYEAR,PERIOD,FYBEGDATE,ENDDATE
		,case when K.gl_class = 'Posting' then -YTDAMT else
			case when K.Norm_Bal = 'DR' and K.gl_class = 'Total  ' then -YTDAMT else 
				case when K.Norm_Bal = 'CR' and K.gl_class ='Total' then abs(YTDAMT) else
					case when K.Norm_Bal = 'DR' and K.gl_class  = 'Closing' then YTDAMT else
						case when K.Norm_Bal = 'CR' and K.gl_class = 'Closing' then -YTDAMT else
							cast(0.00 as numeric(14,2)) end end end end end as YTDAMT
		-- 08/31/20 VL use sales amount to calculate percentage
		,CASE WHEN @SalesAmount <> 0 THEN ROUND(ABS((Amt/@SalesAmount)*100),2) ELSE 0.00 END AS Percnt
		-- 09/08/2020 VL:	Added percentage for YTD column
		,CASE WHEN @SalesAmountYTD <> 0 THEN ROUND(ABS((YTDAMT/@SalesAmountYTD)*100),2) ELSE 0.00 END AS PercntYTD
--,ytd7.Lic_name
from	@GLYTD AS YTD7
		LEFT OUTER JOIN @GLInc1 AS K ON YTD7.GL_NBR = K.GL_NBR 
order by gl_nbr
end					