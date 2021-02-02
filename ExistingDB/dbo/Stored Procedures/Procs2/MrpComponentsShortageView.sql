-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/09/2012
-- Description:	Collect Shortage information for MRP (use in place of zShort cursor in the mGetComponentDemands)
---modified: 03/07/16 YS calculate req date here, becuase if kit has components under phantom, the lead time will be calculated by the phantom lead time. In the class the lead time  was attached to the ParentPt
-- in case of the phantom it will use phantom lead time, but not the top level lead time. made changes to the mrputils mGetComponentDemands   
--- 08/05/20 YS rewrite the sp to use new MrpLeadDetail table for lead times calculation
-- =============================================
CREATE PROCEDURE [dbo].[MrpComponentsShortageView]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    	
		
		/* --- 08/05/20 YS rewrite the sp to use new MrpLeadDetail table for lead times calculation
		use new lead time tables with the qty brake */
		
	if object_id('tempdb..#tShortComp') is not null
	drop table #tShortComp

	SELECT BomParent AS ParentPt, woentry.uniq_key as TopParentPt,Inventor.Uniq_Key, ShortQty AS ReqQty, 
	cast(0 as int) as ProdDays,cast(0 as int) as KitDays,
	cast(0 as int) as PhantomProdDays,cast(0 as int) as PhantomKitDays,
		CAST('WO' + KaMain.WoNo + CASE WHEN KaMain.LineShort=1 THEN 'Line Shortage' ELSE 'Kit Shortage' END as CHAR(24)) AS Ref, 
			'Release PO' AS Action, 
			Inventor.Part_Sourc, PrjUnique, 'Short WO'+KaMain.WoNo AS Demands 
			,Woentry.Uniq_key as WoUniqueKey,woentry.DUE_DATE
		INTO #tShortComp
		FROM  KaMain INNER JOIN INVENTOR ON KaMain.Uniq_Key = Inventor.Uniq_Key
		INNER JOIN WoEntry ON WoEntry.WoNo = KaMain.WoNo
		inner join Inventor M on woentry.UNIQ_KEY=m.UNIQ_KEY
		inner join Inventor P on kamain.bomparent=p.uniq_key
		WHERE (Inventor.Part_Sourc = 'BUY' OR (inventor.Part_Sourc = 'MAKE' AND inventor.Make_Buy=1))
			AND KaMain.ShortQty > 0 
			AND ((WoEntry.OpenClos <> 'CLOSED' 
			AND WoEntry.OpenClos <> 'CANCEL' 
			AND WoEntry.OpenClos <> 'ARCHIVED' 
			AND Woentry.OpenClos<>'MFG HOLD'
			AND OpenClos<>'ADMIN HOLD') 
			OR (OpenClos IN ('MFG HOLD','ADMIN HOLD') AND MrponHold=0)) 
			AND KaMain.IgnoreKit=0
