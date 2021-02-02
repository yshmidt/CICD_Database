
-- =============================================
-- Author:			Debbie / Vicky
-- Create date:		10/11/2012
-- Description:		Created for the Kit Material Availability w/AVL Detail report within Kitting
-- Reports:			kitavail.rpt 
-- Modifications:	10/29/2012 DRP:  Due to some changes within Crystal Report I changed @lcIgnore = '' to @lcIgnore = 'No'
--					05/22/2013 DRP:  there was a spot within the code where I was calling BomIndented procedure and I had incorrectly had the ParentMatlType as char(8) when it should have been char(10).  It was causing truncating issues. 
--					09/24/2013 DRP:  the PnlBlank in the @results section used to be numeric(4,0) it needed to be numeric(7,0)
--					10/02/2013 DRP:   Found MatlType char (8) should have been MatlType char (10)
--					10/31/2013 VL:	 Fixed the issue that customer part number has less AVL than internal part number, here shows all from internal, also only pull active BOM part (added date filter)
--					11/05/2013 VL:	 Fixed the issue that result data show duplicate records if has allocation
--					11/18/2014 DR:  With Yelena's help we found in one case that the user used to have the part listed on the top level of the BOM with only one of the AVL's marked as approved. 
--									They then added a sub-assm to the bom that used the same part.  While on the sub-assm it had all of the AVL's approved.  But when exploded out into the results it was still pulling the inactive top level part.
--									added <<zresults.bomparent = AntiAvl4BomParentView.bomparent>> to the section of code that is used when the Kit has not been put in process yet. 
--					02/17/2015 VL:	Added code to filter out inactive parts
--					03/12/15 YS repalce Invtmfhd table with 2 new tables
-- 04/14/15 YS Location length is changed to varchar(256)
--					01/29/16 DRP:	reports of slow response time for some work orders.  Changed within INSERT @KitInvtView  section <<LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key+@BomCustno=Inventor.INT_UNIQ+Inventor.Custno>> to be
--									<<LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key=inventor.int_uniq and @BomCustno=Inventor.Custno>>
--					01/12/17 DRP:  I needed to account for the situation where the buy parts on the bom had Setup Scrap but the bom that it was used on happen to be set to not use Setup Scrap.
--- 03/28/17 YS changed length of the part_no column from 25 to 35
 --03/01/18 YS lotcode size change to 25
 -- 07/16/18 VL changed custname from char(35) to char(50)
 -- 03/13/2019 Mahesh B; Fixed the issues of "Column name or number of supplied values does not match table definition".  
 -- exec rptKitAvail '198','No','49f80792-e15e-4b62-b720-21b360e3108a'
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
-- =============================================
		CREATE PROCEDURE  [dbo].[rptKitAvail]


				 @lcWono AS char(10) = ''	-- Work order number
				,@lcIgnore as char(20) = 'No'	-- used within the report to indicate if the user elects to ignore any of the scrap settings. 
				,@userid uniqueidentifier = null
		aS
		BEGIN
		SET NOCOUNT ON;

		SET @lcWono=dbo.PADL(@lcWono,10,'0')
		-- 10/31/13 VL added @lcWoDueDate
		-- 11/01/13 VL added PrjUnique that used for get allocation for PJ
		declare @lcKitStatus Char(10), @lcWoDuedate as smalldatetime, @lcPrjUnique char(10)
		--Main Kitting information 
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
		DECLARE @ZKitMainView TABLE (DispPart_no char(35),Req_Qty numeric(12,2),Phantom char(1),DispRevision char(8),Part_class char(8),Part_type char(8),Kaseqnum char(10)
									,Entrydate smalldatetime,Initials char(8),Kitclosed bit,Act_qty numeric(12,2) -- Rej_qty numeric(12,2),Rej_date smalldatetime,Rej_reson char(10), -- 03/13/2019 Mahesh B; Fixed the issues of "Column name or number of supplied values does not match table definition".  
									,Uniq_key char(10),Dept_id char(4),Dept_name char(25),Wono char(10),Scrap numeric(6,2),Setupscrap numeric(4,0),Bomparent char(10)
									,Shortqty numeric(12,2),Lineshort bit,Part_sourc char(10),Qty numeric(12,2),Descript char(45),Inv_note text,U_of_meas char(4),Pur_uofm char(4)
									--- 03/28/17 YS changed length of the part_no column from 25 to 35
									,Ref_des char(15),Part_no char(35),Custpartno char(35),Ignorekit bit,Phant_make bit,Revision char(8),Serialyes bit,Matltype char(10),CustRev char(8)
									-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
									,allocatedQty numeric(12,2), userid uniqueidentifier)

		--Inventory mfgr and qty detail	from the Kitting Main information above
		-- 04/14/15 YS Location length is changed to varchar(256)
		DECLARE	@KitInvtView TABLE (Qty_oh numeric(12,2),QtyNotReserved numeric(12,2),QtyAllocKit numeric(12,2),Kaseqnum char(10),Uniq_key char(10),BomParent char(10)
									,Part_sourc char(10),AntiAvl char(2),Partmfgr char(8),Mfgr_pt_no char(30),Wh_gl_nbr char(13),UniqWh char(10),Location varchar(256)
									,W_key char(10),InStore bit,UniqSupno char(10),Warehouse char(6),CountFlag char(1),OrderPref numeric(2,0),UniqMfgrhd char(10),MfgrMtlType char(10)
									,cUniq_key char(10));

		-- 11/05/13 VL create ZWoalloc and ZPjAlloc that will be used to calculate Qty available
		 --03/01/18 YS lotcode size change to 25
		DECLARE @ZWoAlloc TABLE (W_key char(10), Uniq_key char(10), LotCode char(25), ExpDate smalldatetime, QtyAlloc numeric(12,2), Reference char(12), PoNum char(15))
		DECLARE @ZPJAlloc TABLE (W_key char(10), Uniq_key char(10), QtyAlloc numeric(12,2), LotCode char(25), ExpDate smalldatetime, Reference char(12), PoNum char(15), Fk_prjunique char(10))
			
		--Table that will compile the final results
		--09/24/2013 DRP:  changed the PnlBlank from numeric(4,0) to numeric(7,0)
		--10/31/13 VL added cUniq_key to save customer uniq_key if exist
		--11/01/13 VL Added w_key used to update QtyNotReserved
		-- 04/14/15 YS Location length is changed to varchar(256)
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		-- 07/16/18 VL changed custname from char(35) to char(50)
		declare @results table	(KitStatus char(10),Custname char(50),OrderDate smalldatetime,ParentBomPn char(35),ParentBomRev char(8),ParentBomDesc char(45),ParentMatlType char(10)
								,BldQty numeric (7,0),PerPanel numeric (4,0),PnlBlank numeric(7,0),Item_No numeric(4,0),DispPart_No varchar(max),DispRevision char(8),Req_Qty numeric(12,2)
								,Phantom char(1),Part_Class char(8),Part_Type char(8),Kaseqnum char(10),KitClosed bit,Act_Qty numeric(12,2),Uniq_key char(10),Dept_Id char(4)
								,Dept_Name char(25),Wono char(10),Scrap numeric (6,2),SetupScrap numeric (4,0),BomParent char(10),ShortQty numeric(12,2),LineShort bit,Part_Sourc char(10)
								,Qty numeric(12,2),Descript char(45),U_of_Meas char(4),
								--- 03/28/17 YS changed length of the part_no column from 25 to 35
								Part_No char(35),CustPartNo char(35),IgnoreKit bit,Phant_Make bit,Revision char(8),MatlType char(10)
								,CustRev char(8),location varchar(256),whse char(6),Qty_Oh numeric(12,2),QtyNotReserved numeric(12,2),QtyAllocKit numeric (12,2),AntiAvl char(2),PartMfgr char(8)
								,Mfgr_Pt_No char(30),MfgrMtlType char(10),OrderPref numeric(2,0),UniqMfgrHd char(10),PhParentPn char(35), cUniq_key char(10), W_key char(10))

		-- 09/28/12 VL 
		-- This table will keep all anti avl info for this bomparent
		DECLARE @AntiAvl4BomParentView TABLE (BomParent char(10), Uniq_key char(10), PartMfgr char(8), Mfgr_pt_no char(30), UNIQANTI char(10))

		DECLARE @llKitAllowNonNettable bit,@AllMftr bit, @WOuniq_key char(10), @BomCustno char(10);

		SET @lcWono=dbo.PADL(@lcWono,10,'0') --repopulating the work order number with the leading zeros

		SELECT @llKitAllowNonNettable = lKitAllowNonNettable FROM KitDef
		select @AllMftr = allmftr from KITDEF
		-- 10/31/13 VL get duedate
		--11/05/13 VL added @lcPrjUnique
		SELECT @WOuniq_key = Uniq_key, @lcWoDuedate = Due_date, @lcPrjUnique = PrjUnique FROM WOENTRY WHERE WONO = @lcWoNo
		SELECT @BomCustno = BomCustno FROM INVENTOR WHERE Uniq_key = @WOuniq_key
		-- 09/28/12 VL 
		INSERT @AntiAvl4BomParentView EXEC [AntiAvl4BomParentView] @WoUniq_key

		-- 10/01/12 VL moved SELECT @lcKitStatus from top to here, and return empty set if @@ROWCOUNT = 0
		select @lcKitStatus = woentry.KITSTATUS from WOENTRY where @lcWono = woentry.WONO 
		IF @@ROWCOUNT <> 0
		BEGIN
		--This section will then pull all of the detailed information from the KaMAIN tables because the kit has been put into process.  
		--Otherwise, if not in process ever we will then have to later pull from the BOM information  
			if ( @lcKitStatus <> '')
			Begin

			INSERT @ZKitMainView EXEC [KitMainView] @lcwono 
			
			-- 11/01/13 VL remove invt_res because can not link directly, has to use SUM() then link to get right qty, otherwise if a part is reserved more than one time, here will cause multiple records
			;
			WITH ZKitInvt1 AS
				(
				SELECT DISTINCT invtmfgr.qty_oh,Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved,
					--case when (invt_res.QTYALLOC IS null) then 0000000000.00 else invt_res.QTYALLOC end as QtyAllocKit,
					0000000000.00 AS QtyAllocKit,
					Kitmainview.Kaseqnum, Kitmainview.uniq_key, Kitmainview.BomParent, Kitmainview.Part_sourc,
					--03/12/15 YS repalce Invtmfhd table with 2 new table
					M.Partmfgr, M.Mfgr_pt_no, Warehous.Wh_gl_nbr, Invtmfgr.UniqWh,
					Invtmfgr.Location, Invtmfgr.W_key, Invtmfgr.InStore, InvtMfgr.UniqSupNo, Invtmfgr.CountFlag,
					Warehous.Warehouse, L.OrderPref, L.UniqMfgrHd, Invtmfgr.NetAble, M.lDisallowKit,M.MATLTYPE as MfgrMtlType
				FROM @ZKitMainView as KitMainView
					inner join invtmfgr on KitMainView.Uniq_key = invtmfgr.uniq_key
					--03/12/15 YS repalce Invtmfhd table with 2 new tables
					--inner join invtmfhd on invtmfgr.uniqmfgrhd = invtmfhd.uniqmfgrhd
					inner join invtmpnlink L on invtmfgr.uniqmfgrhd =l.uniqmfgrhd
					inner join mfgrmaster M on l.mfgrmasterid=m.mfgrmasterid
					inner join warehous on invtmfgr.uniqwh = warehous.uniqwh
					--left outer join INVT_RES on kitmainview.Wono = invt_res.WONO and invtmfgr.W_KEY = invt_res.W_KEY		
				WHERE Kitmainview.Uniq_key = Invtmfgr.uniq_key 
					AND M.lDisallowKit = 0
					AND 1 = (CASE WHEN @llKitAllowNonNettable = 1 THEN 1 ELSE Invtmfgr.NetAble END)
					AND L.Is_deleted = 0
					and m.is_deleted=0
					AND Invtmfgr.UniqWh = Warehous.UniqWh
					AND  Warehouse<>'MRB'
					AND Invtmfgr.Is_Deleted = 0
				)

			INSERT @KitInvtView 

			SELECT DISTINCT qty_oh,QtyNotReserved,QtyAllocKit,ZKitInvt1.Kaseqnum, ZKitInvt1.Uniq_key, ZKitInvt1.BomParent, ZKitInvt1.Part_sourc
							,case when (antiavl.PARTMFGR is null) then 'A' else '' end as antiAVL, ZKitInvt1.Partmfgr,ZKitInvt1.Mfgr_pt_no
							,ZKitInvt1.wh_gl_nbr,ZKitInvt1.UniqWh,ZKitInvt1.Location,ZKitInvt1.W_key,ZKitInvt1.InStore,ZKitInvt1.UniqSupno
							,ZKitInvt1.Warehouse,ZKitInvt1.CountFlag, ZKitInvt1.OrderPref, ZKitInvt1.UniqMfgrhd,ZKitInvt1.MfgrMtlType
							,CASE WHEN (Inventor.UNIQ_KEY IS NULL) THEN ZKitInvt1.Uniq_key ELSE Inventor.UNIQ_KEY END AS cUniq_key
			FROM			ZKitInvt1 
							left outer join ANTIAVL on ZKitInvt1.Bomparent = ANTIAVL.BOMPARENT 
											and ZKitInvt1.Uniq_key = ANTIAVL.UNIQ_KEY 
											and ZKitInvt1.PARTMFGR = ANTIAVL.PARTMFGR 
											and ZKitInvt1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO
							LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key=inventor.int_uniq and @BomCustno=Inventor.Custno
							--LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key+@BomCustno=Inventor.INT_UNIQ+Inventor.Custno	--01/29/16 DRP:  replaced with the above
			ORDER BY		Partmfgr, Warehouse, Location

		-- 09/28/12 VL 
		-- Now the cUniq_key can link to Antiavl info
		-- will join with antiavl (with cUniq_key) and invtmfhd, if no record in invtmfhd, will not update Antiavl with 'A'
		-- 10/31/13 VL changed to use LEFT OUTER JOIN and set criterial to have cUniq_key<>''
		UPDATE @KitInvtView
		--03/12/15 YS repalce Invtmfhd table with 2 new table
			SET AntiAvl = CASE WHEN (L.UNIQ_KEY IS NULL) THEN ' ' ELSE 'A' END
			--03/12/15 YS repalce Invtmfhd table with 2 new table
			FROM @KitInvtView KitInvtView LEFT OUTER JOIN 
				(SELECT Uniq_key,Uniqmfgrhd,Partmfgr,mfgr_pt_no FROM InvtmpnLink INNER JOIN mfgrmaster on Mfgrmaster.mfgrMasterid=Invtmpnlink.mfgrMasterid where mfgrMaster.is_deleted=0 and invtmpnlink.is_deleted=0) L
			--@KitInvtView KitInvtView LEFT OUTER JOIN INVTMFHD
			ON KitInvtView.cUniq_key = L.UNIQ_KEY
			AND KitInvtView.Partmfgr = L.PARTMFGR
			AND KitInvtView.Mfgr_pt_no = L.MFGR_PT_NO
			--AND InvtMfhd.IS_DELETED = 0
			WHERE KitInvtView.cUniq_key<>''
		-- 10/31/13 VL changed to use LEFT OUTER JOIN and set criterial to have cUniq_key<>'', also added antiavl = 'A' that some records in previous UPDATE SQL might already set to ' ', this SQL might cause it to have 'A' again, need to filter out
		UPDATE @KitInvtView
			SET AntiAvl = CASE WHEN (AntiAvl4BomParentView.UNIQ_KEY IS NULL) THEN 'A' ELSE ' ' END
			FROM @KitInvtView KitInvtView LEFT OUTER JOIN @AntiAvl4BomParentView AntiAvl4BomParentView
			ON KitInvtView.cUniq_key = AntiAvl4BomParentView.UNIQ_KEY
			AND KitInvtView.Partmfgr = AntiAvl4BomParentView.PARTMFGR
			AND KitInvtView.Mfgr_pt_no = AntiAvl4BomParentView.MFGR_PT_NO
			WHERE cUniq_key<>''
			AND AntiAvl = 'A'			

		--select * from @KitInvtView
		--end


			-- SQL result 
		-- 10/31/13 VL added cUniq_key
		-- 11/05/13 VL added DISTINCT and W_key to update allocation
		insert into @results
			SELECT	DISTINCT woentry.kitstatus,isnull(customer.custname,'') as CustName,woentry.ORDERDATE,i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE
					,woentry.BLDQTY,I4.PERPANEL,case when I4.perpanel = 0 then woentry.BLDQTY else cast(woentry.bldqty/i4.perpanel as numeric (7,0))end as PnlBlank
					,bom_det.ITEM_NO,zmain2.DispPart_no,ZMain2.DispRevision
					--,case when @lcIgnore = 'No' then ZMain2.Req_Qty
					--	else case when @lcIgnore = 'Ignore Scrap' then zmain2.Req_Qty-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
					--		else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.req_qty-zmain2.setupscrap
					--			else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.req_qty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as Req_Qty	--01/12/17 DRP:  replaced with the below
					,case when @lcIgnore = 'No' then ZMain2.Req_Qty
						else case when @lcIgnore = 'Ignore Scrap' then zmain2.Req_Qty-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
							else case when @lcIgnore = 'Ignore Setup Scrap' then case when i4.USESETSCRP = 1 then zmain2.req_qty-zmain2.setupscrap else zmain2.req_qty end
								else case when @lcIgnore = 'Ignore Both Scraps' then case when i4.usesetscrp = 1 then zmain2.req_qty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) else zmain2.Req_Qty-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100
