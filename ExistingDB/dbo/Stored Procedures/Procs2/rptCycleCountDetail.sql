
-- =============================================
-- Author:			Debbie
-- Create date:		08/03/2013
-- Description:		Compiles the details for the Cycle Count Detail Reports
-- Used On:			cycdtl1 ~ cycdtl2
-- Modifications:	12/03/13 YS use 'All' in place of '*'
--	11/18/16 DRP:  It was brought to our attention that this report functioned differently from the VFP version
--	The DATEDIFF need to be changed from the CCDATE to SYS_DATE
--	added ccrecncl = 1:  so it will only pull fwd into the results once it has been reconciled within the count
--	added STDCOSTPR to the results because it was added to the ccrecord table.
--  04/13/17 YS new fields were added to ccrecord table, need to update @Ccount
--- 08/15/17 YS check if currency is on and change order by to use case
--- 08/16/17 YS change [Variance] column name to [Changes in Qty] - I think Aloha has format $ for variance column
-- 08/25/17 DRP:  stimulsoft has issues when the column name that has spaces in it . . . changed [Changes in Qty] to be <<Changes_in_Qty>>
-- 10/11/19 VL changed part_no from char(25) to char(35)
-- =============================================
CREATE PROCEDURE  [dbo].[rptCycleCountDetail]

		@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		-- 12/03/13 YS use 'All' in place of '*'
		,@lcUniqWh as varchar (max) = 'All'		
		,@lcClass as varchar (max) = 'All'
		,@lcSortOrder as char(10) = 'Warehouse'		-- (Class or Warehouse)  This is where the users will pick how they wish for the report to be orderd by. 
		, @userId uniqueidentifier=null 
as
begin
set nocount on

--This table is where it will insert the results from the cte select below.  Basically the Cycle count records per the selections made within the parameters. 
--  04/13/17 YS new fields PRFCUSED_uniq char(10),FUNCfcUsed_uniq char(10),were added to ccrecord table, need to update @Ccount
-- 10/11/19 VL changed part_no from char(25) to char(35)
declare @Ccount as table (Part_no char(35),Revision char(8),Part_class char(8),Part_type char (8),Uniq_key char (10),Uniqccno char (10),w_key char (10),location char(17),lotcode char(15),reference char(12),ponum char(15),qty_oh numeric(12,2)
						,sys_date smalldatetime,ccount numeric (12,2),CCINIT char(8),ABC char(1),CCDATE smalldatetime,CCREASON char(20),CCRECNCL bit,CCQ bit,CCD bit,STDCOST numeric(13,5)
						,EXPDATE smalldatetime,POSTED bit,UNIQ_LOT char(10),IS_UPDATED bit,UNIQWH char(10),UniqSupno char(10),UniqMfgrHd char(10),
						STDCOSTPR NUMERIC(13,5),
						PRFCUSED_uniq char(10),
						FUNCfcUsed_uniq char(10),
						Warehouse char(6))


		--08/02/2013 DRP allow @lcuniqwh have multiple csv
		
		declare @uniqWh table (UniqWh char(10))
		--12/03/13 YS use 'All' in place of '*'
		if @lcUniqWh<>'All' and @lcUniqWh<>'' and @lcUniqWh is not null
			insert into @UniqWh  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqWh,',')
		--08/02/2013 DRP allow @lcClass have multiple csv
		declare @Class table(Class char(8))
		--12/03/13 YS use 'All' in place of '*'
		if @lcClass<>'All' and @lcClass<>'' and @lcClass is not null
			insert into @Class select * from dbo.[fn_simpleVarcharlistToTable](@lcClass,',')

--  04/13/17 YS new fields PRFCUSED_uniq char(10),FUNCfcUsed_uniq char(10),were added to ccrecord table, need to update @Ccount	
;
with 
zCcount as	(						
			select distinct	inventor.PART_NO,inventor.Revision,PART_CLASS,part_type,CCRECORD.*,WAREHOUSE
			from	INVENTOR
					inner join CCRECORD on inventor.UNIQ_KEY = CCRECORD.uniq_key
					inner join WAREHOUS on CCRECORD.UNIQWH = WAREHOUS.UNIQWH
			where	DATEDIFF(Day,ccrecord.SYS_DATE,@lcDateStart)<=0		--11/18/16 DRP:  changed from ccdate to sys_date
					AND DATEDIFF(Day,ccrecord.SYS_DATE,@lcDateEnd)>=0	--11/18/16 DRP:  changed from ccdate to sys_date
					and ccrecncl = 1	--11/18/16 DRP:  added
					--12/03/13 YS use 'All' in place of '*'
					and 1= CASE WHEN @lcUniqWh = 'All' then 1 
							WHEN ccrecord.UNIQWH IN (select Uniqwh from @uniqWh ) then 1 ELSE 0 END
					and 1 = case when @lcClass = 'All' then 1
							when PART_CLASS IN (select class from @Class) then 1 else 0 end		
 

			)
			
