
-- =============================================
-- Author:			Debbie & Yelena
-- Create date:		12/10/2012
-- Description:		Created for the Un-Reconciled PO All Suppliers
-- Reports Using	Stored Procedure:  poinvun.rpt ,poinvun1
-- Modifications:	12/10/2012 DRP:  In VFP the code below for the PMatl_Cost used to use the inventor.stdcost, but we have made modifications in SQL to use the inventor.matl_cost instead. 
--                  08/25/2013 YS    Added Parameter @lcuniqsupno, default to null. If nuill all suppliersm, if one or multiple CSV  
---									this will allow to use the same procedure for the Un-Reconciled PO by Selected Suppliers  POINVUN1  
---					12/03/13 YS  change default from null to 'All'  
--								 added userid	   	
--					12/04/2013 DRP: Found that the users were ablet o create Instore PO's for Make parts.  when this happened it would have a blank PUOM and the PMatl_cost and PStdcost needed a UOM to calculate
--								    So I modified the formula to use the u_of_Meas if the Pur_uom was blank. 
--					01/23/2014 DRP: we found that if the user left All for the supplier that it was incorrectly not displaying the suppliers that were approved for the userid.  It was bringing forward all suppliers regardless if the user was approved for the Userid or not. 
--					07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')
--					12/12/14 DS Added supplier status filter
--					03/19/2015 DRP:  Needed to add StkQty, then needed to to change the formula used to calculate MtlAmt and StdAmt. 
--					04/10/2015 DRP:  Found that it incorrectly pulling from the poitems.Acpt_qty when it should have been pulling from the porecloc.AccptQty for the StkQty calculation.  This would have been contributing to the UnRecon Report discrepancy against the GL Balance reports.   
--									 Changed the titles of the reports in order to try and help clear up confusion of the end users when trying to validate to the GL account balances 
--									 "Unreconciled PO All Supplier" to be "PO Receipts Waiting to be Reconciled - All Suppliers"
--									 "Un-Reconciled PO by Selected Suppliers" to be "PO Receipts Waiting to be Reconciled by Selected Suppliers"
--									 "Un-Reconciled Account Value" to be "Un-Reconciled Receipt GL Account Value"
-- 05/28/15 YS remove ReceivingStatus
--					01/25/17	VL:	 Added functional currency code
-- =============================================
CREATE procedure [dbo].[rptPoReconUnRecon]

--declare	
	@lcuniqsupno varchar(max) = 'All'     ---NULL or empty - all suppliers, allow CSV		-- 12/03/13 YS changed default to 'All'
	,@userid uniqueidentifier = null			--12/03/13 YS added userid
	,@supplierStatus varchar(20) = 'All'	

as 
Begin

/*SUPPLIER LIST*/
-- 12/03/13 YS get list of approved suppliers for this user
DECLARE  @tSupplier tSupplier
DECLARE @Supplier TABLE (Uniqsupno char(10))
-- get list of Suppliers for @userid with access
INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus ;
--SELECT * FROM @tSupplier	
--- 12/03/2013 YS: have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
	insert into @Supplier select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
ELSE
---- 12/03/2013 YS empty or null customer or part number means no selection were made
IF  @lcUniqSupNo='All'	
BEGIN
	INSERT INTO @Supplier SELECT UniqSupno FROM @tSupplier	
END		 

/*RECORD SELECTION SECTION*/

--IF @lcUniqSupno is not null and @lcUniqSupno <>'' and @lcUniqSupno <>'All'
--	INSERT INTO @Supplier SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcUniqSupno,',')

-- 07/23/14 YS Added new column to PorecDtl table (ReceivingStatus ; Values 'Inspection','Complete')

