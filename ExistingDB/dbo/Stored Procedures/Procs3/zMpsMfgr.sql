-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/08/2012
-- Description:	get information for MRP replaces ZmpSMfgr cursor
-- 09/23/14 YS changes to avl new tables and links between avl and inventory. Keeping one AVL master table to link to multiple 
-- records in the inventor table
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
-- 04/14/15 YS Location length is changed to varchar(256)
---02/28/18 YS added column LDISALLOWBUY from invtmfhd table. Ignore LDISALLOWBUY parts when safety stock is entered
---04/10/18 YS modify the way avaialble qty are calculated. It has to be qty_oh-kitted(reserved)+over-kitted. You can find overkitted by gathering negative shortage in the kamain and comapre against reserved
-- 12/10/20 YS fix the claculation of the available qty. Remove reserved and add back over issue. Take into concideration that if shortage is negative and actual>0 negative shortage cannot be used as total over issued
-- 12/14/20 YS fix available qty calculation. Need to make sure that if reserved from multiple w_key we calculate the available qty correctly.
--- 12/15/20 YS Stonewall found a problem when we issue more than allocate and the shortage is negative.
--- we do make an assumption which w_key were over issued. But currently there is nothing we can do about it. Since we just save the allocated qty and do not designate which one
--- concidered as extra
--12/15/20 YS added case for e.g. req 300, allocated 50, act_qty 265, shortage -15 - extra=15
--12/16/20 YS Stonewall identify a problem with the calculation. Take another look
/*
 1. If ShortQty=0 or ShortQty>0 or (ShortQty<0 and AllocatedQty=0) we do not have any extara qty avaialble (Extra=0)
 2. If ShortQty<0 and Act_qty=0  extra=ABS(Required-Act_qty-AllocatedQTy)
 3. If ShortQty<0 and Act_qty<>0 and AllocatedQty<>0 and Act_qty<AllocatedQty extra ABS(Required-Act_qty-AllocatedQTy)
 4. IF ShortQty<0 and Act_qty<>0 and AllocatedQty<>0 and Act_qty>AllocatedQty and Act_qty<Req extra ABS((Required-Act_qty-AllocatedQTy)
 5. If ShortQty<0 and Act_qty<>0 and AllocatedQTy<>0 and Act_qty>Req Extra=AllocatedQty
 */
 --12/16/20 YS recalculate the application of extra qty
 --12/16/20 YS replace null value for the prev_running_totalAllocated  with 0.00 
