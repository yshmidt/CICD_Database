-- =============================================
-- Author:		Yelena
-- Create date: 01/12/2015
-- Description:	This Stored Procedure was created for the Inventory Transaction History with Balance and will replace rptInvtTransHistwBal
-- original Report:  icrpt4.rpt
--01/20/15 YS added conversion from purchase to stock UOM
--03/12/15 YS replace invtmfhd table with Invtmpnlink and mfgrmaster 
-- 08/24/15 DRP/YS:  added the sort order at the end for Quickview. Changed RunningTotal to be RunningBalOh, in order to have the QuickView not think it is a $ value
--					 Had to make sure to change the serialno to be cast('' as char(30)) as serialno instead of '' as serialno within the Po Receipt, Po Reject and DMR Return sections.  it was causing issues with the reporting
--					 In the DMR Return section had to change <<CASE WHEN pi.poittype = 'In Store' then 1 else 0 END>> to <<0 as instore>> because once ISP Po is created the stock is no longer considered Instore. 
--					 also needed to add <<and pi.POITTYPE <> 'In Store'>> in the Po Receipt section of code.
--05/04/16 YS change calculation to show the beginning balance for the transaction
--- 05/05/16 YS remove serialno from the history
--05/05/16 DRP:  change the RunningBalOH column name to be TransactionBeginningBalance		
--05/05/16 YS Note : when receiving and inspection is done this report will have to be modified
--09/11/19 VL Added ipkey (MTC) and ipkey qty, comment out PO Receipt, PO Reject and DMR Return for now until it's done
--09/18/19 VL Added IsLot, need to use it in report form 
--09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
-- 12/12/19 VL Uncomment and changed the PO receiving and PO Reject part and leave the DMR part still comment
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtTransHistwBal2012WM]
-- changing parameters to work on the  web
		@lcUniq_key char(10),
		@lcType as char (20) = 'Internal',  --where the user would specify Internal, Internal & In Store, In Store, Consigned
		@lcCustNo as varchar(max) = 'All',
		@lcDateStart as smalldatetime= null,
		@userId uniqueidentifier = null
	
AS
BEGIN


--BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @lcDateStart=CASE WHEN @lcDateStart is null then @lcDateStart else DATEADD(day,-1,cast(@lcDateStart as smalldatetime))  END			
	
	--get list of customers for @userid with access
	if (@lcType='Consigned') 	
	BEGIN	
		DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid ;
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE
		BEGIN
			IF  @lcCustNo='All'	
			BEGIN
				INSERT INTO @Customer SELECT CustNo FROM @tCustomer
			END -- IF  @lcCustNo='All'	
		END -- IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
		;with PartInfo
			as
			(
			
			select Uniq_key,part_class,Part_type,custpartno as Part_no,custrev as revision,[descript],part_sourc,Inventor.custno 
					from Inventor INNER JOIN @Customer C ON Inventor.custno=C.Custno
					where part_sourc='CONSG' and uniq_key = @lcUniq_key
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--select Uniq_key,uniqmfgrhd, partmfgr,mfgr_pt_no,matltype
			--from Invtmfhd where exists (select 1 from partinfo where partinfo.uniq_key=invtmfhd.uniq_key)
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype
			from Invtmpnlink L inner join mfgrmaster M on l.mfgrmasterid=m.mfgrmasterid where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			
			WhLoc
			as
			(
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse,  
				SUM(qty_oh) OVER (partition by uniq_key ORDER BY Uniq_key) as CurrentBalance
				from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
				where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			-- use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 'from' before 'to', when date is the same
			--- 05/05/16 YS remove serialno from the history
			AllTransactions
			as(
			select CAST('Receiving' as varchar(25)) as transType,Ir.Uniq_key,space(10) as fromwkey,ir.w_key as towkey, 
			mfhd.partmfgr,mfhd.mfgr_pt_no,ir.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			IR.[Date],IR.Qtyrec as TransQty,IR.LotCode,IR.Expdate,IR.Reference,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,COMMREC as reason,Mfhd.MatlTYpe,cast(' ' as varchar(25)) as woPoRef,space(10) as uniqrecdtl,1 as nsort
			-- 09/11/19 VL added Ipkey link
			,IR.INVTREC_NO AS UniqTransKey
			 from Invt_rec IR left outer join mfhd on ir.uniqmfgrhd=mfhd.uniqmfgrhd
			 left outer join whloc on ir.w_key=whloc.w_key
			 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			 LEFT OUTER JOIN aspnet_Users ON IR.fk_userid = aspnet_Users.UserId
			 where [date] > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=ir.uniq_key) 
			 UNION ALL
			 --- 05/05/16 YS remove serialno from the history
			 SELECT case when qtyisu<0 then 'Issue Return' else 'Issue' end as transType, ISS.Uniq_key,Iss.W_KEY as fromwkey,space(10) as towkey,
			mfhd.partmfgr,mfhd.mfgr_pt_no,iss.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			 Iss.[Date],-QTYISU as TransQty,Iss.LOTCODE,Iss.EXPDATE,Iss.REFERENCE,
				-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				--Iss.SAVEINIT,
				aspnet_Users.UserName,			 
				Iss.TRANSREF,ISSUEDTO as reason,Mfhd.MatlTYpe,cast(iss.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,
				5 as nsort	
				-- 09/11/19 VL added Ipkey link
				, iss.INVTISU_NO AS UniqTransKey					
				FROM INVT_ISU iss left outer join Mfhd on iss.uniqmfgrhd=mfhd.uniqmfgrhd
				LEFT OUTER JOIN WhLoc on iss.w_key=whloc.w_key
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON Iss.fk_userid = aspnet_Users.UserId
				WHERE  --(@lcRptType='All' or @lcRptType='Issues') AND
				iss.[date] > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=iss.uniq_key)
			UNION ALL
			--- 05/05/16 YS remove serialno from the history
			SELECT 'Transfer From',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,fromwh.Uniqwh,fromwh.whno,fromwh.location,fromwh.warehouse,fromwh.instore,
			[date],-QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,REASON,Mfhd.MatlTYpe,cast(tra.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,3 as nsort	
			-- 09/11/19 VL added Ipkey link
			,tra.INVTXFER_N AS UniqTransKey			
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc fromwh on tra.fromwkey=fromwh.w_key
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE 
			tra.[date] > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			UNION ALL
			--- 05/05/16 YS remove serialno from the history
			SELECT 'Transfer To',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,towh.Uniqwh,towh.whno,towh.location,towh.warehouse,towh.instore,
			[date],QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,REASON,Mfhd.MatlTYpe,cast(tra.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl	,4 as nsort		
			-- 09/11/19 VL added Ipkey link
			,tra.INVTXFER_N AS UniqTransKey	
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc towh on tra.towkey=towh.w_key
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE tra.[date] >@lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			)
			-- for sql 2012 and up
			select p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,p.custno,
				C.CustName,A.* ,
				--05/04/16 YS change calculation to show the beginning balance for the transaction
				--SUM(TransQty) OVER (ORDER BY a.uniq_key,date,nsort ROWS UNBOUNDED PRECEDING) as RunningBalOh,q.CurrentBalance
				q.CurrentBalance+SUM(-TransQty) OVER (ORDER BY part_no,revision,date desc,nsort desc ROWS UNBOUNDED PRECEDING) as TransactionBeginningBalance,q.CurrentBalance
				from AllTransactions a inner join partinfo P on A.uniq_key=P.Uniq_key 
				inner join Customer C on p.custno=C.Custno
				OUTER APPLY (select distinct uniq_key,CurrentBalance from WhLoc where whloc.UNIQ_KEY=p.UNIQ_KEY) Q
				order by part_no,revision,date,nsort
	END --- if (@lcType='Consigned')
	ELSE   -- @lcType='Consigned')
	BEGIN
		-- internal parts
		;with PartInfo
			as
			(
			--12/23/14 YS added part-class selection
			select Uniq_key,part_class,Part_type,Part_no,revision,[descript],part_sourc 
				from Inventor where uniq_key = @lcUniq_key
			
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--select Uniq_key,uniqmfgrhd, partmfgr,mfgr_pt_no,matltype
			--from Invtmfhd where exists (select 1 from partinfo where partinfo.uniq_key=invtmfhd.uniq_key)
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype
			from Invtmpnlink L inner join mfgrmaster M on l.mfgrmasterid=m.mfgrmasterid where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			-- try limit based on @lcTYpe did not help, will remove from simplicity
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse,qty_oh from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
				where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
		
		
			),
			-- use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 'from' before 'to', when date is the same
			--- 05/05/16 YS remove serialno from the history
			AllTransactions
			as(
			select CAST('Receiving' as varchar(25)) as transType,Ir.Uniq_key,space(10) as fromwkey,ir.w_key as towkey, 
			mfhd.partmfgr,mfhd.mfgr_pt_no,ir.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			IR.[Date],IR.Qtyrec as TransQty,IR.LotCode,IR.Expdate,IR.Reference,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,COMMREC as reason,Mfhd.MatlTYpe,cast(' ' as varchar(25)) as woPoRef,space(10) as uniqrecdtl,1 as nsort
			-- 09/11/19 VL added Ipkey link
			,IR.INVTREC_NO AS UniqTransKey
			 from Invt_rec IR left outer join Mfhd on ir.uniqmfgrhd=mfhd.uniqmfgrhd
			 left outer join whloc on ir.w_key=whloc.w_key
			 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			 LEFT OUTER JOIN aspnet_Users ON IR.fk_userid = aspnet_Users.UserId
			 where date > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=ir.uniq_key) 
			 UNION ALL
			 --- 05/05/16 YS remove serialno from the history
			SELECT case when qtyisu<0 then 'Issue Return' else 'Issue' end as transType, ISS.Uniq_key,Iss.W_KEY as fromwkey,space(10) as towkey,
			 mfhd.partmfgr,mfhd.mfgr_pt_no,iss.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			 Iss.[Date],-QTYISU as TransQty,Iss.LOTCODE,Iss.EXPDATE,Iss.REFERENCE,
				-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				--Iss.SAVEINIT,
				aspnet_Users.UserName,
				Iss.TRANSREF,ISSUEDTO as reason,Mfhd.MatlTYpe,cast(iss.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,
				5 as nsort
				-- 09/11/19 VL added Ipkey link	
				,iss.INVTISU_NO AS UniqTransKey	
				FROM INVT_ISU iss left outer join Mfhd on iss.uniqmfgrhd=mfhd.uniqmfgrhd
				LEFT OUTER JOIN WhLoc on iss.w_key=whloc.w_key
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON Iss.fk_userid = aspnet_Users.UserId
				WHERE iss.date > @lcDateStart   and exists (select 1 from partinfo where partinfo.uniq_key=iss.uniq_key)
			UNION ALL
			SELECT 'Transfer From',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,fromwh.Uniqwh,fromwh.whno,fromwh.location,fromwh.warehouse,fromwh.instore,
			[date],-QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			-- 12/23/14 YS added GL_NBR_INV for 'from' transfer and gl_nbt for 'to' transfer transactions as woPoRef
			--- 05/05/16 YS remove serialno from the history
			TRANSREF,REASON,Mfhd.MatlTYpe,cast('G/L:' +tra.GL_NBR_INV as varchar(25)) as woPoRef,space(10) as uniqrecdtl,3 as nsort		
			-- 09/11/19 VL added Ipkey link	
			,tra.INVTXFER_N AS UniqTransKey		
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc fromwh on tra.fromwkey=fromwh.w_key
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE tra.date > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			UNION ALL
			SELECT 'Transfer To',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,towh.Uniqwh,towh.whno,towh.location,towh.warehouse,towh.instore,
			[date],QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			-- 12/23/14 YS added GL_NBR_INV for 'from' transfer and gl_nbt for 'to' transfer transactions as woPoRef
			--- 05/05/16 YS remove serialno from the history
			TRANSREF,REASON,Mfhd.MatlTYpe,cast('G/L:' +tra.GL_NBR as varchar(25)) as woPoRef,space(10) as uniqrecdtl	,4 as nsort		
			-- 09/11/19 VL added Ipkey link	
			,tra.INVTXFER_N AS UniqTransKey	
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc towh on tra.towkey=towh.w_key
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE tra.date > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			-- 12/12/19 VL tried to add the PO receiving and reject part back
			-- 09/11/19 VL remove PO Receipt, PO Reject and DMR Return for now until it's done
			UNION ALL
			-- added limit based on @lcType
			--01/20/15 YS added conversion from purchase to stock UOM
			--- 05/05/16 YS remove serialno from the history
			select 'PO Receipt',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
			pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,pl.location,w.warehouse,case when pi.poittype='In Store' then 1 else 0 END,
			pr.recvDate as [date],	
			case when pi.Pur_uofm=pi.U_of_meas THEN isnull(lt.lotqty,pl.accptqty) ELSE
			dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,isnull(lt.lotqty,pl.accptqty)) END as transqty,
			isnull(lt.lotcode,space(15)) as lotcode,
			EXPDATE,isnull(REFERENCE,space(12)) as reference,
			--05/05/16 YS for now create empty column for saveinit, when receiving and inspection is done this report will have to be changed
			--RECINIT as SAVEINIT,
			-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--space(8) as saveInit,
			aspnet_Users.UserName,
			'' as TRANSREF,'' as reason,
			--cast('' as char(30)) as serialno	,
				Mfhd.MatlTYpe,pi.ponum as woPoRef,pr.uniqrecdtl,1 as nsort		
				-- 12/12/19 VL added Ipkey link	
				,PL.LOC_UNIQ AS UniqTransKey	
				from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
				inner join porecloc PL on pr.uniqrecdtl=pl.fk_uniqrecdtl
				left outer join Warehous w on pl.uniqwh=w.uniqwh
				left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
				left outer join poreclot lt on pl.loc_uniq=lt.loc_uniq 
				-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				LEFT OUTER JOIN aspnet_Users ON pr.Edituserid = aspnet_Users.UserId
				where pr.recvDate > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) 
				--12/23/14 YS remove records with 0 accepted qty
				AND pl.accptqty<>0.00
				AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))
				and pi.POITTYPE <> 'In Store'	--08/24/15 DRP:  Added
			UNION ALL
			select 'PO Reject',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
			pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,'PO:'+PI.PONUM as location,'MRB',CASE WHEN pi.poittype = 'In Store' then 1 else 0 END,
			pr.recvDate as [date],
			case when pi.Pur_uofm=pi.U_of_meas THEN isnull(lt.rejlotqty,pl.rejqty) ELSE 
			dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,isnull(lt.rejlotqty,pl.rejqty)) END as transqty,
			isnull(lt.lotcode,space(15)) as lotcode,
			EXPDATE,isnull(REFERENCE,space(12)) as reference,
			--05/05/16 YS for now create empty column for saveinit, when receiving and inspection is done this report will have to be changed
			--RECINIT as SAVEINIT,
			-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--space(8) as saveInit,
			aspnet_Users.UserName,
			'' as TRANSREF,'' as reason,
			--- 05/05/16 YS remove serialno from the history
			--cast('' as char(30)) as serialno,
				mfhd.matlType,pi.ponum as woPoRef,pr.uniqrecdtl,2 as nsort	
				-- 12/12/19 VL added Ipkey link	
				,PL.LOC_UNIQ AS UniqTransKey					
				from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
				inner join porecloc PL on pr.uniqrecdtl=pl.fk_uniqrecdtl
				OUTER APPLY (SELECT warehouse,uniqwh,whno from Warehous where warehouse='MRB') w
				left outer join poreclot lt on pl.loc_uniq=lt.loc_uniq 
				-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				LEFT OUTER JOIN aspnet_Users ON pr.Edituserid = aspnet_Users.UserId
				left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
				where pr.recvDate > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) and pl.rejqty<>0.00 
				--AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))
			-- 12/12/19 VL End
			--UNION ALL
			--select 'DMR Return',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
			--pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,'PO:'+PI.PONUM as location,'MRB'
			--,0 as instore,	--CASE WHEN pi.poittype = 'In Store' then 1 else 0 END,	--08/24/15 DRP:
			--MRB.RMA_DATE as [date],	
			--case when pi.Pur_uofm=pi.U_of_meas THEN - MRB.RET_QTY ELSE 
			--- dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,MRB.RET_QTY) END as transqty,
			--space(15) as lotcode,
			--NULL as EXPDATE,space(12) as reference,
			--MRB.Initial as SAVEINIT,'' as TRANSREF,'' as reason,
			----12/23/14 YS show DMR_NO in woPoRef
			----- 05/05/16 YS remove serialno from the history
			----cast('' as char(30)) as serialno,
			--mfhd.matlType,'DMR: '+mrb.dmr_no as woPoRef,pr.uniqrecdtl	,5 as nsort			
			--	from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
			--	inner join PORECMRB MRB on pr.uniqrecdtl=mrb.fk_uniqrecdtl
			--	OUTER APPLY (SELECT warehouse,uniqwh,whno from Warehous where warehouse='MRB') w
			--	left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
			--	where MRB.RMA_DATE > @lcDateStart and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) 
			--	--AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))
