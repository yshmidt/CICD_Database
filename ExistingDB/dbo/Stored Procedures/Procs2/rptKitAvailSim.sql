--/****** Object:  StoredProcedure [dbo].[rptKitAvailSim]    Script Date: 02/25/2013 13:33:14 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

-- =============================================
-- Author:			Debbie 
-- Create date:		02/25/2013
-- Description:		Created for the Kit Material Availability w/AVL Detail ~ Simulation report within Kitting
-- Reports:			kitavailsim.rpt 
-- Modifications:	09/24/2013 DRP:  the PnlBlank in the @results section used to be numeric(4,0) it needed to be numeric(7,0)
--					10/02/2013 DRP:   Found MatlType char (8) should have been MatlType char (10)
--					02/19/2014 DRP:  Fount that the ParentMatlType was still showing as char(8) . . changed them to also be char(10)
--					03/21/2014 DRP:  The results were displaying obsolete items from the bom.  I modified the insert into @tbom section of code to include ~where(Term_dt>GETDATE() OR Term_dt IS NULL)~
--					02/17/2015 VL:   added Eff_dt and status ='Active'
--					3/12/15 YS repaced invtmfhd table with 2 new tables
--					04/14/15 YS Location length is changed to varchar(256)
--					12/17/15 DRP:	 added AvlLink to the <<@tBom>> To help me link to the Customer AVL in order to display what has been removed from the Customer AVL listing.  then changed the <<LEFT OUTER JOIN INVTMFHD ON B.avllink=INVTMFHD.UNIQ_KEY >> witin the BomWithAvl Section
--					12/18/15 DRP:	The changes i made on 12/17/15 now caused the Qty on hand to pull from the incorrect mfgr set if the part happen to be associated with a CPN.  With Yelena's help we made some modifications to get the correct Qty_oh and also cleaned upa couple other items. 
--					12/19/16 DRP:	rearranged the order of the fields and added w_key to the results.  this allowed me to use the xls results for when new users want to bring partially completed jobs into manex.
--					01/12/17 DRP:  I needed to account for the situation where the buy parts on the bom had Setup Scrap but the bom that it was used on happen to be set to not use Setup Scrap.
--					03/28/17 YS changed length of the part_no column from 25 to 35
--					04/25/18 Rajendra K : Repaced invtmfhd table with 2 new tables 'invtmpnlink' and 'mfgrmaster'
--					06/20/18 Rajendra K : Added new parameter @lcUniqWh (for Warehouse filter)
-- =============================================
CREATE PROCEDURE  [dbo].[rptKitAvailSim]
					 @lcUniq_key AS char(10) = ''	-- Product Uniq_key
					,@lcQty numeric(5,0) = '1'		-- user would populate the desired Buidl qty for simulation
					,@lcIgnore as char(20) = 'No'	-- Here the user will specify if report is to ignore any of the scrap settings. 
					,@lcUniqWh as varchar (max) = 'All'	-- 6/20/18 Rajendra K : Added new parameter @lcUniqWh (for Warehouse filter)
					,@userid uniqueidentifier = null
			aS
			BEGIN

			--SET NOCOUNT ON;
		   ---------
			declare  @uniqWh table (UniqWh char(10))
			---------
			if @lcUniqWh<>'All' and @lcUniqWh<>'' and @lcUniqWh is not null
				insert into @UniqWh  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqWh,',')

			--Main Kitting information 
			--- 03/28/17 YS changed length of the part_no column from 25 to 35
			DECLARE @ZKitMainView TABLE (DispPart_no char(35),Req_Qty numeric(12,2),Phantom char(1),DispRevision char(8),Part_class char(8),Part_type char(8),Kaseqnum char(10)
										,Entrydate smalldatetime,Initials char(8),Rej_qty numeric(12,2),Rej_date smalldatetime,Rej_reson char(10),Kitclosed bit,Act_qty numeric(12,2)
										,Uniq_key char(10),Dept_id char(4),Dept_name char(25),Wono char(10),Scrap numeric(6,2),Setupscrap numeric(4,0),Bomparent char(10)
										,Shortqty numeric(12,2),Lineshort bit,Part_sourc char(10),Qty numeric(12,2),Descript char(45),Inv_note text,U_of_meas char(4),Pur_uofm char(4)
										,Ref_des char(15),
										--- 03/28/17 YS changed length of the part_no column from 25 to 35
										Part_no char(35),Custpartno char(35),Ignorekit bit,Phant_make bit,Revision char(8),Serialyes bit,Matltype char(10),CustRev char(8))

			--Inventory mfgr and qty detail	from the Kitting Main information above
			-- 04/14/15 YS Location length is changed to varchar(256)
			DECLARE	@KitInvtView TABLE (Qty_oh numeric(12,2),QtyNotReserved numeric(12,2),QtyAllocKit numeric(12,2),Kaseqnum char(10),Uniq_key char(10),BomParent char(10)
										,Part_sourc char(10),AntiAvl char(2),Partmfgr char(8),Mfgr_pt_no char(30),Wh_gl_nbr char(13),UniqWh char(10),Location varchar(256)
										,W_key char(10),InStore bit,UniqSupno char(10),Warehouse char(6),CountFlag char(1),OrderPref numeric(2,0),UniqMfgrhd char(10),MfgrMtlType char(10)
										,cUniq_key char(10));
				
			--Table that will compile the final results
			--09/24/2013 DRP:  changed the PnlBlank from numeric(4,0) to numeric(7,0
			-- 04/14/15 YS Location length is changed to varchar(256)
				--12/18/16 DRP:  rearranged the position of some of the fields and added W_Key
				--- 03/28/17 YS changed length of the part_no column from 25 to 35
			declare @results table	(ParentBomPn char(35),ParentBomRev char(8),ParentBomDesc char(45),ParentMatlType char(10),BldQty numeric (7,0),PerPanel numeric (4,0),PnlBlank numeric(7,0)
									,Item_No numeric(4,0)
									,DispPart_No varchar(max),DispRevision char(8),Part_Sourc char(10),Part_Class char(8),Part_Type char(8),Descript char(45),U_of_Meas char(4)
									,Uniq_key char(10),w_key char(10),whse char(6),location varchar(256),PartMfgr char(8),Mfgr_Pt_No char(30),Req_Qty numeric(12,2),Phantom char(1)
									,Act_Qty numeric(12,2),Dept_Id char(4),Dept_Name char(25),Scrap numeric (6,2),SetupScrap numeric (4,0),BomParent char(10),ShortQty numeric(12,2)
									,Qty numeric(12,2),
									--- 03/28/17 YS changed length of the part_no column from 25 to 35
									Part_No char(35),CustPartNo char(35),IgnoreKit bit,Phant_Make bit,Revision char(8)
									,MatlType char(10),CustRev char(8),Qty_Oh numeric(12,2),QtyNotReserved numeric(12,2),AntiAvl char(2),MfgrMtlType char(10),OrderPref numeric(2,0),UniqMfgrHd char(10),PhParentPn char(35))


				declare		@lcBomParent char(10)
							,@IncludeMakebuy bit = 1 
							,@ShowIndentation bit =1
							--,@UserId uniqueidentifier=NULL
							,@gridId varchar(50)= null	
				
								
				select @lcBomParent = @lcUniq_key				
		--10/02/2013 DRP:   Found MatlType char (8) should have been MatlType char (10)
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
				declare @tBom table	(bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) 
									,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8)
									,Item_note varchar(max),Offset numeric(4,0),Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max)
									,U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5)
									,Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer,path varchar(max),sort varchar(max),UniqBomNo char(10)
									--- 03/28/17 YS changed length of the part_no column from 25 to 35
									,CustPartNo char(35),CustRev char(8),CustUniqKey char(10),AvlLink char(10))
				;
				WITH BomExplode as (
									SELECT	B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc
											,CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo
											,CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,C.Part_class,C.Part_type,C.Descript,c.MATLTYPE
											,B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap  --, C.Setupscrap	--01/12/17 DRP:  replaced with the below
											,case when M.USESETSCRP = 1 then C.Setupscrap else 0 end as SetupScrap 
											,M.USESETSCRP
											,M.STDBLDQTY, C.Phant_Make, C.StdCost, C.Make_buy, C.Status,cast(1.00 as numeric(9,2)) as TopQty,B.qty as Qty, cast(0 as Integer) as Level
											,'/'+CAST(bomparent as varchar(max)) as path,CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort
											,B.UNIQBOMNO 
									FROM	BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
											INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
									WHERE	B.BOMPARENT=@lcBomParent 
					
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
									)
									--- 03/28/17 YS changed length of the part_no column from 25 to 35
				insert into @tbom	SELECT	E.*,isnull(CustI.CUSTPARTNO,space(35)) as CustPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey  
											,isnull(CustI.UNIQ_KEY,E.uniq_key) as AvlLink	--12/17/15 DRP:  Added
									from	BomExplode E 
											LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ 
											and E.BOMCUSTNO=CustI.CUSTNO 
/*03/21/2014*/						where	(Term_dt>GETDATE() OR Term_dt IS NULL)
									-- 02/17/15 VL added Eff_dt and status ='Active'
									AND (Eff_dt<GETDATE() OR Eff_dt IS NULL)
									AND E.Status = 'Active'
									ORDER BY sort OPTION (MAXRECURSION 100)
									--select * from @tBom 

				;
				-- 09/28/12 VL change first SQL LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY to LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY 
				-- so it link with internal part number records
				WITH BomWithAvl AS	(
									-- 3/12/15 YS repaced invtmfhd table with 2 new tables
									select	B.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,B.MatlType as MfgrMatlType,MF.MATLTYPEVALUE 
									FROM	@tBom B 
											-- 3/12/15 YS repaced invtmfhd table with 2 new tables
											--LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY 
											LEFT OUTER JOIN 
											(select Uniq_key,Uniqmfgrhd,PARTMFGR ,MFGR_PT_NO,L.ORDERPREF ,M.MATLTYPEVALUE 
												FROM Mfgrmaster M inner join invtmpnlink L on M.mfgrmasterid=L.mfgrmasterid where m.is_deleted=0 and L.is_deleted=0) MF
									ON B.AvlLink=MF.Uniq_key	--12/17/15 DRP:  ON B.Uniq_key=MF.Uniq_key
									WHERE	B.CustUniqKey<>' '
										--	AND Invtmfhd.IS_DELETED =0 
										-- 3/12/15 YS repaced invtmfhd table with 2 new tables
											and NOT EXISTS (SELECT	bomParent,UNIQ_KEY 
															FROM	ANTIAVL A 
															where	A.BOMPARENT =B.bomParent 
																	and A.UNIQ_KEY = B.CustUniqKey 
																	and A.PARTMFGR =MF.PARTMFGR 
																	and A.MFGR_PT_NO =MF.MFGR_PT_NO )
				UNION ALL
									-- 3/12/15 YS repaced invtmfhd table with 2 new tables
									select	B.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,B.MatlType as MfgrMatlType,MF.MATLTYPEVALUE 
									FROM	@tBom B 
									-- 3/12/15 YS repaced invtmfhd table with 2 new tables
											--LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY 
											LEFT OUTER JOIN 
											(select Uniq_key,Uniqmfgrhd,PARTMFGR ,MFGR_PT_NO,L.ORDERPREF ,M.MATLTYPEVALUE 
												FROM Mfgrmaster M inner join invtmpnlink L on M.mfgrmasterid=L.mfgrmasterid where m.is_deleted=0 and L.is_deleted=0) MF
									ON B.AvlLink=MF.Uniq_key	--12/17/15 DRP:  ON B.Uniq_key=MF.Uniq_key
									WHERE	B.CustUniqKey=' '
									-- 3/12/15 YS repaced invtmfhd table with 2 new tables
											--AND Invtmfhd.IS_DELETED =0 
											and NOT EXISTS (SELECT	bomParent,UNIQ_KEY 
															FROM	ANTIAVL A 
															where	A.BOMPARENT =B.bomParent 
																	and A.UNIQ_KEY = B.UNIQ_KEY 
																	and A.PARTMFGR =MF.PARTMFGR 
																	and A.MFGR_PT_NO =MF.MFGR_PT_NO )
									)