-- 01/25/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	;
	with zUnRecon as(
	--01/25/17 VL changed RecvQty to ReceivedQty
	SELECt DISTINCT	SUPINFO.SUPNAME, SUPINFO.Supid, ReceivedQty AS Recv_Qty,porecloc.UniqDetNo,PoRecPkNo AS SupPkNo,POrecdtl.RecvDATE AS Date
					,inventor.PART_NO,inventor.REVISION,isnull(inventor.descript,PoItems.DESCRIPT) as Descript,porecloc.AccptQty AS Acpt_Qty
					,PoItSchd.Schd_Qty AS Ord_Qty,PoItems.CostEach,PoItems.ponum,PoItSchd.Balance AS Curr_Balln
					,PoItems.Uniq_Key,POrecdtl.ReceiverNo AS Recvno, porecloc.Sinv_Uniq ,porecdtl.U_OF_MEAS ,porecdtl.PUR_UOFM
					,cast(dbo.fn_ConverQtyUOM(porecdtl.PUR_UOFM,porecdtl.u_of_meas,porecloc.AccptQty) as numeric(13,5)) as StkQty	--03/19/2015 DRP:  Added
	--12/04/2013 DRP:  needed to replace the if pur_uofm is blank then it will now use the u_of_meas
					--CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					--CAST(dbo.fn_convertprice('Stk',Inventor.MATL_COST,porecdtl.U_OF_MEAS ,porecdtl.PUR_UOFM) as numeric(13,5)) END as PMatl_cost
					--,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					--CAST(dbo.fn_convertprice('Stk',Inventor.stdcost,porecdtl.U_OF_MEAS ,porecdtl.PUR_UOFM) as numeric(13,5)) END as PStdcost
					,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					CAST(dbo.fn_convertprice('Stk',Inventor.MATL_COST,porecdtl.U_OF_MEAS ,isnull(porecdtl.u_of_meas,porecdtl.PUR_UOFM)) as numeric(13,5)) END as PMatl_cost
					,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					CAST(dbo.fn_convertprice('Stk',Inventor.stdcost,porecdtl.U_OF_MEAS ,isnull(porecdtl.u_of_meas,porecdtl.PUR_UOFM)) as numeric(13,5)) END as PStdcost
				
	FROM			Poitems LEFT OUTER JOIN INVENTOR on Poitems.UNIQ_KEY=inventor.uniq_key
					INNER JOIN POrecdtl ON POrecdtl.UniqLnNo = PoItems.UniqLnNo 
					INNER JOIN porecloc on porecloc.Fk_UniqRecDtl= POrecdtl.UniqRecDtl 
					INNER JOIN  PoItSchd on porecloc.UniqDetNo = PoItSchd.UniqDetNo 
					INNER JOIN PoMain on PoMain.ponum = PoItems.ponum
					INNER JOIN SUPINFO on SUPINFO.UniqSupNo = PoMain.UniqSupNo 
	WHERE			porecloc.Sinv_Uniq = '' 
					AND porecloc.AccptQty <> 0 
					-- Make sure only complete recevers are selected
					-- 05/28/15 YS remove ReceivingStatus
					--and (PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus=' ')
					-- 12/03/13 YS 'All' means all
	---01/23/2014 DRP:	AND 1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier
	--					WHEN SUPINFO.UNIQSUPNO IN (SELECT UniqSupno FROM @Supplier) THEN 1 ELSE 0  END
					and 1= case WHEN SUPINFO.UNIQSUPNO IN (SELECT Uniqsupno FROM @Supplier) THEN 1 ELSE 0  END
	)
	select	zUnRecon.*,Acpt_Qty*COSTEACH as ExtAmt
			--,zUnRecon.PMatl_cost*zUnRecon.Acpt_Qty as MtlAmt,Pstdcost*Acpt_Qty as StdAmt	--03/19/2015 DRP:  Replaced with the below
			,zUnRecon.PMatl_cost*zUnRecon.StkQty as MtlAmt,Pstdcost*StkQty as StdAmt
			,MICSSYS.LIC_NAME 
	from	zUnRecon cross join MICSSYS			
	order by SUPNAME,PONUM,DATe,PART_NO,REVISION
	END
