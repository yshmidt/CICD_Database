
-- =============================================
-- Author:		Debbie
-- Create date: 09/13/2012
-- Description:	Created for the Over Issued Material Report within Kitting
-- Reports:		kitoveri.rpt 
-- Modified:	10/13/14 YS removed invtmfhd table
--				10/30/15 DRP:   added /*CUSTOMER LIST*/, removed the micssys
-- 05/26/20 VL copied the code from zMpsMfgr and modified for cube version.
-- =============================================
CREATE PROCEDURE  [dbo].[rptKitOverIssueInfo]


		@lcType as char (20) = ''  -- user would indicate either 'Internal' or 'Consigned'
		,@lcCustNo as varchar (Max) = 'All' --
		,@userId uniqueidentifier=null

as
begin				

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

/*RECORD SELECTION*/

if (@lcType = 'Consigned')
	begin
	-- 05/26/20 VL comment out old code
	----10/13/14 YS removed invtmfhd table
	--SELECT	Inventor.Part_class,case when Inventor.Part_sourc<>'CONSG' then Inventor.Part_no else Inventor.CustPartNo end AS Part_no
	--		,case when Inventor.Part_sourc <>'CONSG' then Inventor.Revision else Inventor.CustRev end AS Revision,Inventor.Prod_id
	--		,Inventor.Descript,Inventor.Part_type,Inventor.Part_sourc,m.Partmfgr,Invtmfgr.Qty_oh
	--		,right(LTRIM(rtrim(invtmfgr.location)),10) as wono,customer.CUSTNAME
	--		--,LIC_NAME	--10/30/15 DRP:  removed

	--FROM	InvtMPNLink L
	--		inner join MfgrMaster M on l.mfgrMasterId=M.MfgrMasterId
	--		inner join Invtmfgr on L.UNIQMFGRHD = invtmfgr.UNIQMFGRHD
	--		inner join Inventor on L.UNIQ_KEY = INVENTOR.UNIQ_KEY
	--		inner join Warehous on invtmfgr.UNIQWH = warehous.UNIQWH
	--		inner join customer on inventor.CUSTNO = customer.CUSTNO
	--		--cross join MICSSYS	--10/30/15 DRP:  removed

	--WHERE	Warehous.Warehouse='WO-WIP'
	--		AND Invtmfgr.Qty_oh>0 
	--		AND Invtmfgr.Is_Deleted <> 1 
	--		AND L.Is_Deleted =0
	--		--and Customer.CUSTNAME like case when @lcCust ='*' then '%' else @lcCust+'%' end	--10/30/15 DRP:  replaced by the below.
	--		and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=inventor.custno))

	--ORDER BY Part_class,Part_type,Part_no,Partmfgr,Wono

	-- 05/26/20 VL start new code
	SELECT Inventor.Part_class,case when Inventor.Part_sourc<>'CONSG' then Inventor.Part_no else Inventor.CustPartNo end AS Part_no
				,case when Inventor.Part_sourc <>'CONSG' then Inventor.Revision else Inventor.CustRev end AS Revision
				,Inventor.Descript,Inventor.Part_type,Inventor.Part_sourc,m.Partmfgr, 
				Warehouse, location,T.wono, t.KASEQNUM
				,ISNULL(G.QTY_OH,CAST(0.00 as Numeric(12,2))) as Qty_oh
				,ISNULL(G.[RESERVED],CAST(0.00 as Numeric(12,2))) as Reserved
				,ISNULL(t.totalAlloc,0.00) as totalAlloc
				--,ISNULL(t.totalover,0.00) as totalOver
				,CASE WHEN ROW_NUMBER() OVER (PARTITION BY Part_no, Revision, partmfgr,Wono ORDER BY Part_no, Revision, partmfgr,Wono) = 1 THEN ISNULL(-t.totalover,0.00) ELSE 0 END AS totalOver
				--,g.QTY_OH-
				--case when t.totalAlloc is null then 0.00 
				--	when  t.totalAlloc <=abs(t.totalover) then 0.00
				--	else (isnull(t.totalAlloc,0.00)+isnull(t.totalover,0.00)) end as Availqty 
				,Customer.Custname
			FROM InvtMPNLink L LEFT OUTER JOIN  Invtmfgr G ON L.UniqMfgrHd=G.UniqMfgrHd and G.IS_DELETED=0
			INNER JOIN [MfgrMaster] M ON L.mfgrMasterId=M.MfgrMasterId
			INNER JOIN Inventor ON l.UNIQ_KEY = INVENTOR.UNIQ_KEY
			INNER JOIN Warehous ON g.UNIQWH = warehous.UNIQWH
			INNER JOIN customer on inventor.CUSTNO = customer.CUSTNO
			OUTER APPLY
				(SELECT k.kaseqnum, k.uniq_key,k.wono,sum(shortqty) as totalOver ,r.totalAlloc ,r.W_KEY
					FROM Kamain k INNER JOIN
				(SELECT kaseqnum,w_key,sum(qtyalloc) as totalAlloc from INVT_RES group by w_key,kaseqnum) R on k.kaseqnum=r.kaseqnum
				WHERE shortqty<0 and k.uniq_key=l.uniq_key and r.W_KEY=g.w_key
				group by k.KASEQNUM,k.UNIQ_KEY,k.wono,r.totalAlloc,r.w_key
				) T
			WHERE L.Is_deleted =0 
			AND T.Wono IS NOT NULL
			AND EXISTS(SELECT 1 FROM Kamain INNER JOIN Woentry ON Kamain.Wono = Woentry.Wono AND KITSTATUS = 'KIT PROCSS' AND Kamain.SHORTQTY<0)
			AND (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=inventor.custno))
			ORDER BY Part_class, Part_type, Part_no,partmfgr,Wono

	end
	
