
-- =============================================
-- Author:		Debbie
-- Create date: 08/03/2012
-- Description:	Created for the Income Statement ~ Date Range
-- Reports Using Stored Procedure:  glincst8.rpt 
-- Modified:	12/10/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter
--				05/07/2015 DRP:  added @userId . . . Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division.
--								 removed lic_name from the results.  I can gather that info on the report itself.
--								 replaced the @lcShowAll = 'No' and @lcShowAll = 'Yes' sections with a different select statement so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
-- 07/25/17 DRP:  it was reported whem users would run the Date ranges to cross over different FY's that then the Values would no longer be accurate.  Upon review I believe it was due to the Group By that I had in the <<insert	@AllTrans>> section.
-- =============================================
CREATE PROCEDURE [dbo].[rptGlIncStmtDateRange]
--declare
		@lcDateStart as smalldatetime= NULL
		,@lcDateEnd as smalldatetime = NULL
		,@lcShowAll as char(3) = 'No'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin

--*****DECLARES THE TABLE WHERE THE FINAL REPORTS RESULTS WILL BE INSERTED*****
	--This table will gather detailed information for the final results
	declare @GLInc1 as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13),glTypeDesc char(20)
							,LONG_DESCR char(52),Amt numeric(14,2))
							--,Lic_name char(40)) --05/07/2015 DRP:  REMOVED
							
							
	--This section will gather the gl account detail and insert It into the table above
		insert	@GLInc1								
				Select	tot_start,tot_end,norm_bal,gltypes.GLTYPE,Gl_descr,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr,Gltypes.Gltypedesc,gl_nbrs.LONG_DESCR
						, CAST (0.00 as numeric(14,2))as Amt--,CAST ('' as CHAR(40)) 05/07/2015 DRP: REMOVED 

				FROM	Gl_nbrs, Gltypes 

				WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
						AND Gl_nbrs.stmt = 'INC' 
						and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = ''  then 1 else  
									case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.
				order by gl_nbr


	declare @AllTrans as table (gl_nbr char(13),gl_class char(7),Amt numeric(14,2))
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
				left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
				inner join glfiscalyrs on  glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ

							
		wherE gl_nbrs.STMT = 'INC'
				and GL_CLASS = 'Posting'
				and gltransheader.trans_dt>=@lcDateStart AND gltransheader.TRANS_DT<@lcDateEnd+1
				and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = ''  then 1 else  
							case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter.

		) 
	insert	@AllTrans
			select	GL_NBR,gl_Class,SUM(Debit-credit) as YTDAmt
			from	ZAllTrans
			where	JEtype <> 'CLOSE'
			--group by FY,GL_NBR,gl_Class order by GL_NBR	--07/25/17 DRP:  replaced with the below group by 
			group by GL_NBR,gl_Class order by GL_NBR


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


--This will update the above table with the FY,Period, FyBegDate and Enddate information 
		--update @GLInc1 set Lic_name = MICSSYS.LIC_NAME from MICSSYS --05/07/2015 DRP: REMOVED

						
--The below will gather the information from the two Declared tables (@GLYTD and @GLINC1) and put them into the final results
/*05/07/2015 DRP: 
--if (@lcShowAll = 'No')
--begin
--select	Tot_Start,Tot_End,norm_bal,GLTYPE,gl_descr,J.gl_class,GL_NBR,AMT,LONG_DESCR,GLTYPEDESC,Lic_name 
--from	@GLInc1 AS J  
--where Amt <> 0.00 or J.gl_class ='Title' or J.gl_class = 'Heading'
--order by gl_nbr
--end

--else if (@lcShowAll = 'Yes')
--select	Tot_Start,Tot_End,Norm_Bal,GLTYPE,gl_descr,K.gl_class,GL_NBR,AMT,LONG_DESCR,GLTYPEDESC,Lic_name
--from	@GLInc1 AS K  
--order by gl_nbr
--05/07/2015 REPLACED BY THE BELOW*/

if (@lcShowAll = 'No')
begin
select	Tot_Start,Tot_End,norm_bal,GLTYPE,gl_descr,J.gl_class,GL_NBR
		,case when J.gl_class = 'Posting' then -AMT else
			case when J.Norm_Bal = 'DR' and J.gl_class = 'Total  ' then -AMT else 
				case when J.Norm_Bal = 'CR' and J.gl_class ='Total' then abs(AMT) else
					case when J.Norm_Bal = 'DR' and J.gl_class  = 'Closing' then AMT else
						case when J.Norm_Bal = 'CR' and J.gl_class = 'Closing' then -AMT else
							cast(0.00 as numeric(14,2)) end end end end end as AMT
		,LONG_DESCR,GLTYPEDESC 
from	@GLInc1 AS J  
where Amt <> 0.00 or J.gl_class ='Title' or J.gl_class = 'Heading'
order by gl_nbr
end

else if (@lcShowAll = 'Yes')
select	Tot_Start,Tot_End,Norm_Bal,GLTYPE,gl_descr,K.gl_class,GL_NBR
		,case when K.gl_class = 'Posting' then -AMT else
			case when K.Norm_Bal = 'DR' and K.gl_class = 'Total  ' then -AMT else 
				case when K.Norm_Bal = 'CR' and K.gl_class ='Total' then abs(AMT) else
					case when K.Norm_Bal = 'DR' and K.gl_class  = 'Closing' then AMT else
						case when K.Norm_Bal = 'CR' and K.gl_class = 'Closing' then -AMT else
							cast(0.00 as numeric(14,2)) end end end end end as AMT
		,LONG_DESCR,GLTYPEDESC
from	@GLInc1 AS K  
order by gl_nbr


end