--- update for the full match
update #tShortComp set proddays=lt.ProdDays, KitDays=lt.KitDays from 
View_MrpLeadDetail lt where lt.Uniq_Key=[#tShortComp].TopParentPt
and reqQty between lt.QtyFrom and lt.QtyTo and ([#tShortComp].proddays=0 and  [#tShortComp].KitDays=0)

--- if parts belong to a phantom
update #tShortComp set PhantomProdDays=lt.ProdDays, PhantomKitDays=lt.KitDays from 
View_MrpLeadDetail lt where lt.Uniq_Key=[#tShortComp].ParentPt and [#tShortComp].ParentPt <>TopParentPt
and reqQty between lt.QtyFrom and lt.QtyTo and ([#tShortComp].PhantomProdDays=0 and  [#tShortComp].phantomKitDays=0)

-- if match is not found use the last range
update #tShortComp set proddays=lt.ProdDays, KitDays=lt.KitDays from 
View_MrpLeadDetail lt where lt.Uniq_Key=[#tShortComp].TopParentPt
and reqQty > lt.QtyFrom and reqQty>lt.QtyTo and ([#tShortComp].proddays=0 and  [#tShortComp].KitDays=0)
--- if parts belong to a phantom
update #tShortComp set PhantomProdDays=lt.ProdDays, PhantomKitDays=lt.KitDays from 
View_MrpLeadDetail lt where lt.Uniq_Key=[#tShortComp].ParentPt and [#tShortComp].ParentPt <>TopParentPt
and reqQty > lt.QtyFrom and reqQty>lt.QtyTo and  ([#tShortComp].PhantomProdDays=0 and  [#tShortComp].phantomKitDays=0)

-- if match is not found check for the missing range
update #tShortComp set proddays=lt.ProdDays, KitDays=lt.KitDays from 
View_MrpLeadDetail lt where lt.Uniq_Key=[#tShortComp].TopParentPt
and reqQty < lt.QtyFrom and reqQty<lt.QtyTo and ([#tShortComp].proddays=0 and  [#tShortComp].KitDays=0)
--- if parts belong to a phantom
update #tShortComp set PhantomProdDays=lt.ProdDays, PhantomKitDays=lt.KitDays from 
View_MrpLeadDetail lt where lt.Uniq_Key=[#tShortComp].ParentPt and [#tShortComp].ParentPt <>TopParentPt
and reqQty < lt.QtyFrom and reqQty<lt.QtyTo and  ([#tShortComp].PhantomProdDays=0 and  [#tShortComp].phantomKitDays=0)


--- last resort use old setup
update #tShortComp set proddays=
	Prod_ltime*
	(CASE WHEN lt.Prod_lunit = 'DY' THEN 1 
	WHEN Prod_lunit = 'WK' THEN 5 
	WHEN Prod_lunit = 'MO' THEN 20 ELSE 1 END),
	KitDays=Kit_ltime
	*(CASE WHEN Kit_lunit = 'DY' THEN 1 
	WHEN Kit_lunit = 'WK' THEN 5 
	WHEN Kit_lunit = 'MO' THEN 20 ELSE 1 END)
from 
Inventor lt where lt.Uniq_Key=[#tShortComp].TopParentPt
 and [#tShortComp].proddays=0 and  [#tShortComp].KitDays=0
--- last resort use old setup
update #tShortComp set PhantomProdDays=
	Prod_ltime*
	(CASE WHEN lt.Prod_lunit = 'DY' THEN 1 
	WHEN Prod_lunit = 'WK' THEN 5 
	WHEN Prod_lunit = 'MO' THEN 20 ELSE 1 END),
	PhantomKitDays=Kit_ltime
	*(CASE WHEN Kit_lunit = 'DY' THEN 1 
	WHEN Kit_lunit = 'WK' THEN 5 
	WHEN Kit_lunit = 'MO' THEN 20 ELSE 1 END)
from 
Inventor lt where lt.Uniq_Key=[#tShortComp].ParentPt and [#tShortComp].ParentPt <>TopParentPt
 and  ([#tShortComp].PhantomProdDays=0 and  [#tShortComp].phantomKitDays=0)
 
 --select * from #tShortComp
 select ParentPt,Uniq_key,ReqQty,cast(
	dbo.fn_GetWorkDayWithOffset(t.Due_date,(ProdDays+PhantomProdDays+KitDays+PhantomKitDays),'-') as smalldatetime) as ReqDate,
	Ref,[Action],Part_Sourc, PrjUnique, Demands , WoUniqueKey
 from #tShortComp t
 if object_id('tempdb..#tShortComp') is not null
	drop table #tShortComp
		
		/*old code  
		SELECT BomParent AS ParentPt, Inventor.Uniq_Key, ShortQty AS ReqQty, cast(case when woentry.uniq_key=kamain.BOMPARENT THEN 
				dbo.fn_GetWorkDayWithOffset(woentry.Due_date, M.Prod_ltime*(CASE WHEN M.Prod_lunit = 'DY' THEN 1 
						WHEN M.Prod_lunit = 'WK' THEN 5 
						WHEN M.Prod_lunit = 'MO' THEN 20 ELSE 1 END) + 
					M.Kit_ltime*(CASE WHEN M.Kit_lunit = 'DY' THEN 1 
										WHEN m.Kit_lunit = 'WK' THEN 5 
										WHEN M.Kit_lunit = 'MO' THEN 20 ELSE 1 END),'-') 
			--- woentry.uniq_key=kamain.BomPrent
			ELSE
			-- add top level lead time
			dbo.fn_GetWorkDayWithOffset(woentry.Due_date, M.Prod_ltime*(CASE WHEN M.Prod_lunit = 'DY' THEN 1 
						WHEN M.Prod_lunit = 'WK' THEN 5 
						WHEN M.Prod_lunit = 'MO' THEN 20 ELSE 1 END) + 
					M.Kit_ltime*(CASE WHEN M.Kit_lunit = 'DY' THEN 1 
										WHEN m.Kit_lunit = 'WK' THEN 5 
										WHEN M.Kit_lunit = 'MO' THEN 20 ELSE 1 END)+

			-- add phantom level
			P.Prod_ltime*(CASE WHEN P.Prod_lunit = 'DY' THEN 1 
						WHEN p.Prod_lunit = 'WK' THEN 5 
						WHEN p.Prod_lunit = 'MO' THEN 20 ELSE 1 END) + 
					p.Kit_ltime*(CASE WHEN p.Kit_lunit = 'DY' THEN 1 
										WHEN p.Kit_lunit = 'WK' THEN 5 
										WHEN p.Kit_lunit = 'MO' THEN 20 ELSE 1 END),'-')

			END	 as smalldatetime) AS ReqDate,
			CAST('WO' + KaMain.WoNo + CASE WHEN KaMain.LineShort=1 THEN 'Line Shortage' ELSE 'Kit Shortage' END as CHAR(24)) AS Ref, 
			'Release PO' AS Action, 
			Inventor.Part_Sourc, PrjUnique, 'Short WO'+KaMain.WoNo AS Demands 
			,Woentry.Uniq_key as WoUniqueKey
		FROM  KaMain INNER JOIN INVENTOR ON KaMain.Uniq_Key = Inventor.Uniq_Key
		INNER JOIN WoEntry ON WoEntry.WoNo = KaMain.WoNo
		inner join Inventor M on woentry.UNIQ_KEY=m.UNIQ_KEY
		inner join Inventor P on kamain.bomparent=p.uniq_key
		WHERE (Inventor.Part_Sourc = 'BUY' OR (inventor.Part_Sourc = 'MAKE' AND inventor.Make_Buy=1))
			AND KaMain.ShortQty > 0 
			AND ((WoEntry.OpenClos <> 'CLOSED' 
			AND WoEntry.OpenClos <> 'CANCEL' 
			AND WoEntry.OpenClos <> 'ARCHIVED' 
			AND Woentry.OpenClos<>'MFG HOLD'
			AND OpenClos<>'ADMIN HOLD') 
			OR (OpenClos IN ('MFG HOLD','ADMIN HOLD') AND MrponHold=0)) 
			AND KaMain.IgnoreKit=0
	*/
	
END