,0)end  
									end end end end as Req_Qty
					,ZMain2.Phantom,ZMain2.Part_class,ZMain2.Part_type,ZMain2.Kaseqnum,ZMain2.Kitclosed,ZMain2.Act_qty,zmain2.Uniq_key,ZMain2.Dept_id,ZMain2.Dept_name
					,ZMain2.Wono,ZMain2.Scrap--,ZMain2.Setupscrap	--01/12/17 DRP:  replaced with the below 
					,case when i4.usesetscrp = 1 then ZMain2.Setupscrap else 0 end as Setupscrap
					,ZMain2.Bomparent
					--,case when @lcIgnore = 'No' then ZMain2.ShortQty
					--	else case when @lcIgnore = 'Ignore Scrap' then zmain2.Shortqty - round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
					--		else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.shortqty-zmain2.setupscrap
					--			else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.shortqty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as ShortQty	--01/12/17 DRP:  replaced with the below
					,case when @lcIgnore = 'No' then ZMain2.ShortQty
						else case when @lcIgnore = 'Ignore Scrap' then zmain2.Shortqty - round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)
							else case when @lcIgnore = 'Ignore Setup Scrap' then case when i4.usesetscrp = 1 then zmain2.shortqty-zmain2.setupscrap else zmain2.Shortqty end
								else case when @lcIgnore = 'Ignore Both Scraps' then case when i4.usesetscrp = 1 then zmain2.shortqty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) else zmain2.Shortqty - round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)
