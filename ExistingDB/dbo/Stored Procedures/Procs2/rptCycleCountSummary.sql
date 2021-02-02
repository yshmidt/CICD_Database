
-- =============================================
-- Author:			Debbie
-- Create date:		07/22/2013
-- Description:		Compiles the details for the Cycle Count Summary Report
-- Used On:			cycsumm
-- Modifications:	12/03/13 YS use 'All' in place of '*'
----					11/18/16 DRP:  It was brought to our attention that this report functioned differently from the VFP version
----									The DATEDIFF need to be changed from the CCDATE to SYS_DATE
----									added ccrecncl = 1:  so it will only pull fwd into the results once it has been reconciled within the count
----									added STDCOSTPR to the results because it was added to the ccrecord table. 
--  04/13/17 YS new fields PRFCUSED_uniq char(10),FUNCfcUsed_uniq char(10),were added to ccrecord table, need to update @Ccount	
--  05/23/17 YS move UniqMfgrHd prior to STDCOSTPR 
--- 08/15/17 YS changed the entire SP
-- =============================================
CREATE PROCEDURE  [dbo].[rptCycleCountSummary]

		@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		-- 12/03/13 YS use 'All' in place of '*'
		,@lcUniqWh as varchar (max) = 'All'		
		,@lcClass as varchar (max) = 'All'
	 , @userId uniqueidentifier=null 
as
begin




			--08/02/2013 DRP allow @lcuniqwh have multiple csv
			declare  @uniqWh table (UniqWh char(10))
			--12/03/13 YS use 'All' in place of '*'
			if @lcUniqWh<>'All' and @lcUniqWh<>'' and @lcUniqWh is not null
				insert into @UniqWh  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqWh,',')
			--08/02/2013 DRP allow @lcClass have multiple csv
			declare @Class table(Class char(8))
			--12/03/13 YS use 'All' in place of '*'
			if @lcClass<>'All' and @lcClass<>'' and @lcClass is not null
				insert into @Class select * from dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
			
	---08/15/17 YS move @result table and add additional columns for PR values	
	declare @Results as table ([Total Lines Counted] Numeric(7,0), 
		[Total Lines Outside Count Limit] numeric(7,0), 
		[Total Lines Outside Dollar Limit] numeric(7,0)
		,[Total Parts Counted] numeric(13,2), 
		[Total Parts Outside Count Limit] numeric(13,2),
		[Total Parts Outside Dollar Limit] numeric(13,2), 
		[Total Dollars Counted] numeric(13,2)
		,[Total Dollars Outside Count Limit] numeric(13,2), 
		[Total Dollars Outside Dollar Limit]numeric(13,2), 
		[Total Dollars Variance]numeric(13,2),
		[Total Dollars Counted PR] numeric(13,2)
		,[Total Dollars Outside Count Limit PR] numeric(13,2), 
		[Total Dollars Outside Dollar Limit PR]numeric(13,2), 
		[Total Dollars Variance PR]numeric(13,2),
		PRFCUSED_uniq char(10),FUNCfcUsed_uniq char(10)
		)	