-- =============================================
CREATE PROCEDURE [dbo].[zMpsMfgr] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	TRUNCATE TABLE MrpWh
	-- 09/23/14 YS use new tables
	-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int
	INSERT INTO [MRPWH]
           ([UNIQ_KEY]
           ,[PARTMFGR]
           ,[MFGR_PT_NO]
           ,[QTY_OH]
           ,[NETABLE]
           ,[LOCATION]
           ,[W_KEY]
           ,[RESERVED]
           ,[ORDERPREF]
           ,[UNIQMFGRHD]
           ,[Uniqwh])
    SELECT INVTMFGR.[UNIQ_KEY]
      ,[MfgrMaster].[PARTMFGR]
      ,[MfgrMaster].[MFGR_PT_NO]
      ,INVTMFGR.[QTY_OH]
      ,INVTMFGR.[NETABLE]
      ,INVTMFGR.[LOCATION]
      ,INVTMFGR.[W_KEY]
      ,INVTMFGR.[RESERVED]
      ,[Invtmpnlink].[ORDERPREF]
      ,INVTMFGR.[UNIQMFGRHD]
      ,INVTMFGR.[Uniqwh]
  FROM INVTMFGR INNER JOIN InvtMPNLink ON Invtmfgr.UNIQMFGRHD =InvtMPNLink.UNIQMFGRHD 
  INNER JOIN [MfgrMaster] on InvtMPNLink.mfgrMasterId=MfgrMaster.MfgrMasterId and InvtMPNLink.uniq_key=invtmfgr.UNIQ_KEY
  WHERE Invtmfgr.IS_DELETED=0 and [MfgrMaster].IS_DELETED =0 and InvtMPNLink.is_deleted=0


  

          
    -- Insert statements for procedure here
	-- 04/14/15 YS Location length is changed to varchar(256)
	---02/28/18 YS added column LDISALLOWBUY from invtmfhd table. Ignore LDISALLOWBUY parts when safety stock is entered
	-- 12/14/20 YS fix available qty calculation. Need to make sure that if reserved from multiple w_key we calculate the available qty correctly.
	--- we do make an assumption which w_key were over issued. But currently there is nothing we can do about it. Since we just save the allocated qty and do not designate which one
	--- concidered as extra
	--- adding multiple temprary tables
	if OBJECT_ID('tempdb..#tempavail') is not NULL
		DROP table #tempavail


	if OBJECT_ID('tempdb..#tRes') is not NULL
		DROP table #tRes
	
	if OBJECT_ID('tempdb..#tResPrev') is not NULL
		DROP table #tResPrev
	if OBJECT_ID('tempdb..#tResTotal') is not NULL
		DROP table #tResTotal

	if OBJECT_ID('tempdb..#tExtra') is not NULL
		DROP table #tExtra
	if OBJECT_ID('tempdb..#tApply') is not NULL
		DROP table #tApply
	---12/14/20 YS changes to the select for #tempAvail
	--- remove the code with comments when tested and sure that the calculation is working
	--SELECT l.Uniq_key,M.PartMfgr,M.Mfgr_pt_no,
	--		ISNULL(G.QTY_OH,CAST(0.00 as Numeric(12,2))) as Qty_oh,
	--		ISNULL(G.[NETABLE],CAST(1 as bit)) as Netable, 
	--		ISNULL(G.[UniqWh],cast(' ' as CHAR(10))) as UniqWH,ISNULL(G.LOCATION,cast(' ' as varCHAR(256))) as Location ,
	--		isnull(G.[W_KEY],cast(' ' as CHAR(10))) as w_key ,ISNULL(G.[RESERVED],CAST(0.00 as Numeric(12,2))) as Reserved,
	--		l.[ORDERPREF] ,L.UNIQMFGRHD,M.SftyStk,M.MatlType,
	--		M.lDisallowkit   ,m.LDISALLOWBUY,
	--		t.KASEQNUM,isnull(t.totalAlloc,0.00) as totalAlloc,isnull(t.totalover,0.00) as totalover,t.wono,
	--		--g.QTY_OH-
	--		--case when t.totalAlloc is null then 0.00 
	--		--	when  t.totalAlloc <=abs(t.totalover) then 0.00
	--		--	else (isnull(t.totalAlloc,0.00)+isnull(t.totalover,0.00)) end as Availqty 
	--		-- 12/10/20 YS fix the claculation of the available qty. Remove reserved and add back over issue. Take into concideration that if shortage is negative and actual>0 negative shortage cannot be used as total over issued
	--		g.QTY_OH-g.Reserved+
	--		case when t.totalAlloc is null then 0.00 
	--			when  t.totalAlloc <abs(t.totalover) then t.totalAlloc
	--			else isnull(ABS(t.totalover),0.00) END as Availqty
	--	INTO #tempavail
	--	FROM InvtMPNLink L LEFT OUTER JOIN  Invtmfgr G ON L.UniqMfgrHd=G.UniqMfgrHd  and G.IS_DELETED=0
	--	INNER JOIN [MfgrMaster] M ON L.mfgrMasterId=M.MfgrMasterId
	--	outer apply
	--	(select  k.kaseqnum, k.uniq_key,k.wono,sum(shortqty) as totalover ,r.totalAlloc ,r.W_KEY
	--		from kamain k inner join 
	--	(select kaseqnum,w_key,sum(qtyalloc) as totalAlloc from INVT_RES group by w_key,kaseqnum) R on k.kaseqnum=r.kaseqnum
	--	where shortqty<0 and k.uniq_key=l.uniq_key and r.W_KEY=g.w_key
	--	group by k.KASEQNUM,k.UNIQ_KEY,k.wono,r.totalAlloc,r.w_key
	--	) T
	--	WHERE L.Is_deleted =0 

	SELECT l.Uniq_key,M.PartMfgr,M.Mfgr_pt_no,
			ISNULL(G.QTY_OH,CAST(0.00 as Numeric(12,2))) as Qty_oh,
			isnull(G.[W_KEY],cast(' ' as CHAR(10))) as w_key ,
			ISNULL(G.[RESERVED],CAST(0.00 as Numeric(12,2))) as Reserved,
			CAST(0.00 as Numeric(12,2)) as Availqty,   ---place for the availqty
			CAST(0.00 as Numeric(12,2)) as TotalApply,  --- place for the apply over issued
			ISNULL(G.[NETABLE],CAST(1 as bit)) as Netable, 
			ISNULL(G.[UniqWh],cast(' ' as CHAR(10))) as UniqWH,
			ISNULL(G.LOCATION,cast(' ' as varCHAR(256))) as [Location] ,
			l.[ORDERPREF] ,L.UNIQMFGRHD,M.SftyStk,M.MatlType,
			M.lDisallowkit   ,m.LDISALLOWBUY
		INTO #tempavail
		FROM InvtMPNLink L LEFT OUTER JOIN  Invtmfgr G ON L.UniqMfgrHd=G.UniqMfgrHd  and G.IS_DELETED=0
		INNER JOIN [MfgrMaster] M ON L.mfgrMasterId=M.MfgrMasterId
		WHERE L.Is_deleted =0 

	--12/14/20 YS Find all that have allocated>0 for the w_key in the #tempavail
	select wono,kaseqnum,w_key,sum(qtyalloc) as totalAlloc 
        INTO #tRes
		from INVT_RES  where  
		exists (select 1 from #tempavail t where t.w_key=invt_res.w_key and t.Reserved>0) 
		group by w_key,kaseqnum,wono
		having sum(qtyalloc)>0

	---12/14/20 YS find running total allocated for each kaseqnum
	select kaseqnum,w_key,totalAlloc,wono,
		running_totalAllocated = sum(totalAlloc) OVER (partition by kaseqnum ORDER BY totalAlloc 
                                            ROWS BETWEEN UNBOUNDED PRECEDING 
                                            AND CURRENT ROW)
	INTO #tresTotal
	FROM #tRes
		
	--12/14/20 YS find prior running total to be able apply the correct amount
	select *,
	--12/16/20 YS replace null value for the prev_running_totalAllocated  with 0.00 
		prev_running_totalAllocated = ISNULL(LAG(running_totalAllocated) OVER (partition by kaseqnum ORDER BY totalAlloc),0.00),
		rowseq = ROW_NUMBER() OVER (partition by kaseqnum ORDER BY totalAlloc)
	INTO #tResPrev
	from #tresTotal
	---12/14/20 YS find all extra qty allocated for each kaseqnum where uniq_key exists in the #tempavail
	select  k.kaseqnum, k.uniq_key,k.wono,SHORTQTY,
		act_qty,allocatedQty,ReqQty=allocatedQty+SHORTQTY+ACT_QTY,
		/* 12/16/20 YS take another look at calculationg the extra qty
		1. If ShortQty=0 or ShortQty>0 or (ShortQty<0 and AllocatedQty=0) we do not have any extara qty avaialble (Extra=0)
		2. If ShortQty<0 and Act_qty=0  extra=ABS(Required-Act_qty-AllocatedQTy)
		3. If ShortQty<0 and Act_qty<>0 and AllocatedQty<>0 and Act_qty<AllocatedQty extra ABS(Required-Act_qty-AllocatedQTy)
		4. IF ShortQty<0 and Act_qty<>0 and AllocatedQty<>0 and Act_qty>AllocatedQty and Act_qty<Req extra ABS((Required-Act_qty-AllocatedQTy)
		5. If ShortQty<0 and Act_qty<>0 and AllocatedQTy<>0 and Act_qty>Req Extra=AllocatedQty
		*/
		---1. If ShortQty=0 or ShortQty>0 or (ShortQty<0 and AllocatedQty=0) we do not have any extara qty avaialble (Extra=0)
		--- we are not including Shortqty>=0 becuase we are selecting only records with shortqty<0
		CASE WHEN (ShortQty<0 and AllocatedQty=0) THEN 0.00
		---5. If ShortQty<0 and Act_qty<>0 and AllocatedQTy<>0 and Act_qty>Req Extra=AllocatedQty
		WHEN ShortQty<0 and Act_qty<>0 and allocatedQty<>0 and Act_qty>(AllocatedQty+Act_qty+SHORTQTY) THEN allocatedQty
		--- for all other cases use ABS(Required-Act_qty-AllocatedQTy) which is an abs value for the shortage
		ELSE ABS(SHORTQTY) END as ThisExtraQty
		----- 12/15/20 YS added case for e.g. req 200, allocated 20, act_qty 230, shortage -50 - extra=20(allocated)
		--CASE WHEN SHORTQTY<0 and allocatedQty<ABS(ShortQty) THEN allocatedQty
		----12/15/20 YS added case for e.g. req 300, allocated 50, act_qty 265, shortage -15 - extra=15
		--	WHEN ShortQty<0 and allocatedQty>ABS(ShortQty) and allocatedQty<(allocatedQty+SHORTQTY+ACT_QTY) then ABS(shortQty)
		--	--- e.g. req 200 allocated <200, extra 0.00
		--		WHEN allocatedQty-(allocatedQty+SHORTQTY+ACT_QTY)<=0 then 0.00 
		--		--- e.g. required 200, allocated 240, extra 40
		--		else allocatedQty-(allocatedQty+SHORTQTY+ACT_QTY) end as ThisExtraQtgy
		INTO #tExtra
		from kamain k where 
		---12/15/20 YS check for shortages<0
		 --(allocatedQty-(allocatedQty+SHORTQTY+ACT_QTY)>0)
		 ShortQty<0
		and exists 
		(select 1 from #tempavail t where t.uniq_key=k.UNIQ_KEY)
	--12/14/20 YS find qty to apply
	--12/16/20 YS calculate apply qty
	SELECT   tr.kaSeqnum,tr.w_key,tr.WONO,
         tr.totalAlloc,
		case when tr.prev_running_totalAllocated=0 THEN
			CASE WHEN tr.totalAlloc>te.ThisExtraQty THEN te.ThisExtraQty
			ELSE tr.totalAlloc END -- this is the first record no previous total
		When tr.prev_running_totalAllocated>te.ThisExtraQty THEN 0  --- run out of extra
		WHEN tr.prev_running_totalAllocated<te.ThisExtraQty THEN
			---compare new extra
	        CASE WHEN tr.totalAlloc>(ThisExtraQty-prev_running_totalAllocated) THEN ThisExtraQty-prev_running_totalAllocated
			ELSE tr.totalAlloc END
			END as ExtrApply
		  INTO #tApply
	FROM     #tresprev tr INNER JOIN #tExtra te ON tr.KaSeqnum=tE.KASEQNUM
	---12/16/20 YS only select records with extra qty
	where te.ThisExtraQty>0
	order by tr.KaSeqnum ,tr.rowseq

	/*test
	select * from #tresprev where kaseqnum in ('GFBJR48ZEI','N9FX9XAPHX')
	--update #tExtra set ThisExtraQty=10 where ThisExtraQty>0 and  uniq_key='5KXGXI8ERA'
	select * from #tExtra where uniq_key='5KXGXI8ERA'
	select * from #tApply where kaseqnum in ('GFBJR48ZEI','N9FX9XAPHX')
	*/
	--12/14/20 YS find total to apply for w_key
	;with
		sumapply
		as
		(select w_key, sum(ISNULL(ExtrApply,0.00)) as TotalApply
		from #tapply
		group by w_key)
		--- and populate TotalApply in #tempavail
		update #tempavail set 
		[#tempavail].TotalApply=[sumapply].TotalApply
		from sumapply where sumapply.w_key= [#tempavail].w_key 
	
	--12/14/20 YS Caluclate AvailQty
	update #tempavail set Availqty=Qty_oh-Reserved+TotalApply
	/*test
	select * from #tempavail where uniq_key='5KXGXI8ERA'
	*/
-- 12/10/20 YS fix the claculation of the available qty. Remove reserved and add back over issue. Take into concideration that if shortage is negative and actual>0 negative shortage cannot be used as total over issued
---	get sum of the Availqty otherwise for multiple work orders will have multiple results
		select Uniq_key,PartMfgr,Mfgr_pt_no,
			--Availqty as Qty_oh,
			 sum(Availqty) as Qty_oh,
			 Netable, 
			UniqWH, Location ,
			w_key ,Reserved,
			[ORDERPREF] ,UNIQMFGRHD,SftyStk,MatlType,
			lDisallowkit   ,LDISALLOWBUY 
			from #tempavail 
			group by Uniq_key,PartMfgr,Mfgr_pt_no,
			Netable, 
			UniqWH, Location ,
			w_key ,Reserved,
			[ORDERPREF] ,UNIQMFGRHD,SftyStk,MatlType,
			lDisallowkit   ,LDISALLOWBUY 

			--update mrpwh qty_oh with available qty
			---12/10/20 YS update with the sum()
		UPDATE MrpWh set qty_oh =t.sumQtyoh from (select sum(Availqty) as sumQtyoh,w_key from #tempavail group by w_key ) t where t.w_key=mrpwh.W_KEY
			/*test*/
			---select * from #tempavail where uniq_key='5KXGXI8ERA'
		if OBJECT_ID('tempdb..#tempavail') is not NULL
			DROP table #tempavail

		if OBJECT_ID('tempdb..#tRes') is not NULL
			DROP table #tRes
	
		if OBJECT_ID('tempdb..#tResPrev') is not NULL
			DROP table #tResPrev
		if OBJECT_ID('tempdb..#tResTotal') is not NULL
			DROP table #tResTotal

		if OBJECT_ID('tempdb..#tExtra') is not NULL
			DROP table #tExtra
		if OBJECT_ID('tempdb..#tApply') is not NULL
			DROP table #tApply
END