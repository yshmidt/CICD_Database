
-- =============================================
-- Author:		Debbie
-- Create date: 08/01/2012
-- Description:	Created for the Income Statement Report
-- Reports Using Stored Procedure:  glincst1.rpt
-- Modifications:	04/05/2013 DRP:  upon review of the procedure Yelena found that I could make it a bit cleaner as far as how I was populating the EndDate and Lic_name information.
--					12/10/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
--					05/07/2015 DRP:  added @userId . . . Added  [or @lcDiv = ''] to the below where statements so if the user leaves the parameter blank on the Cloud it will then return all Division.
--									 removed lic_name from the results.  I can gather that info on the report itself.
--									 replaced the @lcShowAll = 'No' and @lcShowAll = 'Yes' sections with a different select statement so I could reflect the correct positive or negative value the the End_Bal fields.  Prior to this change I was doing this on the CR, but in Cloud we need the Quickview to also be accurate.
--					06/23/15 YS:	optimize the "where" and remove "*"
--					01/28/2016 YS & DRP:  Per Enhancement request we have added a new Percnt field to the results.  Yelena helped me determine how to get the correct Total Value to use in the New Percnt field.  It became more difficult if there happen to be a Totaling range within another Totally range.     
--					04/22/15 DRP:	Found that the Percnt formula within the (@lcShowAll = 'No') section below did not account if the null values. changed 
--									<<CASE WHEN I.gl_class = 'Total' then (abs(I.Amt/I.Amt)*100) ELSE	case when I.gl_class = 'Closing' then null ELSE	CASE WHEN l.totamt is null then 0.00 else (abs(i.Amt)/l.totamt)*100 end END end AS Percnt>>  TO BE  <<,CASE WHEN I.gl_class = 'Total' then (abs(I.Amt/nullif(I.Amt,0))*100) ELSE case when I.gl_class = 'Closing' then null ELSE CASE WHEN l.totamt is null then 0.00 else (abs(i.Amt)/nullif(l.totamt,0))*100 end END end AS Percnt>>	
-- 08/31/2020 VL:	Debbie talked with a customer that the percentage should not be calcualted by the sum of that group, it should be divided by the sales amount. CAPA 2956
-- =============================================
CREATE PROCEDURE [dbo].[rptGlIncomeStmt]
--declare
		@lcFy as char(4) = '2015'
		,@lcPer as int = '6'
		,@lcShowAll as char(3) = 'No'
		,@lcDiv as char(2) = null		--12/10/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin

	
declare @GLInc1 as table (Tot_Start char(13),Tot_End char(13),Norm_Bal char(2),GlType char(3),gl_descr char(30),gl_class char(7),gl_nbr char(13),glTypeDesc char(20)
						,LONG_DESCR char(52),FiscalYear char(4),Period numeric(2),Amt numeric(14,2),EndDate smalldatetime,prcnt numeric(6,3))
						--,Lic_name char(40))	--01/28/2016 DRP:  Removed

-- 08/31/20 VL added to get the total sales amount to calculate percentage later
DECLARE @SalesAmount numeric(14,2)

--This section will gather the gl account detail and insert It into the table above
insert	@GLInc1								
		Select	tot_start,tot_end,norm_bal,gltypes.GLTYPE,Gl_descr,Gl_nbrs.Gl_class,Gl_nbrs.Gl_nbr,Gltypes.Gltypedesc,gl_nbrs.LONG_DESCR
				,null as FiscalYear,null as Period, CAST (0.00 as numeric(14,2))as Amt,null as EndDate,0.00
				--,CAST('' as CHAR(40))	--01/28/2016 DRP:  Removed

		FROM	Gl_nbrs, Gltypes 

		WHERE	Gltypes.Gltype = Gl_nbrs.Gltype 
				AND Gl_nbrs.stmt = 'INC' 
				---06/23/15 YS optimize the "where" and remove "*"
				and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
				--and 1 = case when @lcDiv is null OR @lcDiv = '*'  or @lcDiv = '' then 1 else  
				--	 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
		order by gl_nbr
--select * from @GLInc1

--This section will sum the debit and credit together from the gltransaction information and then update It into the declared table above
/* 04/05/2013 DRP: the below declared table @AllTrans used to have EndDate and Lic_name, but it was found that they were not needed at this point of the code and were removed
					So I also removed it from the ZAllTrans Select, From and Insert sections*/