else if (@lcType <> 'Consigned') 
	Begin 
		-- 05/26/20 VL comment out old code
--		SELECT	Inventor.Part_class,case when Inventor.Part_sourc<>'CONSG' then Inventor.Part_no else Inventor.CustPartNo end AS Part_no
--			,case when Inventor.Part_sourc <>'CONSG' then Inventor.Revision else Inventor.CustRev end AS Revision,Inventor.Prod_id
--			,Inventor.Descript,Inventor.Part_type,Inventor.Part_sourc,m.Partmfgr,Invtmfgr.Qty_oh
--			,right(LTRIM(rtrim(invtmfgr.location)),10) as wono
--			--,cast('' as char(35)) as CUSTNAME
--			--,LIC_NAME	--10/30/15 DRP:  removed

----10/13/14 YS removed invtmfhd table
--	FROM	InvtMPNLink L
--			inner join MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
--			inner join Invtmfgr on l.UNIQMFGRHD = invtmfgr.UNIQMFGRHD
--			inner join Inventor on l.UNIQ_KEY = INVENTOR.UNIQ_KEY
--			inner join Warehous on invtmfgr.UNIQWH = warehous.UNIQWH
--			--cross join MICSSYS		--10/30/15 DRP:  removed

--	WHERE	Warehous.Warehouse='WO-WIP'
--			AND Invtmfgr.Qty_oh>0 
--			AND Invtmfgr.Is_Deleted <> 1 
--			AND l.Is_Deleted =0
--			and inventor.PART_SOURC <> 'CONSG'

--	ORDER BY Part_class,Part_type,Part_no,Partmfgr,Wono

	-- 05/26/20 VL start new code
	SELECT Inventor.Part_class,case when Inventor.Part_sourc<>'CONSG' then Inventor.Part_no else Inventor.CustPartNo end AS Part_no
				,case when Inventor.Part_sourc <>'CONSG' then Inventor.Revision else Inventor.CustRev end AS Revision
				,Inventor.Descript,Inventor.Part_type,Inventor.Part_sourc,m.Partmfgr, 
				Warehouse, location,T.wono, t.KASEQNUM
				,ISNULL(G.QTY_OH,CAST(0.00 as Numeric(12,2))) as Qty_oh
				,ISNULL(G.[RESERVED],CAST(0.00 as Numeric(12,2))) as Reserved
				,ISNULL(t.totalAlloc,0.00) as totalAlloc
				--,ISNULL(t.totalover,0.00) as totalOver
				,CASE WHEN ROW_NUMBER() OVER (PARTITION BY Part_no, Revision, partmfgr, Wono ORDER BY Part_no, Revision, partmfgr,Wono) = 1 THEN ISNULL(-t.totalover,0.00) ELSE 0 END AS totalOver
				--,g.QTY_OH-
				--case when t.totalAlloc is null then 0.00 
				--	when  t.totalAlloc <=abs(t.totalover) then 0.00
				--	else (isnull(t.totalAlloc,0.00)+isnull(t.totalover,0.00)) end as Availqty 
			FROM InvtMPNLink L LEFT OUTER JOIN  Invtmfgr G ON L.UniqMfgrHd=G.UniqMfgrHd and G.IS_DELETED=0
			INNER JOIN [MfgrMaster] M ON L.mfgrMasterId=M.MfgrMasterId
			INNER JOIN Inventor ON l.UNIQ_KEY = INVENTOR.UNIQ_KEY
			INNER JOIN Warehous ON g.UNIQWH = warehous.UNIQWH
			OUTER APPLY
				(SELECT k.kaseqnum, k.uniq_key,k.wono,sum(shortqty) as totalOver ,r.totalAlloc ,r.W_KEY
					FROM Kamain k INNER JOIN
				(SELECT kaseqnum,w_key,sum(qtyalloc) as totalAlloc from INVT_RES group by w_key,kaseqnum) R on k.kaseqnum=r.kaseqnum
				WHERE shortqty<0 and k.uniq_key=l.uniq_key and r.W_KEY=g.w_key
				group by k.KASEQNUM,k.UNIQ_KEY,k.wono,r.totalAlloc,r.w_key
				) T
			WHERE L.Is_deleted =0 
			AND T.Wono IS NOT NULL
			AND EXISTS(SELECT 1 FROM Kamain INNER JOIN Woentry ON Kamain.Wono = Woentry.Wono AND KITSTATUS = 'KIT PROCSS' AND Kamain.SHORTQTY<0)
			AND inventor.PART_SOURC <> 'CONSG'
			ORDER BY Part_class, Part_type, Part_no, Partmfgr,Wono
	end 
end