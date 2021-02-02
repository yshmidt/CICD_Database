
-- =============================================
-- Author:			Debbie & Yelena
-- Create date:		07/23/2015
-- Description:		Created for the Projected Excess Inventory List
-- Report:			mrpexinv 
-- Modifications:  
-- 08/14/17 VL Added functional currency code	
-- =============================================
CREATE PROCEDURE [dbo].[rptMrpProjectedExcess]

--declare		
			@lcInvtType char(8) = 'All'		--All, Internal, In Store
			,@userId uniqueidentifier = null

as 
begin
-- 08/14/17 VL Added code to separate FC and non FC
/*----------------------
None FC installation
*/----------------------
IF dbo.fn_IsFCInstalled() = 0
	select	part_no,Revision,part_class,Part_type,Descript,cast(isnull(H.Invt_OH,0.00)  as numeric(12,2)) as Invt_oh ,
			cast(isnull(S.Supply,0.00) as numeric(12,2)) Supply,cast(ISNULL(D.SoDemand,0.00) as numeric(12,2)) SoDemand
			,cast(isnull(E.Demand,0.00) as numeric(12,2)) Demand,cast(H.Invt_OH+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)) as numeric(12,2)) as ExcessQty,STDCOST
			,cast((H.Invt_OH+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)))*STDCOST as numeric(12,2)) ExcessValue,inventor.UNIQ_KEY,MPSSYS.MRPDATE
	from	inventor
			outer apply  
			(select uniq_key,sum(qty_oh) as Invt_OH 
					from invtmfgr 
					where invtmfgr.IS_DELETED <> 1  
						  and invtmfgr.UNIQ_KEY =  Inventor.Uniq_key 
						  and 1 = case when @lcInvtType = 'Internal' and INVTMFGR.INSTORE = 0 then 1 when @lcInvtType = 'In Store' and invtmfgr.INSTORE = 1 then 1 when @lcInvtType = 'All' then 1 else 0 end
					group by invtmfgr.uniq_key ) H 
			outer apply 
			(select uniq_key,sum(reqqty) as Supply from MRPSCH2 where inventor.UNIQ_KEY = MRPSCH2.UNIQ_KEY and reqQty > 0 and ref <> 'Available Inventory' group by MRPSCH2.UNIQ_KEY) S 
			outer apply 
			(select SODETAIL.uniq_key,sum(balance) as SoDemand 
					from  sodetail inner join somain on sodetail.sono = somain.sono 
					where sodetail.UNIQ_KEY = inventor.UNIQ_KEY and balance > 0  and somain.ORD_TYPE = 'OPEN' GROUP BY SODETAIL.UNIQ_KEY) D 
			outer apply 
			(select uniq_key,sum(-reqqty) as Demand 
				from MRPSCH2 where MRPSCH2.Uniq_key=inventor.UNIQ_KEY and REQQTY < 0 and left(ref,2) <> 'SO' and left(ref,3) <> 'RMA' group by uniq_key ) E 
			cross apply MPSSYS
	WHERE	inventor.part_sourc='BUY' and cast((Invt_OH+isnull(Supply,0.00)-(isnull(SoDemand,0.00)+isnull(Demand,0.00)))*STDCOST as numeric(12,2)) <> 0.00

	order by part_no, Revision

ELSE
/*-----------------
 FC installation
*/-----------------
	select	part_no,Revision,part_class,Part_type,Descript,cast(isnull(H.Invt_OH,0.00)  as numeric(12,2)) as Invt_oh ,
			cast(isnull(S.Supply,0.00) as numeric(12,2)) Supply,cast(ISNULL(D.SoDemand,0.00) as numeric(12,2)) SoDemand
			,cast(isnull(E.Demand,0.00) as numeric(12,2)) Demand,cast(H.Invt_OH+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)) as numeric(12,2)) as ExcessQty,STDCOST
			,cast((H.Invt_OH+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)))*STDCOST as numeric(12,2)) ExcessValue, ISNULL(FF.Symbol,'') AS FSymbol
			,STDCOSTPR,cast((H.Invt_OH+isnull(S.Supply,0.00)-(isnull(D.SoDemand,0.00)+isnull(E.Demand,0.00)))*STDCOSTPR as numeric(12,2)) ExcessValuePR, ISNULL(PF.Symbol,'') AS PSymbol,
			inventor.UNIQ_KEY,MPSSYS.MRPDATE
	from	inventor
			outer apply  
			(select uniq_key,sum(qty_oh) as Invt_OH 
					from invtmfgr 
					where invtmfgr.IS_DELETED <> 1  
						  and invtmfgr.UNIQ_KEY =  Inventor.Uniq_key 
						  and 1 = case when @lcInvtType = 'Internal' and INVTMFGR.INSTORE = 0 then 1 when @lcInvtType = 'In Store' and invtmfgr.INSTORE = 1 then 1 when @lcInvtType = 'All' then 1 else 0 end
					group by invtmfgr.uniq_key ) H 
			outer apply 
			(select uniq_key,sum(reqqty) as Supply from MRPSCH2 where inventor.UNIQ_KEY = MRPSCH2.UNIQ_KEY and reqQty > 0 and ref <> 'Available Inventory' group by MRPSCH2.UNIQ_KEY) S 
			outer apply 
			(select SODETAIL.uniq_key,sum(balance) as SoDemand 
					from  sodetail inner join somain on sodetail.sono = somain.sono 
					where sodetail.UNIQ_KEY = inventor.UNIQ_KEY and balance > 0  and somain.ORD_TYPE = 'OPEN' GROUP BY SODETAIL.UNIQ_KEY) D 
			outer apply 
			(select uniq_key,sum(-reqqty) as Demand 
				from MRPSCH2 where MRPSCH2.Uniq_key=inventor.UNIQ_KEY and REQQTY < 0 and left(ref,2) <> 'SO' and left(ref,3) <> 'RMA' group by uniq_key ) E 
			cross apply MPSSYS
			LEFT OUTER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq
			LEFT OUTER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq	
	WHERE	inventor.part_sourc='BUY' and cast((Invt_OH+isnull(Supply,0.00)-(isnull(SoDemand,0.00)+isnull(Demand,0.00)))*STDCOST as numeric(12,2)) <> 0.00

	order by part_no, Revision

end