insert into @Ccount select* from zCcount

--- 08/15/17 YS check if currency is on and chnage order by to use case
if (dbo.fn_IsFCInstalled()=0)
BEGIN
	if (@lcSortOrder = 'Warehouse')
	Begin
	---08/16/17 YS change [Variance] column name to [Changes in Qty] - I think Aloha has format $ for variance column
	--08/25/17 DRP: Stimulsoft does not like spaces in field names changed [Changed in Qty] to be <<Changes_in_Qty>>
		select	 Part_class,Part_type,Part_no,Revision,Warehouse,location,lotcode,ccount,qty_oh,ccount-qty_oh as [Changes_in_Qty],round((ccount -Qty_oh) * StdCost,2) as DollarVariance
				 ,sys_date,CCDATE,CCREASON,Uniq_key,UniqMfgrHd,w_key,Uniqccno 
		from	 @Ccount 
		where	 ccount<>qty_oh 
		order by 
		warehouse,location,reference,Part_no,Revision,qty_oh		
	End
	else if (@lcSortOrder = 'Class')
	Begin
	---08/16/17 YS change [Variance] column name to [Changes in Qty] - I think Aloha has format $ for variance column
	--08/25/17 DRP: Stimulsoft does not like spaces in field names changed [Changed in Qty] to be <<Changes_in_Qty>>
		select	 Part_class,Part_type,Part_no,Revision,Warehouse,location,lotcode,ccount,qty_oh,ccount-qty_oh as [Changes_in_Qty],round((ccount -Qty_oh) * StdCost,2) as DollarVariance
				 ,sys_date,CCDATE,CCREASON,Uniq_key,UniqMfgrHd,w_key,Uniqccno 
		from	 @Ccount 
		where	 ccount<>qty_oh 
		order by part_class,Part_type,Part_no,Revision,Warehouse,location,reference
	end	--- if (@lcSortOrder = 'Class')
END
ELSE if (dbo.fn_IsFCInstalled()=1)
BEGIN
if (@lcSortOrder = 'Warehouse')
	Begin
	---08/16/17 YS change [Variance] column name to [Changes in Qty] - I think Aloha has format $ for variance column
	--08/25/17 DRP: Stimulsoft does not like spaces in field names changed [Changed in Qty] to be <<Changes_in_Qty>>
		select	 Part_class,Part_type,Part_no,Revision,Warehouse,location,lotcode,ccount,qty_oh,ccount-qty_oh as [Changes_in_Qty],func.funcSymbol,
		round((ccount -Qty_oh) * StdCost,2) as DollarVariance,round((ccount -Qty_oh) * STDCOSTPR,2) as DollarVariancePr,pr.prSymbol
				 ,sys_date,CCDATE,CCREASON,Uniq_key,UniqMfgrHd,w_key,Uniqccno 
		from	 @Ccount 
		OUTER APPLY (select symbol as funcSymbol from fcused where fcused.fcused_uniq=funcfcused_uniq) func
		OUTER APPLY (select symbol as prSymbol from fcused where fcused.fcused_uniq=PRFCUSED_uniq) pr
		where	 ccount<>qty_oh 
		order by 
		warehouse,location,reference,Part_no,Revision,qty_oh		
	End
	else if (@lcSortOrder = 'Class')
	Begin
	---08/16/17 YS change [Variance] column name to [Changes in Qty] - I think Aloha has format $ for variance column
	--08/25/17 DRP: Stimulsoft does not like spaces in field names changed [Changed in Qty] to be <<Changes_in_Qty>>
		select	 Part_class,Part_type,Part_no,Revision,Warehouse,location,lotcode,ccount,qty_oh,ccount-qty_oh as [Changes_in_Qty],
		round((ccount -Qty_oh) * StdCost,2) as DollarVariance,func.funcSymbol,
		round((ccount -Qty_oh) * STDCOSTPR,2) as DollarVarianceP,pr.prSymbol
				 ,sys_date,CCDATE,CCREASON,Uniq_key,UniqMfgrHd,w_key,Uniqccno 
		from	 @Ccount 
		OUTER APPLY (select symbol as funcSymbol from fcused where fcused.fcused_uniq=funcfcused_uniq) func
		OUTER APPLY (select symbol as prSymbol from fcused where fcused.fcused_uniq=PRFCUSED_uniq) pr
		where	 ccount<>qty_oh 
		order by part_class,Part_type,Part_no,Revision,Warehouse,location,reference
	end	--- if (@lcSortOrder = 'Class')
END
END