--12/18/16 DRP:  rearranged the position of some of the fields and added W_Key
			insert into @results
				select	i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE,@lcQty as BldQty
						,I4.PERPANEL,case when I4.perpanel = 0 then @lcQty else cast(@lcQty/i4.perpanel as numeric (7,0))end as PnlBlank
						,b1.ITEM_NO,b1.viewpartno as DispPart_no,b1.ViewRevision as DispRevision,b1.Part_sourc,b1.Part_class,b1.Part_type
						,b1.Descript,b1.U_of_meas,b1.UNIQ_KEY,invtmfgr.w_key,warehous.WAREHOUSE,invtmfgr.location,b1.PARTMFGR,b1.MFGR_PT_NO

						,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap+ round((((B1.Qty * @lcQty)*B1.Scrap)/100),0) 
							else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap 
								else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*@lcQty) + round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)
									else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*@lcQty) end end end end as Req_Qty
						,CASE when @lcUniq_key =  B1.BomParent THEN ' ' ELSE 'f' end as Phantom
						,CAST(0.00 as numeric(5,2)) as Act_qty,b1.Dept_id,depts.DEPT_NAME,b1.scrap,b1.SetupScrap,b1.bomParent
						,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)* @lcQty)+b1.SetupScrap+ round((((B1.Qty * @lcQty)*B1.Scrap)/100),0) 
							else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)* @lcQty)+b1.SetupScrap 
								else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)* @lcQty) + round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)
									else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)* @lcQty) end end end end as ShortQty
						,b1.TopQty*b1.qty as Qty,b1.PART_NO,b1.CustPartNo,CAST(0 as bit) as Ignorekit
						,CAST (0 as bit) as Phant_make,b1.Revision,b1.MatlType,b1.CustRev,invtmfgr.QTY_OH
						,Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved,case when (antiavl.PARTMFGR is null) then 'A' else '' end as antiAVL
						,b1.MfgrMatlType,b1.ORDERPREF,b1.UNIQMFGRHD
						,case when @lcUniq_key = B1.bomparent then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn
					
				from	BomWithAvl as B1
						inner join INVENTOR as I4 on i4.UNIQ_KEY=@lcUniq_key		--12/18/15 DRP:  --inner join INVENTOR as I4 on right(left(b1.path,11),10) = i4.UNIQ_KEY
						left outer join DEPTS on b1.Dept_id = depts.DEPT_ID
						-- 4/25/18 Rajendra K : Repaced invtmfhd table with 2 new tables
						--inner join invtmfhd MH on b1.uniq_key=mh.uniq_key and B1.PARTMFGR = mh.PARTMFGR AND B1.MFGR_PT_NO = mh.MFGR_PT_NO and mh.IS_DELETED=0	--12/18/15 DRP:  added
						INNER JOIN (select Uniq_key,Uniqmfgrhd,PARTMFGR ,MFGR_PT_NO,L.ORDERPREF ,M.MATLTYPEVALUE 
												FROM Mfgrmaster M inner join invtmpnlink L on M.mfgrmasterid=L.mfgrmasterid where m.is_deleted=0 and L.is_deleted=0) MH
												ON b1.uniq_key=mh.uniq_key and B1.PARTMFGR = mh.PARTMFGR AND B1.MFGR_PT_NO = mh.MFGR_PT_NO
						inner join INVTMFGR on mh.uniqmfgrhd = invtmfgr.uniqmfgrhd
						inner join warehous on invtmfgr.uniqwh = warehous.uniqwh 
						left outer join ANTIAVL on B1.Bomparent = ANTIAVL.BOMPARENT and b1.Uniq_key = ANTIAVL.UNIQ_KEY and b1.PARTMFGR = ANTIAVL.PARTMFGR and b1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO
						left outer join INVENTOR as I3 on b1.BomParent = I3.UNIQ_KEY
					
				where	B1.part_sourc <> 'PHANTOM'
						AND B1.Phantom_make <> 1
						and (@lcUniqWh = 'All' OR warehous.uniqwh IN (select Uniqwh from @uniqWh )) -- 6/20/18 Rajendra K : Added condition for Warehouse filter
						--right(left(b1.path,11),10) = @lcUniq_key	--12/15/15 DRP:  removed because we already select above with the @lcUniq_key

			select R2.* from @results as R2

			end