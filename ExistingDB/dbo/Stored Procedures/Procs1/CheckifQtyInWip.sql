-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 0516/2014
-- Description:	Check if a part is in WIP
-- =============================================
CREATE PROCEDURE CheckifQtyInWip 
	-- Add the parameters for the stored procedure here
	@uniq_key char(10) = ' ' 
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	;
with WIP
AS
(
select	kamain.UNIQ_KEY,SUM(act_qty) as ActQty,LINESHORT,SUM(shortqty) as ShortQty,
	Woentry.wono,woentry.balance
	,woentry.UNIQ_KEY as ParentUniq,woentry.bldqty,
	SUM(act_qty) + SUM(shortqty) as ReqPerBld
	,(SUM(act_qty) + SUM(shortqty)) /nullif(woentry.bldqty,0)as ReqPerEach
	,(sum(act_qty) + SUM(shortqty))/nullif(woentry.bldqty * woentry.balance,0) as ReqPerBal
	,case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/nullif(woentry.bldqty,0)) * woentry.balance then SUM(shortqty) else
	case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance end end as QtyShort
	,(sum(act_qty) + SUM(shortqty))/ nullif (woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance then SUM(shortqty) else
	case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance end end as QtyInWip
	,ceiling((sum(act_qty) + SUM(shortqty))/ nullif(woentry.bldqty,0) * woentry.balance - case when SUM(shortqty)>0.00 and SUM(shortqty) <= (sum(act_qty) + SUM(shortqty)/ nullif(woentry.bldqty,0)) * woentry.balance then SUM(shortqty) else
	case when SUM(shortqty)<=0.00 then 0.00 else (sum(act_qty) + SUM(shortqty)/nullif(woentry.bldqty,0)) * woentry.balance end end) as rQtyInWip
	from	kamain
		inner join WOENTRY on KAMAIN.wono = woentry.WONO
		inner join INVENTOR on kamain.UNIQ_KEY = inventor.UNIQ_KEY
		where	woentry.openclos <> 'Closed' and woentry.openclos <>'Cancel'
		and kamain.uniq_key=@uniq_key
	group by	
	kamain.uniq_key,lineshort,woentry.WONO,woentry.balance,woentry.UNIQ_KEY,woentry.BLDQTY
	)
	select top 1 * from wip where qtyinwip>0 order by qtyinwip desc
	 
END