

-- =============================================
-- Author:		<Debbie>
-- Create date: <10/21/2015>
-- Description:	<Compiles the details for the Inventory and WIP Qty's for Consigned>
-- Used On:     InvtWipConsg
-- Modified:	10/21/2015 DRP:  Per Request of a user we created this Consigned Version of the Inventory and WIP report.  It will only show qty information since Consigned Inventory does not have a value. 		
--				11/08/16 DRP:  	Needed to change the formula for the  QtyInWip  field so that it would no longer use the Cast as numeric(12,2) when this was being used it would then incorrectly show a decimal place.						
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--08/01/17 YS moved part_class setup from "support" table to partClass table 
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtWipConsg]

--declare
	-- Add the parameters for the stored procedure here
		@lcClass as varchar (max) = 'All'
		,@lcCustNo varchar(max) = 'All'
		,@lcUniq_keyStart char(10)=''
		,@lcUniq_keyEnd char(10)=''
		,@lcRound as char(3) = 'No'				--Yes:  round QtyInWip to the nearest Interger No:  Don't round the QtyInWip	--01/27/2015 DRP: Added
		, @userId uniqueidentifier=null

as
begin

SET NOCOUNT ON;
/*PART RANGE*/		
	--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
	@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
		
	--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key	
	--09/13/2013 DRP: If null or '*' then pass ''
	IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart ='' 
		SELECT @lcPartStart=' ', @lcRevisionStart=' '
	ELSE
	SELECT @lcPartStart = ISNULL(I.Part_no,' '), 
		@lcRevisionStart = ISNULL(I.Revision,' ') 
	FROM Inventor I where Uniq_key=@lcUniq_keyStart
		
	-- find ending part number
	IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd ='' 
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
		SELECT @lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)
	ELSE
		SELECT @lcPartEnd =ISNULL(I.Part_no,' '), 
			@lcRevisionEnd = ISNULL(I.Revision,' ') 
		FROM Inventor I where Uniq_key=@lcUniq_keyEnd	
	
	
/*PART CLASS LIST*/	--01/27/2015 DRP:  Added
	DECLARE @tPartClass TABLE (part_class char(8))
		Declare @Class table(part_class char(8))
		--08/01/17 YS moved part_class setup from "support" table to partClass table 
		insert into @tPartClass SELECT  PART_CLASS FROM partClass
	
		IF @lcClass is not null and @lcClass <>'' and @lcClass<>'All'
			insert into @Class select * from dbo.[fn_simpleVarcharlistToTable](@lcClass,',')
					where CAST (id as CHAR(10)) in (select part_class from @tPartClass)
		ELSE

		IF  @lcClass='All'	
		BEGIN
			INSERT INTO @Class SELECT Part_class FROM @tPartClass
		END

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END

--select * from @Customer
;
with	zQtyOh as 
(
	select	inventor.uniq_key,part_no,revision,customer.custno,custname,inventor.CUSTPARTNO,inventor.CUSTREV,part_class,part_type,descript,abc,inventor.PART_SOURC,U_OF_MEAS
			,sum(mfgr1.qty_oh) as QtyOh,SUM(mfgr1.reserved) as QtyAlloc,CAST (0.00 as numeric (12,2)) as QtyNotNet,inventor.BUYER_TYPE
	from	inventor 
			inner join INVTMFGR as mfgr1 on inventor.UNIQ_KEY = mfgr1.UNIQ_KEY
			inner join customer on inventor.custno = customer.CUSTNO
	where	inventor.STATUS = 'Active'
			and mfgr1.IS_DELETED <> 1
			and mfgr1.INSTORE <> 1
			and PART_NO >= case when @lcPartStart = '' then PART_NO else @lcPartStart END
			and PART_NO <= CASE WHEN @lcPartEnd = '' THEN PART_NO ELSE @lcPartEnd END
			AND PART_SOURC = 'CONSG'	
			and EXISTS (select 1 from @class c where inventor.PART_CLASS=c.part_class)	
			--and 1 = case when inventor.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
			and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join CUSTOMER c on t.custno=c.CUSTNO where c.CUSTno=inventor.CUSTNO))					
	group by inventor.UNIQ_KEY,part_no,revision,customer.custno,CUSTNAME,CUSTPARTNO,CUSTREV,part_class,part_type,descript,abc,PART_SOURC,U_OF_MEAS,BUYER_TYPE
)
 
	,

	zQtyInWip as
(
	select	kamain.UNIQ_KEY,I.PART_NO,I.REVISION,i.CUSTNO,i.CUSTNAME,I.CUSTPARTNO,I.CUSTREV,I.part_class,I.Part_type,I.descript,SUM(act_qty) as ActQty,LINESHORT,SUM(shortqty) as ShortQty
			,Woentry.wono,woentry.balance,woentry.UNIQ_KEY as ParentUniq,woentry.bldqty,SUM(act_qty) + SUM(shortqty) as ReqPerBld
			,(SUM(act_qty) + SUM(shortqty)) /nullif(woentry.bldqty,0)as ReqPerEach,(sum(act_qty) + SUM(shortqty))/nullif(woentry.bldqty * woentry.balance,0) as ReqPerBal
			,case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else
				case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end as QtyShort
			--,case when @lcRound = 'No' then cast((sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else
			--	case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end as numeric(12,2)) 
			--		else cast(ceiling((sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else
			--			case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end)as numeric(12,2)) end as  QtyInWip 	--11/08/16 DRP:  REPLACED BY THE BELOW
			,case when @lcRound = 'No' then  sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else 
					case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end 
						else ceiling(sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance then SUM(shortqty) else 
								case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance end end end  QtyInWip 
	from	kamain
			inner join WOENTRY on KAMAIN.wono = woentry.WONO
			inner join zQtyOh I on kamain.UNIQ_KEY = I.UNIQ_KEY
	where	woentry.openclos <> 'Closed' and woentry.openclos <>'Cancel'
			AND PART_SOURC = 'CONSG'	--06/10/2015 DRP:  Added
	group by	kamain.uniq_key,part_no,Revision,i.custno,CUSTNAME,CUSTPARTNO,CUSTREV,part_class,Part_type,DESCRIPT,lineshort,woentry.WONO,woentry.balance,woentry.UNIQ_KEY,woentry.BLDQTY
)	
		
Select	t1.uniq_key,t1.PART_NO,t1.REVISION,t1.custno,t1.CUSTNAME,t1.CUSTPARTNO,t1.CUSTREV,t1.PART_CLASS,t1.PART_TYPE,t1.DESCRIPT,t1.ABC,t1.PART_SOURC,t1.U_OF_MEAS
		,t1.qtyoh,isnull(w1.QtyInWip,0.00) as QtyInWip
from	zQtyOh t1
		OUTER APPLY (select	zQtyInWip.uniq_key,sum(QtyInWip) as QtyInWip 
					 from	zQtyInWip  
					 where	zQtyInWip.QtyInWip <> 0.00 
							and zQtyInWip.UNIQ_KEY = T1.UNIQ_KEY 
					 GROUP BY zQtyInWip.UNIQ_KEY) W1 
where	t1.qtyoh <> 0.00 OR (W1.QtyInWip<>0.00 and W1.QtyInWip  IS NOT NULL)

			
			
end