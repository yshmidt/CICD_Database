
-- =============================================
-- Author:		Debbie
-- Create date: 01/06/2014
-- Description:	Created for the Bill of Material with Alternate Part Numbers
-- Reports Using Stored Procedure:  bomrpt8
-- Modifications:
--					02/17/15	VL:	Added 10th parameter to fn_PhantomSubSelect() to get inactive parts or no
--					05/13/2015 DRP:  customer reported that the items marked as Floor Stock Used in Kit = "F" where not being displayed on the report results.  Upon review found that it was due to the changes made on 02/17/2015 VL 
--									 I changed the section that inserts into the @BOM from the [dbo].[fn_PhantomSubSelect] . . by changing the @cKitInUse from "T" to "All"
--					08/27/15	VL: changed StdCostper1Build from numeric(14,6) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
--									also increase @BOM.qty length from numeric(9,2) to numeric(12,2) like Kamain.Qty
--					02/24/17     Vijay G. : Added column @BOM.Qty_each numeric(12,2) and also increase TopStdCost numeric (14,6) length from numeric(14,6) to numeric(20,5). Also increase LeadTime numeric (3) length to numeric(5)
-- 05/22/17 YS Vicky updated return table from [fn_PhantomSubSelect], but have not updated this SP to match
-- =============================================
CREATE PROCEDURE [dbo].[rptBomwAltPart] 

 @lcUniqkey AS char(10) = ''			-- This is the Uniq_key for the Product that the users selects on screen within WebManex
 , @userId uniqueidentifier=null
 , @lcStatus char(8) = 'Active'
		
		
	
as
begin

	DECLARE @t TABLE(ParentPartNo CHAR (25),ParentRev CHAR(8),Parent_Desc char (45),ParentUniqkey CHAR (10),ParentMatlType char(10),ParentBomCustNo char(10)
					,ParentCustName char(35),PUseSetScrap bit,PStdBldQty numeric(8),LaborCost numeric (14,6),Bom_Note text)	
			
		INSERT @T	select part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''),USESETSCRP,STDBLDQTY,LABORCOST, bom_note
					from inventor 
					left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO 
					where uniq_key = @lcUniqkey AND PART_SOURC <> 'CONSG'
		
	-- 02/17/15 VL added Status field		
	-- 05/22/17 YS Vicky updated return table from [fn_PhantomSubSelect], but have not updated this SP to match				
	declare @BOM table (Item_no char(10),Part_no char(35),Revision char(8),Custpartno char (35),Custrev char (8),Part_class char(8),Part_type char(8),Descript char(45),
			Qty numeric(12,2),Scrap_qty numeric(9,2),StdCostper1Build numeric(29,5),Scrap_Cost numeric (14,6),SetupScrap_Cost numeric(14,6),sort varchar(max),Bomparent char(10),Uniq_key char(10),Dept_id char(8)
			,Item_note text,Offset bit,Term_dt smalldatetime,Eff_dt smalldatetime,Custno char(10),U_of_meas char (4),Inv_note text,Part_sourc char(10),Perpanel numeric(4),Used_inkit char(1)
			,Scrap numeric (6,2),Setupscrap numeric (4),UniqBomNo char(10),Buyer_type char(3),StdCost numeric(13,5),Phant_make bit,Make_buy bit,MatlType char(10)
			,TopStdCost numeric (20,5),LeadTime numeric (5),UseSetScrp bit,SerialYes bit,StdBldQty numeric (8),Level Integer, Status char(8),Qty_each numeric(12,2), ReqQty numeric (14,6),
			StdCostper1BuildPR numeric(29,5), Scrap_CostPR numeric(14,6), SetupScrap_CostPR numeric(14,6), StdCostPR numeric(13,5), TopStdCostPR numeric(14,6)
			)

	-- 02/17/15 VL added 10th paramete to get inactive parts or not
	--insert @BOM select * FROM [dbo].[fn_PhantomSubSelect] (@lcUniqkey , 1, 'T', GETDATE(), 'F', 'T', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no	--05/13/2015 DRP: replaced by below
		insert @BOM select * FROM [dbo].[fn_PhantomSubSelect] (@lcUniqkey , 1, 'T', GETDATE(), 'F', 'All', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no
			-- @cTopUniq_key - the top BOM parent uniq_key
			-- @nNeedQty - Required qty
			-- @cChkDate - Need to check date or not -- 'T' or 'F'
			-- @dDate - The WO due date
			-- @cMake - Want to explore MAKE part or not -- 'T' or 'F'
			-- @cKitInUse - Kit in use or not -- 'T' or 'F' or 'ALL'
			-- @cMakeBuy - if need to explore Make_Buy
			-- @lIgnoreScrap - calculate scrap or not, kit, costroll, MRP calculation can ignore scrap
			-- @lLeaveParentPart - Filter out the parent part numbers from the record set or not
			-- @lGetInactivePart - Include inactive parts

	-- 02/17/15 VL added Status field
	select	b1.Item_no,b1.Part_no,b1.Revision,b1.Custpartno,b1.Custrev,b1.Part_class,b1.Part_type,b1.Descript,b1.Qty
			,case when ISNULL(i5.part_no,'') <> '' then CAST(1 as bit) else CAST(0 as bit) end as Alt
			,ISNULL(i5.part_sourc,'')as AltSource,case when i5.part_sourc = 'CONSG' then ISNULL(i5.custpartno,'') else isnull(i5.PART_NO,'') end as AltPartNo
			,case when i5.part_sourc = 'CONSG' THEN ISNULL(I5.CUSTREV,'') ELSE isnull(i5.REVISION,'') END as AltRev,isnull(i5.MATLTYPE,'') as AltMatlType
			,isnull(i5.PART_CLASS,'') as AltClass,ISNULL(i5.part_type,'')as AltType,ISNULL(i5.DESCRIPT,'') as AltDesc
			,b1.sort,b1.Bomparent,b1.Uniq_key,b1.term_dt,b1.eff_dt,b1.Custno,b1.U_of_meas,b1.Part_sourc,b1.Used_inkit
			,b1.UniqBomNo,b1.Phant_make,b1.Make_buy,b1.MatlType,b1.Level,t2.ParentPartNo,t2.ParentRev,t2.Parent_Desc
			,t2.ParentUniqkey,t2.ParentMatlType,t2.ParentBomCustNo,t2.ParentCustName
			,case when I3.UNIQ_KEY <> @lcUniqkey and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'
				when i3.UNIQ_KEY <> @lcUniqkey and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom' 
				 when I3.UNIQ_KEY <> @lcUniqkey and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource
			,case when t2.ParentUniqKey = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) end as SubParent, B1.Status

	from	@BOM as B1
			left outer join INVENTOR I3 on B1.UNIQ_KEY = i3.UNIQ_KEY
			left outer join INVENTOR i4 on b1.Bomparent = I4.UNIQ_KEY
			left outer join depts on b1.Dept_id = depts.DEPT_ID
			cross join @t T2 
			left outer join BOM_ALT on b1.UNIQ_KEY = BOM_ALT.ALT_FOR and b1.Bomparent = BOM_ALT.BOMPARENT
			left outer join INVENTOR I5 on BOM_ALT.UNIQ_KEY = i5.UNIQ_KEY
			
			
end