ELSE
	BEGIN
	;
	with zUnRecon as(
	--01/25/17 VL changed RecvQty to ReceivedQty
	SELECt DISTINCT	SUPINFO.SUPNAME, SUPINFO.Supid, ReceivedQty AS Recv_Qty,porecloc.UniqDetNo,PoRecPkNo AS SupPkNo,POrecdtl.RecvDATE AS Date
					,inventor.PART_NO,inventor.REVISION,isnull(inventor.descript,PoItems.DESCRIPT) as Descript,porecloc.AccptQty AS Acpt_Qty
					,PoItSchd.Schd_Qty AS Ord_Qty,PoItems.CostEach,PoItems.ponum,PoItSchd.Balance AS Curr_Balln
					,PoItems.Uniq_Key,POrecdtl.ReceiverNo AS Recvno, porecloc.Sinv_Uniq ,porecdtl.U_OF_MEAS ,porecdtl.PUR_UOFM
					,cast(dbo.fn_ConverQtyUOM(porecdtl.PUR_UOFM,porecdtl.u_of_meas,porecloc.AccptQty) as numeric(13,5)) as StkQty	--03/19/2015 DRP:  Added
	--12/04/2013 DRP:  needed to replace the if pur_uofm is blank then it will now use the u_of_meas
					--CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					--CAST(dbo.fn_convertprice('Stk',Inventor.MATL_COST,porecdtl.U_OF_MEAS ,porecdtl.PUR_UOFM) as numeric(13,5)) END as PMatl_cost
					--,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					--CAST(dbo.fn_convertprice('Stk',Inventor.stdcost,porecdtl.U_OF_MEAS ,porecdtl.PUR_UOFM) as numeric(13,5)) END as PStdcost
					,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					CAST(dbo.fn_convertprice('Stk',Inventor.MATL_COST,porecdtl.U_OF_MEAS ,isnull(porecdtl.u_of_meas,porecdtl.PUR_UOFM)) as numeric(13,5)) END as PMatl_cost
					,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					CAST(dbo.fn_convertprice('Stk',Inventor.stdcost,porecdtl.U_OF_MEAS ,isnull(porecdtl.u_of_meas,porecdtl.PUR_UOFM)) as numeric(13,5)) END as PStdcost
					-- 01/25/17 VL added functional currency and FC code
					,PoItems.CostEachFC
					,PoItems.CostEachPR
					,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					CAST(dbo.fn_convertprice('Stk',Inventor.MATL_COSTPR,porecdtl.U_OF_MEAS ,isnull(porecdtl.u_of_meas,porecdtl.PUR_UOFM)) as numeric(13,5)) END as PMatl_costPR
					,CASE WHEN Inventor.UNIQ_KEY IS NULL THEN CAST(0.00 as numeric(13,5)) ELSE 
					CAST(dbo.fn_convertprice('Stk',Inventor.stdcostPR,porecdtl.U_OF_MEAS ,isnull(porecdtl.u_of_meas,porecdtl.PUR_UOFM)) as numeric(13,5)) END as PStdcostPR
					,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol 
									
	FROM			Poitems LEFT OUTER JOIN INVENTOR on Poitems.UNIQ_KEY=inventor.uniq_key
					INNER JOIN POrecdtl ON POrecdtl.UniqLnNo = PoItems.UniqLnNo 
					INNER JOIN porecloc on porecloc.Fk_UniqRecDtl= POrecdtl.UniqRecDtl 
					INNER JOIN  PoItSchd on porecloc.UniqDetNo = PoItSchd.UniqDetNo 
					INNER JOIN PoMain on PoMain.ponum = PoItems.ponum
					INNER JOIN SUPINFO on SUPINFO.UniqSupNo = PoMain.UniqSupNo 
					-- 01/25/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON POMAIN.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON POMAIN.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON POMAIN.Fcused_uniq = TF.Fcused_uniq			

	WHERE			porecloc.Sinv_Uniq = '' 
					AND porecloc.AccptQty <> 0 
					-- Make sure only complete recevers are selected
					-- 05/28/15 YS remove ReceivingStatus
					--and (PORECDTL.ReceivingStatus='Complete' or PORECDTL.ReceivingStatus=' ')
					-- 12/03/13 YS 'All' means all
	---01/23/2014 DRP:	AND 1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier
	--					WHEN SUPINFO.UNIQSUPNO IN (SELECT UniqSupno FROM @Supplier) THEN 1 ELSE 0  END
					and 1= case WHEN SUPINFO.UNIQSUPNO IN (SELECT Uniqsupno FROM @Supplier) THEN 1 ELSE 0  END
	)
	-- 01/25/17 VL added functional and fc currency code
	select	zUnRecon.*,Acpt_Qty*COSTEACH as ExtAmt
			--,zUnRecon.PMatl_cost*zUnRecon.Acpt_Qty as MtlAmt,Pstdcost*Acpt_Qty as StdAmt	--03/19/2015 DRP:  Replaced with the below
			,zUnRecon.PMatl_cost*zUnRecon.StkQty as MtlAmt,Pstdcost*StkQty as StdAmt
			, Acpt_Qty*COSTEACHFC as ExtAmtFC, Acpt_Qty*COSTEACHPR as ExtAmtPR
			,zUnRecon.PMatl_costPR*zUnRecon.StkQty as MtlAmtPR,PstdcostPR*StkQty as StdAmtPR
			,MICSSYS.LIC_NAME 
	from	zUnRecon cross join MICSSYS			
	order by SUPNAME,PONUM,DATe,PART_NO,REVISION
	END

end