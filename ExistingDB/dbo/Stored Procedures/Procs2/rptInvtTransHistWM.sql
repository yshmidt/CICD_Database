-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 12/17/14  - procedure to replace [rptInvtTransHistWM]
-- Description:	transaction log report: test for part number and date range. Excluded serial numbers for po receiving  
--- 12/18/14 this procedure should filter part source typer but still shows all the transactions
--  12/22/14 now add filters for all the transaction types
--12/23/14 YS remove records with 0 accepted qty
-- 12/23/14 YS added GL_NBR_INV for 'from' transfer and gl_nbt for 'to' transfer transactions as woPoRef
--12/23/14 YS show DMR_NO in woPoRef
--12/23/14 YS added part-class selection
--12/23/14 YS added warehouse parameter
--12/23/14 YS added left outer join with mfhd table variable in case Uniqmfgrhd was not populated in tables like invttrns
--01/12/15 DRP:  needed to change the @UniqWH parameter to be @lcUniqWh in order to work with the Cloud Parameters that already exist.  Also needed to change @userid to @userId in order to work with Cloud Manex  
--01/26/15 YS added lcUniq_key for a single part. 
--01/26/15 YS if start part number and the end part number is empty and uniq_key is empty or null then user should get all the parts in the selected criteria
-- 02/03/15 YS missing warehouse connection
--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
-- 03/12/15 YS added new MfgrMaster and InvtmpnLink tables in place of Invtmfhd table
--03/26/15 DRP found that the Consigned was not pass the custpartno and custrev to the PartStart and PartEnd values.  It was alwasy passing the internal pn and rev
--			   added conversion from purchase to stock UOM
--			   added the logic to show or not show the SN
--- 03/28/17 YS changed length of the part_no column from 25 to 35
--04/24/17 DRP: per request I have added the reject reason to the results under the Reason field so for PO Reject records they can see the reason recorded from the PO Receiving screen
-- 09/01/17 VL  Added code to filter out receiving record for in-store poitems because it already has transaction for the receipt when received manually
--03/13/19 YS typo in MfgrMater
--03/13/19 YS serialno is not saved with any tramsaction tables. Removed it for now. Have to change code later
--03/13/19 user information will come from aspnet_profile table
-- 03/14/19 YS remove purch order and dmr for now
-- 09/11/19 VL added ipkeyUnique(MTC) and qty, CAPA #1701, if the transaction records have more than one ipkey record, multiple records will show, those records share the same 'UniqTransKey'
-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
-- 12/12/19 VL Uncomment and changed the PO receiving and PO Reject part and leave the DMR part still comment
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtTransHistWM]
	@lcClass as varchar (MAX) = 'All',
	--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key
	@lcUniq_keyStart char(10)='',
	--@lcPartStart as varchar(25)='',
	--@lcPartEnd as varchar(25)='',
	@lcUniq_keyEnd char(10)='',
	@lcType as char (20) = 'Internal',				--where the user would specify Internal, Internal & In Store, In Store, Consigned
	@lcCustNo as varchar (max) = 'All',
	@lcDateStart as smalldatetime= null,
	@lcDateEnd as smalldatetime = null,
	@lcRptType as char(100) = 'All',				--Type of Transactions the user desires 'All' is default, Receipts, Issues or Transfers
	@lcShowSN as char (3) = 'No',							-- Yes or No12/22/14 show no show serial numbers --03/26/15 DRP:  added the logic to show or not show the SN, for now do not show serial numbers from po receiving and all related to po receiving transactions  
	@lcUniqWH varchar(max)='All',						--- 12/23/14 YS added parameter for user to be able to filter output by warehouse. Default to 'All' can coma separated. has to be multiselect list or All
	@userId uniqueidentifier = null

	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',
		@lcPartEnd char(35)='',@lcRevisionEnd char(8)=''
  
	-- find starting part number
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
		
	SELECT @lcDateStart=CASE WHEN @lcDateStart is null then @lcDateStart else cast(@lcDateStart as smalldatetime)  END,
			@lcDateEnd=CASE WHEN @lcDateEnd is null then @lcDateEnd else DATEADD(day,1,cast(@lcDateEnd as smalldatetime))  END
	
	-- try a different apprach
	DECLARE @Warehouse TABLE (UniqWH char(10))
	IF (@lcUniqWH<>'All' and @lcUniqWH<>' ' and @lcUniqWH IS NOT NULL)
		INSERT INTO @Warehouse (UniqWH) select id  from dbo.[fn_simpleVarcharlistToTable](@lcUniqWH,',')

	-- 12/23/14 YS added part class selection
	DECLARE @PartClass TABLE (part_class char(8))
	IF @lcClass is not null and @lcClass <>'' and @lcClass <>'All'
		INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')	
	--get list of customers for @userid with access
	if (@lcType='Consigned') 	
	BEGIN	
		DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userId ;
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
		--- 12/22/14 YS get consign transactions for Receipts only
		IF (@lcRptType='Receipts')
		BEGIN
			;with PartInfo
			as
			(
			select Uniq_key,part_class,Part_type,custpartno as Part_no,custrev as revision,[descript],part_sourc,Inventor.custno,inventor.stdcost 
				from Inventor INNER JOIN @Customer C ON Inventor.custno=C.Custno
				where part_sourc='CONSG' and 
				(custpartno+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
				and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			-- 03/13/19 YS typo in MfgrMaster
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse 
				from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
			where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			/*
			use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 
				'from' before 'to', when date is the same
			*/
			AllReceipts
			as(
			select CAST('Receiving' as varchar(25)) as transType,Ir.Uniq_key,space(10) as fromwkey,ir.w_key as towkey, 
			mfhd.partmfgr,mfhd.mfgr_pt_no,ir.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			IR.[Date],IR.Qtyrec as TransQty,IR.LotCode,IR.Expdate,IR.Reference,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,COMMREC as reason
			--- 03/13/19 YS do not show serial number for now
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,cast(' ' as char (30)) as serialno
			,Mfhd.MatlTYpe,cast(' ' as varchar(25)) as woPoRef,space(10) as uniqrecdtl,1 as nsort
			-- 09/11/19 VL added Ipkey
			,iRecIpKey.ipkeyunique AS MTC, iRecIpKey.qtyReceived AS MTCQty, IR.INVTREC_NO AS UniqTransKey
			 from Invt_rec IR left outer join mfhd on ir.uniqmfgrhd=mfhd.uniqmfgrhd
			 left outer join whloc on ir.w_key=whloc.w_key
			 -- 09/11/19 VL added Ipkey
			 LEFT OUTER JOIN iRecIpKey ON IR.INVTREC_NO = iRecIpKey.invtrec_no
			 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			 LEFT OUTER JOIN aspnet_Users ON IR.fk_userid = aspnet_Users.UserId
			 where --(@lcRptType='All' or @lcRptType='Receipts') AND
			 [date] between @lcDateStart and @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=ir.uniq_key) 
			)
			-- try with partinfo
			select 
			p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,p.custno,
				C.CustName,A.* 
				from AllReceipts a inner join partinfo P on A.uniq_key=P.Uniq_key 
				inner join Customer C on p.custno=C.Custno
					-- added filter for warehous
				where (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort
		
		END  -- IF (@lcRptType='Receipts')  for consign parts
		--- 12/22/14 YS get consign transactions for Issues only
		IF (@lcRptType='Issues')
		BEGIN
			;with PartInfo
			as
			(
			--12/23/14 YS added part_class selection
			--01/26/15 YS added single part vs part range
			select Uniq_key,part_class,Part_type,custpartno as Part_no,custrev as revision,[descript],part_sourc,Inventor.custno 
				from Inventor INNER JOIN @Customer C ON Inventor.custno=C.Custno
				where part_sourc='CONSG' and 
				--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
				(custpartno+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
				and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
				),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--03/13/19 YS typo in MfgrMaster
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
			where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			/*
			use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 
				'from' before 'to', when date is the same
			*/
			AllIssues
			as(
			 SELECT case when qtyisu<0 then 'Issue Return' else 'Issue' end as transType, ISS.Uniq_key,Iss.W_KEY as fromwkey,space(10) as towkey,
				mfhd.partmfgr,mfhd.mfgr_pt_no,iss.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
				Iss.[Date],-QTYISU as TransQty,Iss.LOTCODE,Iss.EXPDATE,Iss.REFERENCE,
				-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				--Iss.SAVEINIT,
				aspnet_Users.UserName,
				Iss.TRANSREF,ISSUEDTO as reason
				--03/13/19 YS do not show serial for now
				--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
				,cast(' ' as char (30)) as serialno
				,Mfhd.MatlTYpe,cast(iss.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,5 as nsort			
				-- 09/11/19 VL added Ipkey
				,issueipkey.ipkeyunique AS MTC, issueipkey.qtyissued AS MTCQty, iss.INVTISU_NO AS UniqTransKey	
				FROM INVT_ISU iss left outer join mfhd on iss.uniqmfgrhd=mfhd.uniqmfgrhd
				LEFT OUTER JOIN WhLoc on iss.w_key=whloc.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN issueipkey ON Iss.INVTISU_NO = issueipkey.invtisu_no
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON Iss.fk_userid = aspnet_Users.UserId
				WHERE iss.[date] BETWEEN @lcDateStart AND @lcDateEnd  and exists (select 1 from partinfo where partinfo.uniq_key=iss.uniq_key)
			)
			select p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,p.custno,
				C.CustName,A.* 
				from AllIssues a inner join partinfo P on A.uniq_key=P.Uniq_key 
				inner join Customer C on p.custno=C.Custno
					-- added filter for warehous
			WHERE (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort

		END -- IF (@lcRptType='Issues') for consigned parts
		--- 12/22/14 YS get consign transactions for Transfers only
		IF (@lcRptType='Transfers')
		BEGIN
			;with PartInfo
			as
			(
			--12/23/14 YS added part_class selection
			--1/26/15 YS check if single part or a range of parts
			select Uniq_key,part_class,Part_type,custpartno as Part_no,custrev as revision,[descript],part_sourc,Inventor.custno,inventor.stdcost  
				from Inventor INNER JOIN @Customer C ON Inventor.custno=C.Custno
				where part_sourc='CONSG' and
				--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
				(custpartno+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd) 
				and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--03/13/19 YS typo in MfgrMaster
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
			where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			/*
			 use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 
			 'from' before 'to', when date is the same
			*/
			AllTransfers
			as(
			SELECT 'Transfer From' transType,tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,fromwh.Uniqwh,fromwh.whno,fromwh.location,fromwh.warehouse,fromwh.instore,
			[date],-QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,			
			TRANSREF,REASON
			--03/13/19 YS do not show serial for now
			,cast(' ' as char (30)) as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast(tra.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,3 as nsort		
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.fromIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey	
				FROM INVTTRNS tra left outer join mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc fromwh on tra.fromwkey=fromwh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId

			WHERE tra.[date] BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			UNION ALL
			SELECT 'Transfer To',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,towh.Uniqwh,towh.whno,towh.location,towh.warehouse,towh.instore,
			[date],QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,REASON
			--03/13/19 YS do not show serial for now
			,cast(' ' as char (30)) as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast(tra.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl	,4 as nsort		
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.toIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey				
				FROM INVTTRNS tra left outer join mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc towh on tra.towkey=towh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId

			WHERE 	tra.[date] BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			)
			select 
			p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,p.custno,
				C.CustName,A.* 
				from AllTransfers a inner join partinfo P on A.uniq_key=P.Uniq_key 
				inner join Customer C on p.custno=C.Custno
					-- added filter for warehous
			WHERE (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort
		END --- IF (@lcRptType='Transfers') for consign parts
		--- 12/22/14 YS get consign transactions for all
		IF (@lcRptType='All')
		BEGIN
			;with PartInfo
			as
			(
			--12/23/14 YS added part_class selection
			select Uniq_key,part_class,Part_type,custpartno as Part_no,custrev as revision,[descript],part_sourc,Inventor.custno ,Inventor.STDCOST
					from Inventor INNER JOIN @Customer C ON Inventor.custno=C.Custno
					where part_sourc='CONSG' and 
					--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
					(custpartno+custrev BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
					and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--03/13/19 YS typo in MfgrMaster
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
				where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			/*
			 use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 
			 'from' before 'to', when date is the same
			*/
			AllTransactions
			as(
			select CAST('Receiving' as varchar(25)) as transType,Ir.Uniq_key,space(10) as fromwkey,ir.w_key as towkey, 
			mfhd.partmfgr,mfhd.mfgr_pt_no,ir.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			IR.[Date],IR.Qtyrec as TransQty,IR.LotCode,IR.Expdate,IR.Reference,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,COMMREC as reason
			--03/13/19 YS do not show serial for now
			,cast(' ' as char (30)) as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast(' ' as varchar(25)) as woPoRef,space(10) as uniqrecdtl,1 as nsort
			-- 09/11/19 VL added Ipkey
			,iRecIpKey.ipkeyunique AS MTC, iRecIpKey.qtyReceived AS MTCQty, IR.INVTREC_NO AS UniqTransKey
			 from Invt_rec IR left outer join mfhd on ir.uniqmfgrhd=mfhd.uniqmfgrhd
			 left outer join whloc on ir.w_key=whloc.w_key
			 -- 09/11/19 VL added Ipkey
			 LEFT OUTER JOIN iRecIpKey ON IR.INVTREC_NO = iRecIpKey.invtrec_no
			 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			 LEFT OUTER JOIN aspnet_Users ON IR.fk_userid = aspnet_Users.UserId
			 where --(@lcRptType='All' or @lcRptType='Receipts') AND
			 [date] between @lcDateStart and @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=ir.uniq_key) 
			 UNION ALL
			 SELECT case when qtyisu<0 then 'Issue Return' else 'Issue' end as transType, ISS.Uniq_key,Iss.W_KEY as fromwkey,space(10) as towkey,
			mfhd.partmfgr,mfhd.mfgr_pt_no,iss.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			 Iss.[Date],-QTYISU as TransQty,Iss.LOTCODE,Iss.EXPDATE,Iss.REFERENCE,
				-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				--Iss.SAVEINIT,
				aspnet_Users.UserName,
				Iss.TRANSREF,ISSUEDTO as reason
				--03/13/19 YS do not show serial for now
			,cast(' ' as char (30)) as serialno
				--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
				,Mfhd.MatlTYpe,cast(iss.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,5 as nsort	
				-- 09/11/19 VL added Ipkey
				,issueipkey.ipkeyunique AS MTC, issueipkey.qtyissued AS MTCQty, iss.INVTISU_NO AS UniqTransKey									
				FROM INVT_ISU iss left outer join Mfhd on iss.uniqmfgrhd=mfhd.uniqmfgrhd
				LEFT OUTER JOIN WhLoc on iss.w_key=whloc.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN issueipkey ON Iss.INVTISU_NO = issueipkey.invtisu_no
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON Iss.fk_userid = aspnet_Users.UserId

				WHERE  --(@lcRptType='All' or @lcRptType='Issues') AND
				iss.[date] BETWEEN @lcDateStart AND @lcDateEnd  and exists (select 1 from partinfo where partinfo.uniq_key=iss.uniq_key)
			UNION ALL
			SELECT 'Transfer From',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,fromwh.Uniqwh,fromwh.whno,fromwh.location,fromwh.warehouse,fromwh.instore,
			[date],-QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,REASON
			--03/13/19 YS do not show serial for now
			,cast(' ' as char (30)) as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast(tra.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,3 as nsort	
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.fromIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey							
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc fromwh on tra.fromwkey=fromwh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId

			WHERE --(@lcRptType='All' or @lcRptType='Transfers') AND
			tra.[date] BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			UNION ALL
			SELECT 'Transfer To',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,towh.Uniqwh,towh.whno,towh.location,towh.warehouse,towh.instore,
			[date],QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,REASON
			--03/13/19 YS do not show serial for now
			,cast(' ' as char (30)) as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast(tra.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl	,4 as nsort		
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.toIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey				
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc towh on tra.towkey=towh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId

			WHERE --(@lcRptType='All' or @lcRptType='Transfers') AND
			tra.[date] BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			)
			-- try with partinfo
			
			select 
				p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,p.custno,
				C.CustName,A.* 
				from AllTransactions a inner join partinfo P on A.uniq_key=P.Uniq_key 
				inner join Customer C on p.custno=C.Custno
					-- added filter for warehous
			WHERE (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort
		END  --- (IF @lcRptType='All')

	END --- if (@lcType='Consigned')
	ELSE   -- @lcType='Consigned')
	BEGIN
	-- internal parts
		--12/22/14 YS added IF for different trnasaction types
		IF (@lcRptType='Receipts')  -- for internal
		BEGIN	
			;with PartInfo
			as
			(
			--12/23/14 YS added part-class selection
			
			select Uniq_key,part_class,Part_type,Part_no,revision,[descript],part_sourc ,Inventor.STDCOST
				from Inventor where (part_sourc='MAKE' or part_sourc='BUY') and 
				--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
				(part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
				and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
			
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--03/13/19 YS typo in MfgrMaster
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			-- try limit based on @lcTYpe did not help, will remove from simplicity
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
				where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
		
			
			),
			/*
			 use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 
			 'from' before 'to', when date is the same
			*/
			AllReceipts
			as(
			--03/13/19 YS use aspnet_profile table to get user's initials
				select CAST('Receiving' as varchar(25)) as transType,Ir.Uniq_key,space(10) as fromwkey,ir.w_key as towkey, 
					mfhd.partmfgr,mfhd.mfgr_pt_no,ir.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
					IR.[Date],IR.Qtyrec as TransQty,IR.LotCode,IR.Expdate,IR.Reference,
					-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
					--SAVEINIT,
					aspnet_Users.UserName,
					TRANSREF,COMMREC as reason
					--03/13/19 YS do not show serial for now
			,cast(' ' as char (30)) as serialno
					--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
					,Mfhd.MatlTYpe,cast(' ' as varchar(25)) as woPoRef,space(10) as uniqrecdtl,1 as nsort
				-- 09/11/19 VL added Ipkey
				,iRecIpKey.ipkeyunique AS MTC, iRecIpKey.qtyReceived AS MTCQty, IR.INVTREC_NO AS UniqTransKey
				from Invt_rec IR left outer join Mfhd on ir.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc on ir.w_key=whloc.w_key
				 -- 09/11/19 VL added Ipkey
				 LEFT OUTER JOIN iRecIpKey ON IR.INVTREC_NO = iRecIpKey.invtrec_no
				-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON IR.fk_userid = aspnet_Users.UserId
				 where date between @lcDateStart and @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=ir.uniq_key) 
				UNION ALL
				-- 12/12/19 VL tried to add the PO receiving and reject part back
				--- 03/13/19 YS receiving changed. Remove for now
				select 'PO Receipt',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
				pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,pl.location,w.warehouse,case when pi.poittype='In Store' then 1 else 0 END,
				pr.recvDate as [date]
				--,isnull(lt.lotqty,pl.accptqty) as transqty	--03/26/15 DRP added conversion from purchase to stock UOM
				,case when pi.Pur_uofm=pi.U_of_meas THEN isnull(lt.lotqty,pl.accptqty) ELSE dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,isnull(lt.lotqty,pl.accptqty)) END as transqty,
				isnull(lt.lotcode,space(15)) as lotcode,
				EXPDATE,isnull(REFERENCE,space(12)) as reference,
				--03/13/19 user information will come from aspnet_profile table
				-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				--isnull(a.Initials,'  ') as SAVEINIT
				aspnet_Users.UserName,
				'' as TRANSREF,'' as reason,
				'' as serialno	,Mfhd.MatlTYpe,pi.ponum as woPoRef,pr.uniqrecdtl,1 as nsort	
				-- 12/12/19 VL added Ipkey
				,PORECLOCIPKEY.ipkeyunique AS MTC, PORECLOCIPKEY.accptQty AS MTCQty, PORECLOCIPKEY.LOC_UNIQ AS UniqTransKey						
				from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
				inner join porecloc PL on pr.uniqrecdtl=pl.fk_uniqrecdtl
				 -- 12/12/19 VL added Ipkey
				LEFT OUTER JOIN PORECLOCIPKEY ON PL.Loc_Uniq = PORECLOCIPKEY.Loc_uniq
				left outer join warehous w on pl.uniqwh=w.uniqwh
				left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
				left outer join poreclot lt on pl.loc_uniq=lt.loc_uniq 
				-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				LEFT OUTER JOIN aspnet_Users ON pr.Edituserid = aspnet_Users.UserId
				--left outer join aspnet_profile a on pr.Edituserid=a.UserId
				where pr.recvDate BETWEEN @lcDateStart AND @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) 
				--12/23/14 YS remove records with 0 accepted qty
				AND pl.accptqty<>0.00
				-- 09/01/17 VL  Added code to filter out receiving record for in-store poitems because it already has transaction for the receipt when received manually
				AND pi.PoitType <> 'In Store'
				AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))
				UNION ALL
				select 'PO Reject',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
					pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,'PO:'+PI.PONUM as location,'MRB',CASE WHEN pi.poittype = 'In Store' then 1 else 0 END,
					pr.recvDate as [date]
					--,isnull(lt.rejlotqty,pl.rejqty) as transqty	--03/26/15 DRP added conversion from purchase to stock UOM
					,case when pi.Pur_uofm=pi.U_of_meas THEN isnull(lt.rejlotqty,pl.rejqty) ELSE dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,isnull(lt.rejlotqty,pl.rejqty)) END as transqty,
					isnull(lt.lotcode,space(15)) as lotcode,
					EXPDATE,isnull(REFERENCE,space(12)) as reference,
					--03/13/19 user information will come from aspnet_profile table
					-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
					--isnull(a.Initials,'  ') as SAVEINIT
					aspnet_Users.UserName,
					'' as TRANSREF,'' as reason,
					'' as serialno,mfhd.matlType,pi.ponum as woPoRef,pr.uniqrecdtl,2 as nsort	
				-- 12/12/19 VL added Ipkey
				,PORECLOCIPKEY.ipkeyunique AS MTC, PORECLOCIPKEY.accptQty AS MTCQty, PORECLOCIPKEY.LOC_UNIQ AS UniqTransKey						
				from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
				inner join porecloc PL on pr.uniqrecdtl=pl.fk_uniqrecdtl
				OUTER APPLY (SELECT warehouse,uniqwh,whno from Warehous where warehouse='MRB') w
				 -- 12/12/19 VL added Ipkey
				LEFT OUTER JOIN PORECLOCIPKEY ON PL.Loc_Uniq = PORECLOCIPKEY.Loc_uniq
				left outer join poreclot lt on pl.loc_uniq=lt.loc_uniq 
				left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
				-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				LEFT OUTER JOIN aspnet_Users ON pr.Edituserid = aspnet_Users.UserId
				--left outer join aspnet_Profile a on pr.Edituserid=a.UserId
				where pr.recvDate BETWEEN @lcDateStart AND @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) and pl.rejqty<>0.00 
				AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))
				-- 12/12/19 VL End
				--UNION ALL
				--	select 'DMR Return',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
				--	pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,'PO:'+PI.PONUM as location,'MRB',CASE WHEN pi.poittype = 'In Store' then 1 else 0 END,
				--	MRB.RMA_DATE as [date]
				--	--,	-MRB.RET_QTY as transqty	--03/26/15 DRP added conversion from purchase to stock UOM
				--	,case when pi.Pur_uofm=pi.U_of_meas THEN - MRB.RET_QTY ELSE - dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,MRB.RET_QTY) END as transqty,
				--	space(15) as lotcode,
				--	NULL as EXPDATE,space(12) as reference,
				--	MRB.Initial as SAVEINIT,'' as TRANSREF,'' as reason,
				--	--12/23/14 YS show DMR_NO in woPoRef
				--	'' as serialno,mfhd.matlType,'DMR: '+mrb.dmr_no as woPoRef,pr.uniqrecdtl	,5 as nsort			
				--from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
				--inner join PORECMRB MRB on pr.uniqrecdtl=mrb.fk_uniqrecdtl
				--OUTER APPLY (SELECT warehouse,uniqwh,whno from Warehous where warehouse='MRB') w
				--left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
				--where MRB.RMA_DATE BETWEEN @lcDateStart AND @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) 
				----AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))

			)
			select 
			--p.stdcost,p.stdcost*a.TransQty as transvalue,
			p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,' ' as custno, ' ' as custname,
				A.* 
				from AllReceipts a inner join partinfo P on A.uniq_key=P.Uniq_key
				where ((@lcType='Internal & In Store') OR (@lcType='In Store' and a.instore=1) OR (@lcType='Internal' and a.instore=0))
					-- added filter for warehous
			and (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort
		END -- (@lcRptType='Receipts') -- internal parts
		IF (@lcRptType='Issues')
		BEGIN
		;with PartInfo
			as
			(
			-- added part_class selection
			--01/26/15 YS check for single part or a range of parts
			select Uniq_key,part_class,Part_type,Part_no,revision,[descript],part_sourc ,Inventor.STDCOST
				from Inventor where (part_sourc='MAKE' or part_sourc='BUY') and 
				--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
				(part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
				--((@lcUniq_key is not null and Inventor.Uniq_key=@lcuniq_key) OR
				--(@lcUniq_key is null and part_no between @lcPartStart and @lcPartEnd))
				and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
			--select Uniq_key 
			--	from Inventor where (part_sourc='MAKE' or part_sourc='BUY') and part_no between @lcPartStart and @lcPartEnd
		
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--select Uniq_key,uniqmfgrhd, partmfgr,mfgr_pt_no,matltype from Invtmfhd where exists (select 1 from partinfo where partinfo.uniq_key=invtmfhd.uniq_key)
			--03/13/19 YS typo in MfgrMaster
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			-- try limit based on @lcTYpe did not help, will remove from simplicity
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
				where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			AllIssues
			as(	
			 SELECT case when qtyisu<0 then 'Issue Return' else 'Issue' end as transType, ISS.Uniq_key,Iss.W_KEY as fromwkey,space(10) as towkey,
			 mfhd.partmfgr,mfhd.mfgr_pt_no,iss.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			 Iss.[Date],-QTYISU as TransQty,Iss.LOTCODE,Iss.EXPDATE,Iss.REFERENCE,
				-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				--Iss.SAVEINIT,
				aspnet_Users.UserName,
					Iss.TRANSREF,ISSUEDTO as reason
				--03/13/19 YS remove serialno for now
				, cast(' ' as char (30))  as serialno
				--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
				,Mfhd.MatlTYpe,cast(iss.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,5 as nsort	
				-- 09/11/19 VL added Ipkey
				,issueipkey.ipkeyunique AS MTC, issueipkey.qtyissued AS MTCQty, iss.INVTISU_NO AS UniqTransKey							
				FROM INVT_ISU iss left outer join Mfhd on iss.uniqmfgrhd=mfhd.uniqmfgrhd
				LEFT OUTER JOIN WhLoc on iss.w_key=whloc.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN issueipkey ON Iss.INVTISU_NO = issueipkey.invtisu_no
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON Iss.fk_userid = aspnet_Users.UserId
				WHERE iss.date BETWEEN @lcDateStart AND @lcDateEnd  and exists (select 1 from partinfo where partinfo.uniq_key=iss.uniq_key)
			)
			select 
			--p.stdcost,p.stdcost*a.TransQty as transvalue,
			p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,' ' as custno, ' ' as custname,
				A.* 
				from AllIssues a inner join partinfo P on A.uniq_key=P.Uniq_key
				where ((@lcType='Internal & In Store') OR (@lcType='In Store' and a.instore=1) OR (@lcType='Internal' and a.instore=0))
					-- added filter for warehous
			and (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort
		END -- (@lcRptType='Issues') -- internal parts
		IF (@lcRptType='Transfers')
		BEGIN
		;with PartInfo
			as
			(
			--12/23/14 YS added part_class selection
			--01/26/15 YS check for a single part or a range of parts
			select Uniq_key,part_class,Part_type,Part_no,revision,[descript],part_sourc ,Inventor.STDCOST
				from Inventor where (part_sourc='MAKE' or part_sourc='BUY') and
				--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
				(part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
				--and ((@lcUniq_key is not null and Inventor.Uniq_key=@lcuniq_key) OR
				--(@lcUniq_key is null and part_no between @lcPartStart and @lcPartEnd))
				and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
			--select Uniq_key 
			--	from Inventor where (part_sourc='MAKE' or part_sourc='BUY') and part_no between @lcPartStart and @lcPartEnd
		
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--select Uniq_key,uniqmfgrhd, partmfgr,mfgr_pt_no,matltype from Invtmfhd where exists (select 1 from partinfo where partinfo.uniq_key=invtmfhd.uniq_key)
			--03/13/19 YS typo in MfgrMater
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			-- try limit based on @lcTYpe did not help, will remove from simplicity
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
				where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			AllTransfers
			as(
			SELECT 'Transfer From' transType,tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,fromwh.Uniqwh,fromwh.whno,fromwh.location,fromwh.warehouse,fromwh.instore,
			[date],-QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			-- 12/23/14 YS added GL_NBR_INV for 'from' transfer and gl_nbt for 'to' transfer transactions as woPoRef
			TRANSREF,REASON
			--03/13/19 YS remove serialno for now
				, cast(' ' as char (30))  as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast('G/L:' +tra.GL_NBR_INV as varchar(25)) as woPoRef,space(10) as uniqrecdtl,3 as nsort	
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.fromIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc fromwh on tra.fromwkey=fromwh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE tra.date BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			UNION ALL
			SELECT 'Transfer To',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,towh.Uniqwh,towh.whno,towh.location,towh.warehouse,towh.instore,
			[date],QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			-- 12/23/14 YS added GL_NBR_INV for 'from' transfer and gl_nbt for 'to' transfer transactions as woPoRef
			TRANSREF,REASON
			--03/13/19 YS remove serialno for now
				, cast(' ' as char (30))  as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast('G/L:' + tra.gl_nbr as varchar(25)) as woPoRef,space(10) as uniqrecdtl	,4 as nsort	
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.toIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey					
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc towh on tra.towkey=towh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE tra.date BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			)
			select 
			--p.stdcost,p.stdcost*a.TransQty as transvalue,
			p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,' ' as custno, ' ' as custname,
				A.* 
				from AllTransfers a inner join partinfo P on A.uniq_key=P.Uniq_key
				where ((@lcType='Internal & In Store') OR (@lcType='In Store' and a.instore=1) OR (@lcType='Internal' and a.instore=0))
					-- added filter for warehous
			and (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort
		END -- (@lcRptType='Transfers') -- internal
		IF (@lcRptType='All')
		BEGIN
			;with PartInfo
			as
			(
			--12/23/14 YS added part-class selection
			--01/26/15 YS check for a single part or a range of parts
			select Uniq_key,part_class,Part_type,Part_no,revision,[descript],part_sourc ,Inventor.STDCOST
				from Inventor where (part_sourc='MAKE' or part_sourc='BUY') and 
				--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key
				(part_no+revision BETWEEN @lcPartStart +@lcrevisionstart and @lcPartEnd+@lcRevisionEnd)
				--((@lcUniq_key is not null and Inventor.Uniq_key=@lcuniq_key) OR
				--(@lcUniq_key is null and part_no between @lcPartStart and @lcPartEnd))
				and (@lcClass = 'All' OR EXISTS (SELECT 1 FROM @PartClass PC where PC.Part_class=Inventor.Part_class))
			--select Uniq_key 
			--	from Inventor where (part_sourc='MAKE' or part_sourc='BUY') and part_no between @lcPartStart and @lcPartEnd
		
			),
			Mfhd
			as
			(
			--03/12/15 YS replace invtmfhd table with 2 new tables
			--select Uniq_key,uniqmfgrhd, partmfgr,mfgr_pt_no,matltype from Invtmfhd where exists (select 1 from partinfo where partinfo.uniq_key=invtmfhd.uniq_key)
			--03/13/19 YS typo in MfgrMater
			select L.Uniq_key,L.uniqmfgrhd, M.partmfgr,M.mfgr_pt_no,M.matltype 
				from Invtmpnlink L INNER JOIN MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
			),
			WhLoc
			as
			(
			-- try limit based on @lcTYpe did not help, will remove from simplicity
			select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
				where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key)
		
			--select Uniq_key,uniqmfgrhd, w_key,w.whno,w.uniqwh,location,instore,w.warehouse from Invtmfgr L INNER JOIN Warehous W on l.uniqwh=w.uniqwh 
			--	where exists (select 1 from partinfo where partinfo.uniq_key=l.uniq_key) AND
			--	((@lcType='Internal & In Store') OR (@lcType='In Store' and instore=1) OR (@lcType='Internal' and instore=0))
		
			),
			-- use nsort to position transactions with types like receipts and in house movememnts before issue or DMR, 'from' before 'to', when date is the same
			AllTransactions
			as(
			select CAST('Receiving' as varchar(25)) as transType,Ir.Uniq_key,space(10) as fromwkey,ir.w_key as towkey, 
			mfhd.partmfgr,mfhd.mfgr_pt_no,ir.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			IR.[Date],IR.Qtyrec as TransQty,IR.LotCode,IR.Expdate,IR.Reference,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			TRANSREF,COMMREC as reason
			--03/13/19 YS remove serialno for now
				, cast(' ' as char (30))  as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast(' ' as varchar(25)) as woPoRef,space(10) as uniqrecdtl,1 as nsort
			-- 09/11/19 VL added Ipkey
			,iRecIpKey.ipkeyunique AS MTC, iRecIpKey.qtyReceived AS MTCQty, IR.INVTREC_NO AS UniqTransKey
			 from Invt_rec IR left outer join Mfhd on ir.uniqmfgrhd=mfhd.uniqmfgrhd
			 left outer join whloc on ir.w_key=whloc.w_key
			 -- 09/11/19 VL added Ipkey
			 LEFT OUTER JOIN iRecIpKey ON IR.INVTREC_NO = iRecIpKey.invtrec_no
			 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			 LEFT OUTER JOIN aspnet_Users ON IR.fk_userid = aspnet_Users.UserId
			 where date between @lcDateStart and @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=ir.uniq_key) 
			 UNION ALL
			 SELECT case when qtyisu<0 then 'Issue Return' else 'Issue' end as transType, ISS.Uniq_key,Iss.W_KEY as fromwkey,space(10) as towkey,
			mfhd.partmfgr,mfhd.mfgr_pt_no,iss.uniqmfgrhd,whloc.Uniqwh,whloc.whno,whloc.location,whloc.warehouse,whloc.instore,
			 Iss.[Date],-QTYISU as TransQty,Iss.LOTCODE,Iss.EXPDATE,Iss.REFERENCE,
				-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				--Iss.SAVEINIT,
				aspnet_Users.UserName,			 
				Iss.TRANSREF,ISSUEDTO as reason
				--03/13/19 YS remove serialno for now
				, cast(' ' as char (30))  as serialno
				--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
				,Mfhd.MatlTYpe,cast(iss.wono as varchar(25)) as woPoRef,space(10) as uniqrecdtl,5 as nsort		
				-- 09/11/19 VL added Ipkey
				,issueipkey.ipkeyunique AS MTC, issueipkey.qtyissued AS MTCQty, iss.INVTISU_NO AS UniqTransKey									
				FROM INVT_ISU iss left outer join Mfhd on iss.uniqmfgrhd=mfhd.uniqmfgrhd
				LEFT OUTER JOIN WhLoc on iss.w_key=whloc.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN issueipkey ON Iss.INVTISU_NO = issueipkey.invtisu_no
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON Iss.fk_userid = aspnet_Users.UserId
				WHERE iss.date BETWEEN @lcDateStart AND @lcDateEnd  and exists (select 1 from partinfo where partinfo.uniq_key=iss.uniq_key)
			UNION ALL
			SELECT 'Transfer From',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,fromwh.Uniqwh,fromwh.whno,fromwh.location,fromwh.warehouse,fromwh.instore,
			[date],-QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			-- 12/23/14 YS added GL_NBR_INV for 'from' transfer and gl_nbt for 'to' transfer transactions as woPoRef
			TRANSREF,REASON
			--03/13/19 YS remove serialno for now
				, cast(' ' as char (30))  as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast('G/L:' +tra.GL_NBR_INV as varchar(25)) as woPoRef,space(10) as uniqrecdtl,3 as nsort
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.fromIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey							
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc fromwh on tra.fromwkey=fromwh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE tra.date BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			UNION ALL
			SELECT 'Transfer To',tra.UNIQ_KEY, FROMWKEY ,TOWKEY,
			mfhd.partmfgr,mfhd.mfgr_pt_no,tra.uniqmfgrhd,towh.Uniqwh,towh.whno,towh.location,towh.warehouse,towh.instore,
			[date],QTYXFER TransQty,LOTCODE,EXPDATE,REFERENCE,
			-- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--SAVEINIT,
			aspnet_Users.UserName,
			-- 12/23/14 YS added GL_NBR_INV for 'from' transfer and gl_nbt for 'to' transfer transactions as woPoRef
			TRANSREF,REASON
			--03/13/19 YS remove serialno for now
				, cast(' ' as char (30))  as serialno
			--,case when @lcShowSN = 'Yes' then serialno else cast(' ' as char (30)) end as serialno	--03/26/15 DRP:  changed from just SerialNo
			,Mfhd.MatlTYpe,cast('G/L:' +tra.GL_NBR as varchar(25)) as woPoRef,space(10) as uniqrecdtl	,4 as nsort		
			-- 09/11/19 VL added Ipkey
			,iTransferipkey.toIpkeyunique AS MTC, iTransferipkey.qtyTransfer AS MTCQty, tra.INVTXFER_N AS UniqTransKey
				FROM INVTTRNS tra left outer join Mfhd on tra.uniqmfgrhd=mfhd.uniqmfgrhd
				left outer join whloc towh on tra.towkey=towh.w_key
				-- 09/11/19 VL added Ipkey
				LEFT OUTER JOIN iTransferipkey ON tra.INVTXFER_N = iTransferipkey.INVTXFER_N
				 -- 09/26/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				 LEFT OUTER JOIN aspnet_Users ON tra.fk_userid = aspnet_Users.UserId
			WHERE tra.date BETWEEN @lcDateStart AND @lcDateEnd 	and exists (select 1 from partinfo where partinfo.uniq_key=tra.uniq_key) 
			-- 12/12/19 VL tried to add the PO receiving and reject part back
			---03/14/19 YS remove po rece and dmr part for now untill fixed
			UNION ALL
			-- added limit based on @lcType
			select 'PO Receipt',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
			pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,pl.location,w.warehouse,case when pi.poittype='In Store' then 1 else 0 END,
			pr.recvDate as [date]
			--,	isnull(lt.lotqty,pl.accptqty) as transqty,	--03/26/15 DRP added conversion from purchase to stock UOM
			,case when pi.Pur_uofm=pi.U_of_meas THEN isnull(lt.lotqty,pl.accptqty) ELSE dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,isnull(lt.lotqty,pl.accptqty)) END as transqty,
			isnull(lt.lotcode,space(15)) as lotcode,
			EXPDATE,isnull(REFERENCE,space(12)) as reference,
			--- 03/13/19 YS use aspnet_profile for user info
			-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--isnull(a.Initials,'  ') as SAVEINIT
			aspnet_Users.UserName,
			'' as TRANSREF,'' as reason,
			'' as serialno	,Mfhd.MatlTYpe,pi.ponum as woPoRef,pr.uniqrecdtl,1 as nsort		
				-- 12/12/19 VL added Ipkey
				,PORECLOCIPKEY.ipkeyunique AS MTC, PORECLOCIPKEY.accptQty AS MTCQty, PORECLOCIPKEY.LOC_UNIQ AS UniqTransKey					
				from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
				inner join porecloc PL on pr.uniqrecdtl=pl.fk_uniqrecdtl
				 -- 12/12/19 VL added Ipkey
				LEFT OUTER JOIN PORECLOCIPKEY ON PL.Loc_Uniq = PORECLOCIPKEY.Loc_uniq
				left outer join Warehous w on pl.uniqwh=w.uniqwh
				left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
				left outer join poreclot lt on pl.loc_uniq=lt.loc_uniq 
				-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				LEFT OUTER JOIN aspnet_Users ON pr.Edituserid = aspnet_Users.UserId
				--left outer join aspnet_Profile a on pr.Edituserid=a.userid
				where pr.recvDate BETWEEN @lcDateStart AND @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) 
				--12/23/14 YS remove records with 0 accepted qty
				AND pl.accptqty<>0.00
				-- 09/01/17 VL  Added code to filter out receiving record for in-store poitems because it already has transaction for the receipt when received manually
				AND pi.PoitType <> 'In Store'
				AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))
			UNION ALL
			select 'PO Reject',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
			pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,'PO:'+PI.PONUM as location,'MRB',CASE WHEN pi.poittype = 'In Store' then 1 else 0 END,
			pr.recvDate as [date]
			--,	isnull(lt.rejlotqty,pl.rejqty) as transqty,	--03/26/15 DRP added conversion from purchase to stock UOM
			,case when pi.Pur_uofm=pi.U_of_meas THEN isnull(lt.rejlotqty,pl.rejqty) ELSE dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,isnull(lt.rejlotqty,pl.rejqty)) END as transqty,
			isnull(lt.lotcode,space(15)) as lotcode,
			EXPDATE,isnull(REFERENCE,space(12)) as reference,
			--03/13/19 use aspnet_profile for user info
			--RECINIT as SAVEINIT,'' as TRANSREF
			-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
			--isnull(a.Initials,'  ') as SAVEINIT
			aspnet_Users.UserName,
			'' as TRANSREF,
----check			--pr.rejreason as reason,		--04/24/17 DRP:  replaced <<,'' as reason,>>
			'' as reason,
			'' as serialno,mfhd.matlType,pi.ponum as woPoRef,pr.uniqrecdtl,2 as nsort	
				-- 12/12/19 VL added Ipkey
				,PORECLOCIPKEY.ipkeyunique AS MTC, PORECLOCIPKEY.accptQty AS MTCQty, PORECLOCIPKEY.LOC_UNIQ AS UniqTransKey								
				from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
				inner join porecloc PL on pr.uniqrecdtl=pl.fk_uniqrecdtl
				OUTER APPLY (SELECT warehouse,uniqwh,whno from Warehous where warehouse='MRB') w
				 -- 12/12/19 VL added Ipkey
				LEFT OUTER JOIN PORECLOCIPKEY ON PL.Loc_Uniq = PORECLOCIPKEY.Loc_uniq
				left outer join poreclot lt on pl.loc_uniq=lt.loc_uniq 
				left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
				-- 12/12/19 VL changed not to use saveinit field anymore, link to aspnet_users to get username by fk_userid
				LEFT OUTER JOIN aspnet_Users ON pr.Edituserid = aspnet_Users.UserId
				--left outer join aspnet_Profile a on pr.Edituserid=a.userid
				where pr.recvDate BETWEEN @lcDateStart AND @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) and pl.rejqty<>0.00 
				--AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))
			-- 12/12/19 VL End}
			--UNION ALL
			--select 'DMR Return',PI.Uniq_key, space(10) as fromwkey,space(10) as towkey,
			--pr.partmfgr,pr.mfgr_pt_no,pr.uniqmfgrhd,w.Uniqwh,w.whno,'PO:'+PI.PONUM as location,'MRB',CASE WHEN pi.poittype = 'In Store' then 1 else 0 END,
			--MRB.RMA_DATE as [date]
			----,	-MRB.RET_QTY as transqty,	--03/26/15 DRP added conversion from purchase to stock UOM
			--,case when pi.Pur_uofm=pi.U_of_meas THEN - MRB.RET_QTY ELSE - dbo.fn_ConverQtyUOM(pi.Pur_uofm, pi.U_of_meas,MRB.RET_QTY) END as transqty,
			--space(15) as lotcode,
			--NULL as EXPDATE,space(12) as reference,
			--MRB.Initial as SAVEINIT,'' as TRANSREF,'' as reason,
			----12/23/14 YS show DMR_NO in woPoRef
			--'' as serialno,mfhd.matlType,'DMR: '+mrb.dmr_no as woPoRef,pr.uniqrecdtl	,5 as nsort			
			--	from porecdtl PR inner join poitems pi on pr.uniqlnno=pi.uniqlnno
			--	inner join PORECMRB MRB on pr.uniqrecdtl=mrb.fk_uniqrecdtl
			--	OUTER APPLY (SELECT warehouse,uniqwh,whno from Warehous where warehouse='MRB') w
			--	left outer join mfhd on pr.uniqmfgrhd=mfhd.uniqmfgrhd and pr.partmfgr=mfhd.partmfgr and pr.mfgr_pt_no=mfhd.mfgr_pt_no
			--	where MRB.RMA_DATE BETWEEN @lcDateStart AND @lcDateEnd and exists (select 1 from partinfo where partinfo.uniq_key=pi.uniq_key) 
			--	--AND ((@lcType='Internal & In Store') OR (@lcType='In Store' and pi.poittype='In Store') OR (@lcType='Internal' and pi.poittype='Invt Part'))

			)
			-- using inventor table took too long

			--select I.Part_no,I.Revision,I.part_class,I.Part_type,I.Descript,I.Part_sourc,I.custno, ' ' as custname,
			--	A.* 
			--	from AllTransactions a inner join partinfo P on A.uniq_key=P.Uniq_key
			--	INNER JOIN Inventor I ON P.Uniq_key=I.Uniq_key 
			--	where a.instore=case when @lcType='In Store' THEN 1
			--						WHEN @lcType='Internal & In Store' THEN a.instore ELSE 0 END
			--	order by part_no,revision,date,nsort


			
			select 
			--p.stdcost,p.stdcost*a.TransQty as transvalue,
			p.Part_no,p.Revision,p.part_class,p.Part_type,p.Descript,p.Part_sourc,' ' as custno, ' ' as custname,
				A.* 
				from AllTransactions a inner join partinfo P on A.uniq_key=P.Uniq_key
				--where a.instore=case when @lcType='In Store' THEN 1
				--					WHEN @lcType='Internal & In Store' THEN a.instore ELSE 0 END
				-- using 1 = case did not make any faster
				--where 1=case when @lcType='In Store' and a.instore=1 THEN 1
				--				WHEN @lcType='Internal & In Store' THEN 1 
				--				WHEN @lcType='Internal' and a.instore=0 then 1 ELSE 0 END
				--using boolean logic avoiding case
				where ((@lcType='Internal & In Store') OR (@lcType='In Store' and a.instore=1) OR (@lcType='Internal' and a.instore=0))
				-- added filter for warehous
			and (@lcUniqWH='All' OR exists (select 1 from @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=A.uniqwh))
				order by part_no,revision,date,nsort
		END   ---IF (@lcRptType='All')
		
	END   --- else --- if (@lcType='Consigned')
 
 END