-- 09/11/19 VL End}
			)
			
			-- for sql 2012 and up
			, ZTrans AS
			(
			select p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,' ' as custno, ' ' as custname,
				A.*,--ROW_NUMBER() OVER (ORDER BY  part_no,revision,date,nsort) as nsequence , 
				--05/04/16 YS change calculation to show the beginning balance for the transaction
				--SUM(TransQty) OVER (ORDER BY a.uniq_key,date,nsort ROWS UNBOUNDED PRECEDING) as RunningBalOh,q.CurrentBalance
				q.CurrentBalance+SUM(-TransQty) OVER (ORDER BY part_no,revision,date desc,nsort desc ROWS UNBOUNDED PRECEDING) as TransactionBeginningBalance,
				q.CurrentBalance
				from AllTransactions a inner join partinfo P on A.uniq_key=P.Uniq_key
				OUTER APPLY (SELECT uniq_key,sum(qty_oh) as CurrentBalance 
							from WhLoc 
								where whloc.uniq_key=p.uniq_key  
								and ((@lcType='Internal & In Store') OR (@lcType='In Store' and WhLoc.instore=1) OR (@lcType='Internal' and WhLoc.instore=0))
								group by whloc.uniq_key ) Q
				where ((@lcType='Internal & In Store') OR (@lcType='In Store' and a.instore=1) OR (@lcType='Internal' and a.instore=0))
				-- 09/11/19 VL comment out for now, will use in last sql 
				--order by part_no,revision,Date Desc, nsort desc		--08/24/15 DRP/YS:  Added
			)
			-- 09/11/19 VL Combine the final result with ipkey and ipkey qty
			-- 09/18/19 VL added lotdetail IsLot, used in report form
			-- 12/12/19 VL added Ipkey link	for PO Receipt and PO reject
			SELECT ZTrans.*, 
				CASE WHEN Transtype = 'Receiving' THEN iRecIpKey.ipkeyunique ELSE CASE WHEN Transtype like 'Issue%' THEN issueipkey.ipkeyunique ELSE 
					CASE WHEN Transtype = 'Transfer From' THEN iTrFr.fromIpkeyunique ELSE CASE WHEN Transtype = 'Transfer To' THEN iTrTo.toIpkeyunique ELSE
					CASE WHEN Transtype = 'PO Receipt' THEN POrec.IPKEYUNIQUE ELSE CASE WHEN Transtype = 'PO Reject' THEN POrej.IPKEYUNIQUE END END
					END END END END AS MTC,
				CASE WHEN Transtype = 'Receiving' THEN iRecIpKey.qtyReceived ELSE CASE WHEN Transtype like 'Issue%' THEN issueipkey.qtyissued ELSE 
					CASE WHEN Transtype = 'Transfer From' THEN iTrFr.qtyTransfer ELSE CASE WHEN Transtype = 'Transfer To' THEN iTrTo.qtyTransfer END END END END AS MTCQty,
					CASE WHEN Lotdetail = 1 THEN 'Y' ELSE 'N' END AS IsLot
				FROM ZTrans 
					LEFT OUTER JOIN iRecIpkey ON ZTrans.UniqTransKey = iRecIpkey.invtrec_no AND ZTrans.transType = 'Receiving' 
					LEFT OUTER JOIN issueipkey ON ZTrans.UniqTransKey = issueipkey.invtisu_no AND (ZTrans.transType = 'Issue' OR ZTrans.transType = 'Issue Return')
					LEFT OUTER JOIN iTransferipkey iTrFr ON ZTrans.UniqTransKey = iTrFr.INVTXFER_N AND ZTrans.transType = 'Transfer From'
					LEFT OUTER JOIN iTransferipkey iTrTo ON ZTrans.UniqTransKey = iTrTo.INVTXFER_N AND ZTrans.transType = 'Transfer To'
					LEFT OUTER JOIN PORECLOCIPKEY POrec ON ZTrans.UniqTransKey = PORec.LOC_UNIQ AND ZTrans.transType = 'PO Receipt'
					LEFT OUTER JOIN PORECLOCIPKEY POrej ON ZTrans.UniqTransKey = PORej.LOC_UNIQ AND ZTrans.transType = 'PO Receipt'
					INNER JOIN PARTTYPE ON ZTrans.PART_CLASS = Parttype.Part_class AND ZTrans.PART_TYPE = Parttype.PART_TYPE
				order by part_no,revision,Date Desc, nsort desc		--08/24/15 DRP/YS:  Added
			
		
		END   --- else --- if (@lcType='Consigned')
	END