/100,0) end
									end end end end as ShortQty
					,ZMain2.Lineshort,ZMain2.Part_sourc,ZMain2.Qty,ZMain2.Descript,ZMain2.U_of_meas,ZMain2.Part_no,ZMain2.Custpartno,ZMain2.Ignorekit
					,ZMain2.Phant_make,ZMain2.Revision,ZMain2.Matltype,ZMain2.CustRev,zinvtv2.location,zinvtv2.Warehouse,zinvtv2.qty_oh, ZInvtV2.QtyNotReserved, zinvtv2.QtyAllocKit, zinvtV2.AntiAvl
					, ZInvtV2.Partmfgr, ZInvtV2.Mfgr_pt_no, zinvtv2.MfgrMtlType, ZInvtV2.OrderPref, ZInvtV2.UniqMfgrhd,case when ZMain2.Phantom = 'f' then rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) else ''end as PhParentPn
					,ZInvtV2.cUniq_key, ZInvtV2.W_key
					
			FROM	@ZKitMainView as ZMain2
					inner join @KitInvtView as ZInvtV2  on ZMain2.Uniq_key = ZInvtV2.Uniq_key
					left outer join INVENTOR as I3 on ZInvtV2.BomParent = I3.UNIQ_KEY
					-- 11/05/13 VL found didn't have  AND ZMain2.Dept_id = Bom_det.DEPT_ID criteria, add it here
					left outer join BOM_DET on ZInvtV2.BomParent = bom_det.BOMPARENT and ZInvtV2.Uniq_key = bom_det.UNIQ_KEY AND ZMain2.Dept_id = Bom_det.DEPT_ID            
					inner join WOENTRY on zmain2.Wono = woentry.wono
					inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO
					inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY
					-- 10/31/13 VL added Antiavl = 'A' criteria
					AND ANTIAVL='A'					


			-- 11/05/13 VL added code to update QtyNotReserved from WO/PJ allocation
			INSERT @ZWoAlloc EXEC WoAllocatedView @lcWono
		
			-- Update QtyNotReserved, need to group @ZWoAlloc by W_key
			;WITH ZWoAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZWoAlloc GROUP BY W_key)
			UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZWoAllocSumW_key WHERE Results.W_key=ZWoAllocSumW_key.W_key

			-- If this WO link to PJ
			IF @lcPrjUnique<>''
				BEGIN
				INSERT @ZPJAlloc EXEC Invt_res4PJView @lcPrjUnique
	
				-- Update QtyNotReserved, need to group @ZPJAlloc by W_key
				;WITH ZPJAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZPJAlloc GROUP BY W_key)
				UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZPJAllocSumW_key WHERE Results.W_key=ZPJAllocSumW_key.W_key
						
			END
			-- 11/05/13 VL End}						
			select R1.*,MICSSYS.lic_name from @results as R1 cross join MICSSYS 
		end


		--if the kit has never been put into process then the below section will gather the information from the Bill of Material
			else if ( @lcKitStatus = '')
			begin

			declare		@lcBomParent char(10)
						,@IncludeMakebuy bit = 1 
						,@ShowIndentation bit =1
						--,@UserId uniqueidentifier=NULL
						,@gridId varchar(50)= null	
							
			select @lcBomParent = woentry.UNIQ_KEY from WOENTRY where @lcWono = woentry.wono				
			--- 03/28/17 YS changed length of the part_no column from 25 to 35
			declare @tBom table	(bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) 
								,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8)
								,Item_note varchar(max),Offset numeric(4,0),Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max)
								,U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5)
								,Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer,path varchar(max),sort varchar(max),UniqBomNo char(10)
								--- 03/28/17 YS changed length of the part_no column from 25 to 35
								,CustPartNo char(35),CustRev char(8),CustUniqKey char(10))
			;
			WITH BomExplode as (
								SELECT	B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc
										,CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo
										,CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,C.Part_class,C.Part_type,C.Descript,c.MATLTYPE
										,B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap--, C.Setupscrap	--01/12/17 DRP:  replaced with the below
										,case when M.USESETSCRP = 1 then C.Setupscrap else 0 end as SetupScrap 
										,M.USESETSCRP
										,M.STDBLDQTY, C.Phant_Make, C.StdCost, C.Make_buy, C.Status,cast(1.00 as numeric(9,2)) as TopQty,B.qty as Qty, cast(0 as Integer) as Level
										,'/'+CAST(bomparent as varchar(max)) as path,CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort
										,B.UNIQBOMNO 
								FROM	BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
										INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
								WHERE	B.BOMPARENT=@lcBomParent 
								-- 10/31/13 VL get code from kit pick list report to only pull active BOM part
								and 1 = case when NOT @lcWoDuedate IS null then 
									case when (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcWoDuedate)>=0)
									AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcWoDuedate)<0) THEN 1 ELSE 0 END
									ELSE 1
									END
								-- 02/17/15 VL also added status = 'Active'
								AND C.Status = 'Active'
				
			UNION ALL
				
								SELECT  B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no  ,C2.PART_NO,C2.Revision,c2.Part_sourc 
										,CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo
										,CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,C2.Part_class, C2.Part_type, C2.Descript,c2.MATLTYPE,B2.Dept_id
										,B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno,C2.Inv_note, C2.U_of_meas, C2.Scrap--, C2.Setupscrap	--01/12/17 DRP:  replaced with the below
										,case when M2.USESETSCRP = 1 then C2.Setupscrap else 0 end as SetupScrap 
										,M2.USESETSCRP,M2.STDBLDQTY
										,C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status,P.Qty as TopQty,B2.QTY, P.Level+1,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path 
										,CAST(RTRIM(p.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,B2.UNIQBOMNO   
								FROM	BomExplode as P 
										INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
										INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
										INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY 
								WHERE	P.PART_SOURC='PHANTOM'
										or (p.PART_SOURC = 'MAKE' and P.PHANT_MAKE = 1) 
								--**THE BELOW WAS THE CODE THAT YELENA WAS USING WITHIN THE BOMINDENTED PROCEDURE, BUT IT DID NOT WORK FOR THIS REPORT
								--**SO I TOOK THE ENTIRE CODE FROM THE PROCEDURE AND MADE THE BELOW CHANGES BY REMOVING THE BELOW 
										--or (P.PART_SOURC = 'MAKE' and P.MAKE_BUY = 1) 
										--or (P.PART_SOURC='MAKE' and P.MAKE_BUY=CASE WHEN @IncludeMakeBuy=1 THEN P.MAKE_BUY ELSE 0 END)
								-- 02/17/15 VL found did not have code to consider eff_dt and term_dt
								and 1 = case when NOT @lcWoDuedate IS null then 
									case when (B2.Eff_dt is null or DATEDIFF(day,B2.EFF_DT,@lcWoDuedate)>=0)
									AND (B2.Term_dt is Null or DATEDIFF(day,B2.TERM_DT,@lcWoDuedate)<0) THEN 1 ELSE 0 END
									ELSE 1
									END
								-- 02/17/15 VL also added status = 'Active'
								AND C2.Status = 'Active'
								)
--- 03/28/17 YS changed length of the part_no column from 25 to 35
			insert into @tbom	SELECT	E.*,isnull(CustI.CUSTPARTNO,space(35)) as CustPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey  
								from	BomExplode E 
										LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ 
										and E.BOMCUSTNO=CustI.CUSTNO 
								ORDER BY sort OPTION (MAXRECURSION 100)
				
		--						select * from @tBom 
		--end
			;
			-- 09/28/12 VL change first SQL LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY to LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY 
			-- so it link with internal part number records
			WITH BomWithAvl AS	(
			---03/12/15 YS replaced invtmfhd table with 2 new tables
								select	B.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,B.MatlType as MfgrMatlType,MF.MATLTYPEVALUE 
								FROM	@tBom B 
											---03/12/15 YS replaced invtmfhd table with 2 new tables
										LEFT OUTER JOIN 
										(SELECT Uniq_key,Uniqmfgrhd,partmfgr,mfgr_pt_no,ORDERPREF,MATLTYPEVALUE 
												from MfgrMaster M INNER JOIN Invtmpnlink L ON l.mfgrmasterid=m.mfgrmasterid
												WHERE m.is_deleted=0 and L.is_deleted=0) MF
										ON B.Uniq_key=MF.Uniq_key
										--LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY 
								WHERE	B.CustUniqKey<>' '
								---03/12/15 YS replaced invtmfhd table with 2 new tables
										--AND Invtmfhd.IS_DELETED =0 
										and NOT EXISTS (SELECT	bomParent,UNIQ_KEY 
														FROM	ANTIAVL A 
														where	A.BOMPARENT =B.bomParent 
																and A.UNIQ_KEY = B.CustUniqKey 
																and A.PARTMFGR =MF.PARTMFGR 
																and A.MFGR_PT_NO =MF.MFGR_PT_NO )
			UNION ALL
								---03/12/15 YS replaced invtmfhd table with 2 new tables
								select	B.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,B.MatlType as MfgrMatlType,MF.MATLTYPEVALUE
								FROM	@tBom B 
											---03/12/15 YS replaced invtmfhd table with 2 new tables
										--LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY 
										LEFT OUTER JOIN 
										(SELECT Uniq_key,Uniqmfgrhd,partmfgr,mfgr_pt_no,ORDERPREF,MATLTYPEVALUE 
												from MfgrMaster M INNER JOIN Invtmpnlink L ON l.mfgrmasterid=m.mfgrmasterid
												WHERE m.is_deleted=0 and L.is_deleted=0) MF
										ON B.Uniq_key=MF.Uniq_key
								WHERE	B.CustUniqKey=' '
									--	AND Invtmfhd.IS_DELETED =0 
										---03/12/15 YS replaced invtmfhd table with 2 new tables
										and NOT EXISTS (SELECT	bomParent,UNIQ_KEY 
														FROM	ANTIAVL A 
														where	A.BOMPARENT =B.bomParent 
																and A.UNIQ_KEY = B.UNIQ_KEY 
																and A.PARTMFGR =MF.PARTMFGR 
																and A.MFGR_PT_NO =MF.MFGR_PT_NO )
								)

		-- 10/31/13 VL added cUniq_key
		-- 11/05/13 VL remove Invt_res, will update allocated qty later, added w_key
		insert into @results
			select	woentry.kitstatus,ISNULL(customer.custname,'') as CustName,woentry.ORDERDATE,i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE
					,woentry.BLDQTY,I4.PERPANEL,case when I4.perpanel = 0 then woentry.BLDQTY else cast(woentry.bldqty/i4.perpanel as numeric (7,0))end as PnlBlank
					,b1.ITEM_NO,b1.viewpartno as DispPart_no,b1.ViewRevision as DispRevision
					,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0) 
						else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap 
							else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)
								else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end as Req_Qty
					,CASE when woentry.UNIQ_KEY =  B1.BomParent THEN ' ' ELSE 'f' end as Phantom,b1.Part_class,b1.Part_type,CAST('' as char(10)) as kaseqnum
					,CAST(0 as bit) as kitclosed,CAST(0.00 as numeric(5,2)) as Act_qty,b1.UNIQ_KEY,b1.Dept_id,depts.DEPT_NAME,woentry.WONO,b1.scrap
					,b1.SetupScrap,b1.bomParent
					,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0) 
						else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap 
							else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)
								else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end as ShortQty
					,CAST (0 as bit) as lineshort,b1.Part_sourc,b1.TopQty*b1.qty as Qty,b1.Descript,b1.U_of_meas,b1.PART_NO,b1.CustPartNo,CAST(0 as bit) as Ignorekit
					,CAST (0 as bit) as Phant_make,b1.Revision,b1.MatlType,b1.CustRev,invtmfgr.location,warehous.WAREHOUSE,invtmfgr.QTY_OH,Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved
					-- 11/05/13 VL remove Invt_res field, need to use SUM() on invt_res table, will update this field later
					--,case when (invt_res.QTYALLOC IS null) then 0000000000.00 else invt_res.QTYALLOC end as QtyAllocKit
					, 0000000000.00 AS QtyAllocKit							
					,case when (antiavl.PARTMFGR is null) then 'A' else '' end as antiAVL
					,b1.PARTMFGR,b1.MFGR_PT_NO,b1.MfgrMatlType,b1.ORDERPREF,b1.UNIQMFGRHD,case when woentry.uniq_key = B1.bomparent then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn
					, B1.CustUniqKey AS cUniq_key, Invtmfgr.W_key
			from	WOENTRY	
					inner join BomWithAvl as B1 on woentry.UNIQ_KEY =  right(Left(b1.path,11),10)
					inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO
					inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY
					left outer join DEPTS on b1.Dept_id = depts.DEPT_ID
					inner join INVTMFGR on b1.uniqmfgrhd = invtmfgr.uniqmfgrhd
					inner join warehous on invtmfgr.uniqwh = warehous.uniqwh
					--left outer join INVT_RES on woentry.Wono = invt_res.WONO and invtmfgr.W_KEY = invt_res.W_KEY	
					left outer join ANTIAVL on B1.Bomparent = ANTIAVL.BOMPARENT and b1.Uniq_key = ANTIAVL.UNIQ_KEY and b1.PARTMFGR = ANTIAVL.PARTMFGR and b1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO
					left outer join INVENTOR as I3 on b1.BomParent = I3.UNIQ_KEY
				
			where	@lcWono = woentry.WONO
					AND B1.part_sourc <> 'PHANTOM'
					AND B1.Phantom_make <> 1
					-- 10/31/13 VL added netable = 1 and filter out deleted record
					AND INVTMFGR.IS_DELETED <> 1
					AND Invtmfgr.NETABLE = 1
				
		-- 10/31/13 VL DED reported a problem that internal part number has more AVLs and customer has less AVLs, if the BOM is assigned to a customer, here show all AVLs from internal, will fix to only show AVL for the customer
		-- changed to use LEFT OUTER JOIN and set criterial to have cUniq_key<>''
		---03/12/15 YS replaced invtmfhd table with 2 new tables
		UPDATE @results
			SET AntiAvl = CASE WHEN (mf.UNIQ_KEY IS NULL) THEN ' ' ELSE 'A' END
			FROM @results Zresults 
			---03/12/15 YS replaced invtmfhd table with 2 new tables
			--LEFT OUTER JOIN INVTMFHD
			LEFT OUTER JOIN 
			(SELECT Uniq_key,Uniqmfgrhd,partmfgr,mfgr_pt_no,ORDERPREF,MATLTYPEVALUE 
					from MfgrMaster M INNER JOIN Invtmpnlink L ON l.mfgrmasterid=m.mfgrmasterid
					WHERE m.is_deleted=0 and L.is_deleted=0) MF
			ON Zresults.cUniq_key=MF.Uniq_key
			--ON Zresults.cUniq_key = Invtmfhd.UNIQ_KEY
			AND Zresults.Partmfgr = MF.PARTMFGR
			AND Zresults.Mfgr_pt_no = MF.MFGR_PT_NO
			--AND InvtMfhd.IS_DELETED = 0
			WHERE cUniq_key<>''

		-- 10/31/13 VL added Antiavl = 'A' at end, found in previous SQL might already correctly set antiavl = '' for those don't have invtmfhd record, but this update SQL might set to 'A' again, need to filter out those records
		UPDATE @results
			SET AntiAvl = CASE WHEN (AntiAvl4BomParentView.UNIQ_KEY IS NULL) THEN 'A' ELSE ' ' END
			FROM @results Zresults LEFT OUTER JOIN @AntiAvl4BomParentView AntiAvl4BomParentView
			ON Zresults.cUniq_key = AntiAvl4BomParentView.UNIQ_KEY
			AND Zresults.Partmfgr = AntiAvl4BomParentView.PARTMFGR
			AND Zresults.Mfgr_pt_no = AntiAvl4BomParentView.MFGR_PT_NO
			and zresults.bomparent = AntiAvl4BomParentView.bomparent	--11/18/2014 DRP:  needed to add this in case the part is inactive on top level but then is included on sublevel (but with different avl approvals)
			WHERE cUniq_key<>''
			AND AntiAvl='A'

		DELETE FROM @results WHERE ANTIAVL<>'A'		
		-- 10/31/13 VL End}
									
		-- 11/05/13 VL added code to update QtyNotReserved from WO/PJ allocation
		INSERT @ZWoAlloc EXEC WoAllocatedView @lcWono
	
		-- Update LotQtyAvail field

		-- Update QtyNotReserved, need to group @ZWoAlloc by W_key
		;WITH ZWoAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZWoAlloc GROUP BY W_key)
		UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZWoAllocSumW_key WHERE Results.W_key=ZWoAllocSumW_key.W_key

		-- If this WO link to PJ
		IF @lcPrjUnique<>''
			BEGIN
			INSERT @ZPJAlloc EXEC Invt_res4PJView @lcPrjUnique

			-- Update QtyNotReserved, need to group @ZPJAlloc by W_key
			;WITH ZPJAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZPJAlloc GROUP BY W_key)
			UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZPJAllocSumW_key WHERE Results.W_key=ZPJAllocSumW_key.W_key
				
		END
		-- 11/05/13 VL End}
		
		select R2.*,MICSSYS.LIC_NAME from @results as R2 cross join MICSSYS

		end

		END
		ELSE -- ELSE of @@ROWCOUNT <> 0
			SELECT R2.*,MICSSYS.LIC_NAME from @results as R2 cross join MICSSYS
		end