/* declare @AllTrans as table (FiscalYear char(4),Period numeric(2),gl_nbr char(13),gl_class char(7),Amt numeric(14,2),gl_descr char(30),EndDate smalldatetime,Lic_Name Char(40))*/
	declare @AllTrans as table (FiscalYear char(4),Period numeric(2),gl_nbr char(13),gl_class char(7),Amt numeric(14,2),gl_descr char(30))
  
;With
ZAllTrans as
	(
	SELECT	GLTRANSHEADER.FY,cast (GLTRANSHEADER.PERIOD as CHAR(2)) as Period,GltransHeader.TransactionType,
			gltrans.GL_NBR,GL_NBRS.GL_CLASS,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT
			,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT rtrim(gljehdr.JETYPE) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD )
				ELSE CAST('' as varchar(60)) end as JEtype  --,GLFYRSDETL.ENDDATE,MICSSYS.LIC_NAME 

	FROM	GLTRANSHEADER  
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
			--left outer join GLFYRSDETL on gltransheader.fk_fydtluniq = GLFYRSDETL.FYDTLUNIQ
			--cross join MICSSYS
				
	where	@lcFy = GLTRANSHEADER.FY
			and @lcPer = GLTRANSHEADER.period
			and gl_nbrs.STMT = 'INC'
			and GL_CLASS = 'Posting'
			---06/23/15 YS optimize the "where" and remove "*"
			and (@lcDiv is null or @lcDiv = '' or PATINDEX('%[0-9][-]'+@lcDiv+'[-]%[0-9]', gl_nbrs.gl_nbr)<>0)
			--and 1 = case when @lcDiv is null OR @lcDiv = '*' or @lcDiv = '' then 1 else  
			--		 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/10/2014 DRP:  Added this filter to work with the Division parameter. 
	) 
	
insert	@AllTrans 
		select	FY,PERIOD,GL_NBR,gl_Class,SUM(Debit-credit) as Amt,GL_DESCR --,ENDDATE,lic_name 
		from	ZAllTrans 
		where	JEtype <> 'CLOSE' 
		group by FY,PERIOD,GL_NBR,gl_Class,GL_DESCR --,ENDDATE,LIC_NAME 
		order by GL_NBR




--04/05/2013 DEBBIE:  per Yelena's instruction I removed the two individual update codes and replaced with this individual line of code below

--This will update the above @GLInc1 table with the calculated totals
	/*04/05/2013 DRP:  needed to only update the @GLinc1 table with the Amt.  removed the FY, Period, endDate from the update */
	--update @GLinc1 set Amt = (isnull(a1.Amt,0.00)),FiscalYear=a1.FiscalYear ,Period=a1.Period, EndDate=a1.EndDate  from  @AllTrans as A1,@GLInc1 as B where A1.gl_nbr = B.gl_nbr 
		update @GLinc1 set Amt = (isnull(a1.Amt,0.00)) from  @AllTrans as A1,@GLInc1 as B where A1.gl_nbr = B.gl_nbr 

/*04/05/2013 DRP:  inserted the below*/
--Using the below view to get the Period End date.  
	DECLARE @T as dbo.AllFYPeriods
		INSERT INTO @T EXEC GlFyrstartEndView @lcfy	
			declare @fy char(4),@period int,@enddate smalldatetime,@fyDtlUniq uniqueidentifier
				select  @enddate=EndDate,@fyDtlUniq =FyDtlUniq from @t where FiscalYr =@lcfy and Period=@lcper 
--This will populate the table with the FY, Period and EndDate
	update	@GLInc1 set FiscalYear = @lcFy,Period = @lcPer, EndDate = @enddate
			--,Lic_name = MICSSYS.LIC_NAME	--05/07/2015 DRP:  Removed 
			-- 06/23/15 YS remove micssys
			--from MICSSYS

/*04/05/2013 DRP: The above replaced the below */
	/*
		--This will update the above @GLInc1 table with the calculated totals
			update @GLinc1 set Amt = (isnull(a1.Amt,0.00))from  @AllTrans as A1,@GLInc1 as B where A1.gl_nbr = B.gl_nbr 

		--This will update the above table with the FY,Period and Enddate information 
			update @GLInc1 set fiscalyear = a2.fiscalyear,period = a2.period,EndDate = a2.enddate,Lic_name = a2.Lic_Name from @AllTrans as A2
	*/

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


/*
if (@lcShowAll = 'No')
begin
select * from @GLInc1 where Amt <> 0.00 or gl_class ='Title' or gl_class = 'Heading'
order by gl_nbr
end 

else if (@lcShowAll = 'Yes')
select * from @GLInc1
order by gl_nbr
*/	--05/07/2015 DRP:  Is replaced by the below.

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