insert into @Results ([Total Lines Counted],[Total Parts Counted],[Total Dollars counted], [Total Dollars Variance],
[Total Lines Outside Count Limit],[Total Parts Outside Count Limit],[Total Dollars Outside Count Limit],
[Total Lines Outside Dollar Limit],[Total Parts Outside Dollar Limit],[Total Dollars Outside Dollar Limit],
 [Total Dollars counted PR],[Total Dollars Variance PR],[Total Dollars Outside Count Limit PR],[Total Dollars Outside Dollar Limit PR],
 prfcused_uniq,c.funcfcused_uniq)
 select count(*) as [Total Lines Counted],
	SUM(C.ccount) as [Total Parts Counted],
	SUM(C.Ccount*StdCost) as [Total Dollars counted],
	SUM((C.Ccount - C.Qty_oh)*StdCost) as [Net Dollars Variance],
	CL.[Total Lines Outside Count Limit],CL.[Total Parts Outside Count Limit],CL.[Total Dollars Outside Count Limit],
	CD.[Total Lines Outside Dollar Limit],CD.[Total Parts Outside Dollar Limit],CD.[Total Dollars Outside Dollar Limit],
	SUM(C.Ccount*StdCostpr) as [Total Dollars counted PR],
	SUM((C.Ccount - C.Qty_oh)*StdCostPr) as [Net Dollars Variance PR],
	CL.[Total Dollars Outside Count Limit PR],
	CD. [Total Dollars Outside Dollar Limit PR],
	c.prfcused_uniq,c.funcfcused_uniq
	FROM ccrecord C
	CROSS APPLY
	(select count(*) as [Total Lines Outside Count Limit],
			 SUM(c2.ccount) as [Total Parts Outside Count Limit],
			 SUM(c2.Ccount*c2.StdCost) as [Total Dollars Outside Count Limit],
			 SUM(c2.Ccount*c2.StdCostPr) as [Total Dollars Outside Count Limit PR]
			 FROM Ccrecord C2 
			  inner join Inventor on c2.uniq_key=inventor.uniq_key
			 where DATEDIFF(Day,c2.SYS_DATE,@lcDateStart)<=0		--11/18/16 DRP:  changed from ccdate to sys_date
					AND DATEDIFF(Day,c2.SYS_DATE,@lcDateEnd)>=0	--11/18/16 DRP:  changed from ccdate to sys_date
					and c2.ccrecncl = 1 and c2.CCQ = 1	
					and (@lcUniqWh = 'All' OR c.UNIQWH IN (select Uniqwh from @uniqWh ))
					and (@lcClass = 'All'  OR inventor.part_class IN (select class from @class ))
					) CL
	CROSS APPLY
	(select count(*) as [Total Lines Outside Dollar Limit],
			 SUM(c3.ccount) as [Total Parts Outside Dollar Limit],
			 SUM(c3.Ccount*c3.StdCost) as [Total Dollars Outside Dollar Limit],
			  SUM(c3.Ccount*c3.StdCostPR) as [Total Dollars Outside Dollar Limit PR]
			 FROM Ccrecord c3 
			 inner join Inventor on c3.uniq_key=inventor.uniq_key
			 where DATEDIFF(Day,c3.SYS_DATE,@lcDateStart)<=0		--11/18/16 DRP:  changed from ccdate to sys_date
					AND DATEDIFF(Day,c3.SYS_DATE,@lcDateEnd)>=0	--11/18/16 DRP:  changed from ccdate to sys_date
					and c3.ccrecncl = 1 and c3.CCD = 1	
					and (@lcUniqWh = 'All' OR c.UNIQWH IN (select Uniqwh from @uniqWh ))
					and (@lcClass = 'All'  OR inventor.part_class IN (select class from @class))
					) CD
	where 
	DATEDIFF(Day,c.SYS_DATE,@lcDateStart)<=0		--11/18/16 DRP:  changed from ccdate to sys_date
	AND DATEDIFF(Day,c.SYS_DATE,@lcDateEnd)>=0	--11/18/16 DRP:  changed from ccdate to sys_date
	and c.ccrecncl = 1
	and (@lcUniqWh = 'All' OR c.UNIQWH IN (select Uniqwh from @uniqWh ))
	and (@lcClass = 'All'  OR c.uniq_key IN (select Uniq_key from Inventor inner join @class on inventor.part_class=[@class].class))
	GROUP BY CL.[Total Lines Outside Count Limit],CL.[Total Parts Outside Count Limit],CL.[Total Dollars Outside Count Limit],
	CD.[Total Lines Outside Dollar Limit],CD.[Total Parts Outside Dollar Limit],CD.[Total Dollars Outside Dollar Limit],
	c.prfcused_uniq,c.funcfcused_uniq,[Total Dollars Outside Count Limit PR], [Total Dollars Outside Dollar Limit PR]

---08/15/17 YS now check for the FC
if dbo.fn_IsFCInstalled()=0
	select  
	 [Total Lines Counted],[Total Parts Counted],[Total Dollars counted], [Total Dollars Variance],
	[Total Lines Outside Count Limit],[Total Parts Outside Count Limit],[Total Dollars Outside Count Limit],
	[Total Lines Outside Dollar Limit],[Total Parts Outside Dollar Limit],[Total Dollars Outside Dollar Limit]
	from @Results
else
	select  
	 [Total Lines Counted],[Total Parts Counted],[Total Dollars counted], [Total Dollars Variance],
	[Total Lines Outside Count Limit],[Total Parts Outside Count Limit],[Total Dollars Outside Count Limit],
	[Total Lines Outside Dollar Limit],[Total Parts Outside Dollar Limit],[Total Dollars Outside Dollar Limit],
	[Total Dollars counted PR],[Total Dollars Variance PR],[Total Dollars Outside Count Limit PR],[Total Dollars Outside Dollar Limit PR],
	isnull(prSymbol,space(3)) as prSymbol,isnull(funcSymbol,space(3)) as funcsymbol
	from @Results
	OUTER APPLY (select symbol as funcSymbol from fcused where fcused.fcused_uniq=funcfcused_uniq) func
	OUTER APPLY (select symbol as prSymbol from fcused where fcused.fcused_uniq=PRFCUSED_uniq) pr



end		