if (@lcShowAll = 'No')
begin
select	I.Tot_Start,I.Tot_End,I.Norm_Bal,I.GlType,I.gl_descr,I.gl_class,I.gl_nbr,I.glTypeDesc,I.LONG_DESCR,I.FiscalYear,I.Period
		,case when I.gl_class = 'Posting' then -Amt else
			case when I.Norm_Bal = 'DR' and I.gl_class = 'Total  ' then -Amt else 
				case when I.Norm_Bal = 'CR' and I.gl_class ='Total' then abs(Amt) else
					case when I.Norm_Bal = 'DR' and I.gl_class  = 'Closing' then Amt else
						case when I.Norm_Bal = 'CR' and I.gl_class = 'Closing' then -Amt else
							cast(0.00 as numeric(14,2)) end end end end end as Amt,I.EndDate
		-- 08/31/20 VL changed to use sales amount to calculate percentage
		--,CASE WHEN I.gl_class = 'Total' then (abs(I.Amt/nullif(I.Amt,0))*100) ELSE	
		--	case when I.gl_class = 'Closing' then null ELSE
		--	CASE WHEN l.totamt is null then 0.00 else (abs(i.Amt)/nullif(l.totamt,0))*100 end END end AS Percnt		--01/28/2016 YS: Added	--04/22/16 DRP:  changed the formula to include the nullif
		,CASE WHEN @SalesAmount <> 0 THEN ROUND(ABS((I.Amt/@SalesAmount)*100),2) ELSE 0.00 END AS Percnt
		,isnull(CASE WHEN I.gl_class = 'Total' THEN I.AMT ELSE L.totamt END, 0.00) AS TotAmt	--01/28/2016 YS:  added

from	@GLInc1 I
		outer apply (SELECT	t.*,abs(i2.amt) as totamt 
					 from	@totallevel t 
							inner join @GLInc1 I2 on t.parentTotal=i2.gl_nbr  
					 where	i.gltype=t.GlType and i.gl_nbr between t.Parenttot_start and t.parenttotal_end 
							and i.gl_class<>'Total') L	--01/28/2016 YS:  Added in order to get the Total Value to calculate the Percentage.
where	Amt <> 0.00 or I.gl_class ='Title' or I.gl_class = 'Heading'
order by gl_nbr
end 


else if (@lcShowAll = 'Yes')
select	I.Tot_Start,I.Tot_End,I.Norm_Bal,I.GlType,I.gl_descr,I.gl_class,I.gl_nbr,I.glTypeDesc,I.LONG_DESCR,I.FiscalYear,I.Period
		,case when I.gl_class = 'Posting' then -Amt else
			case when I.Norm_Bal = 'DR' and I.gl_class = 'Total  ' then -Amt else 
				case when I.Norm_Bal = 'CR' and I.gl_class ='Total' then abs(Amt) else
					case when I.Norm_Bal = 'DR' and I.gl_class  = 'Closing' then Amt else
						case when I.Norm_Bal = 'CR' and I.gl_class = 'Closing' then -Amt else
							cast(0.00 as numeric(14,2)) end end end end end as Amt,I.EndDate 
		-- 08/31/20 VL changed to use sales amount to calculate percentage
		--,CASE WHEN I.gl_class = 'Total' then (abs(I.Amt/nullif(I.Amt,0))*100) ELSE	
		--	CASE WHEN l.totamt is null then 0.00 else (abs(i.Amt)/nullif(l.totamt,0))*100 end END AS Percnt	--01/28/2016 YS: Added
		,CASE WHEN @SalesAmount <> 0 THEN ROUND(ABS((I.Amt/@SalesAmount)*100),2) ELSE 0.00 END AS Percnt
		,isnull(CASE WHEN I.gl_class = 'Total' THEN I.AMT ELSE L.totamt END, 0.00) AS TotAmt	--01/28/2016 YS:  added

from	@GLInc1 I
		outer apply (SELECT	t.*,abs(i2.amt) as totamt 
							 from	@totallevel t 
									inner join @GLInc1 I2 on t.parentTotal=i2.gl_nbr  
							 where	i.gltype=t.GlType and i.gl_nbr between t.Parenttot_start and t.parenttotal_end 
									and i.gl_class<>'Total') L	--01/28/2016 YS:  Added in order to get the Total Value to calculate the Percentage.
order by gl_nbr

end