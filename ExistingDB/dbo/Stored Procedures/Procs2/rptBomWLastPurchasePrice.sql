
-- =============================================
-- Author:		Debbie
-- Create date: 08/20/2012
-- Description:	Created for the Bill of Material with Standard Cost
-- Reports Using Stored Procedure:  bomrpt4a, bomrpt4b, bomrpt4c 
-- Modifications:	09/21/2012 DRP:  I needed to increase the Descript Char from (40) to (45), it was causing truncation error on the reports when the Description field was max'd out. 
--					06/24/2014 DRP:  created this procedure so that it would work better with the WebManex Parameters.   Changed the Parameter to be the Uniq_key
--								 Added @sortby and the Order at the end so the users can control the sort order of the quick views
--								 replaced the following (B1.StdCostper1Build, B1.SetupScrap_Cost,B1.Scrap_Cost,B1.TopStdCost) with case statements so if they are phantoms it will properly display 0.00 as the value. 
--					02/17/2015 VL:	 Added 10th parameter to fn_phantomsubselect to show inactive part or not
--					05/13/2015 DRP:  customer reported that the items marked as Floor Stock Used in Kit = "F" where not being displayed on the report results.  Upon review found that it was due to the changes made on 02/17/2015 VL 
--									 I changed the section that inserts into the @BOM from the [dbo].[fn_PhantomSubSelect] . . by changing the @cKitInUse from "T" to "All"
--- 06/05/15 Avinash - created new SP based on the rptBomwithstdcost, calling new [fn_phantomSubSelectWLastPurchasePrice]
-- 06/05/15 YS modified
-- 02/24/17 Vijay G: Increase the LeadTime numeric (3) to LeadTime numeric (5)
--08/14/17 YS added PR, func values. This report is not fully usable, but I think no one is using it now when FC is on. Need to finish it and andd currency symbol. Also function return part number
--- not sure why we need to connect to all the inventory again. No time to answer all these ?
-- =============================================
	CREATE PROCEDURE [dbo].[rptBomWLastPurchasePrice]

--declare	
		@lcUniqBomParent varchar(max)= null			--top Bom Parent Product #'s Uniq_key
		,@sortBy char(35)='Item Number'				--Item Number, Part Number or Descending Extended Cost
		,@userID uniqueidentifier = null
		,@lcStatus char(8) = 'Active'
		
		
as
begin



DECLARE @t TABLE	(ParentPartNo CHAR (25),ParentRev CHAR(8),Parent_Desc char (45),ParentUniqkey CHAR (10),ParentMatlType char(10),ParentBomCustNo char(10)
					,ParentCustName char(35),PUseSetScrap bit,PStdBldQty numeric(8),LaborCost numeric (14,6),Bom_Note nvarchar(max),
					LaborCostPR Numeric(14,6),funcfcused_uniq char(10),prfcused_uniq char(10))		
		
---08/14/17 YS added FC values		
INSERT @T	select	part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''),USESETSCRP,STDBLDQTY,LABORCOST, bom_note,LaborCostPr,
					funcfcused_uniq,prfcused_uniq
			from	inventor 
					left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO 
			where	UNIQ_KEY = @lcUniqBomParent
					and PART_SOURC <> 'CONSG'	
					
					
--I am declaring the below parameter so I can populate it with the Products uniq_key and then use it to pull the information fwd from the Function (fn_phantomSubSelect)		
	declare		@lcBomParent char(10) 
--populat the parameter with the uniq_key for the parent bom 				
	select  @lcBomParent = t1.ParentUniqKey from @t as t1

	-- <<09/21/2012 DRP:  increased the descript char from (40) to (45)					
	-- 02/17/15 VL added Status field		
	--06/05/15 YS change any column with stdCost to LastPoCost
	--08/14/17 YS added columns for FC
	declare @BOM table (Item_no char(10),Part_no char(35),Revision char(8),Custpartno char (35),Custrev char (8),Part_class char(8),Part_type char(8),Descript char(45),
			Qty numeric(9,2),Scrap_qty numeric(9,2),LastPoCostper1Build numeric(14,6),Scrap_Cost numeric (14,6),SetupScrap_Cost numeric(14,6),sort varchar(max),Bomparent char(10)
			,Uniq_key char(10),Dept_id char(8),Item_note text,Offset bit,Term_dt smalldatetime,Eff_dt smalldatetime,Custno char(10),U_of_meas char (4),Inv_note text
			,Part_sourc char(10),Perpanel numeric(4),Used_inkit char(1),Scrap numeric (6,2),Setupscrap numeric (4),UniqBomNo char(10),Buyer_type char(3),LastPoCost numeric(13,5)
			,Phant_make bit,Make_buy bit,MatlType char(10),TopLastPoCost numeric (14,6),LeadTime numeric (5),UseSetScrp bit,SerialYes bit,StdBldQty numeric (8),Level Integer
			, Status char(8), ReqQty numeric (14,6),
			---08/14/17 YS added currency
			LastPoCostper1Buildpr numeric(14,6), Scrap_Costpr numeric(14,6), SetupScrap_CostPR numeric(14,6),TopLastPoCostpr numeric(14,6),costeachPr numeric(13,5)
			)

	-- 02/17/15 VL added 10th parameter
	--insert @BOM select * FROM [dbo].[fn_PhantomSubSelect] (@lcBomParent , 1, 'T', GETDATE(), 'F', 'T', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no	--05/13/2015 DRP: replaced by below
	insert @BOM select * FROM [dbo].[fn_phantomSubSelectWLastPurchasePrice] (@lcBomParent , 1, 'T', GETDATE(), 'F', 'All', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no
			-- @cTopUniq_key - the top BOM parent uniq_key
			-- @nNeedQty - Required qty
			-- @cChkDate - Need to check date or not -- 'T' or 'F'
			-- @dDate - The WO due date
			-- @cMake - Want to explore MAKE part or not -- 'T' or 'F'
			-- @cKitInUse - Kit in use or not -- 'T' or 'F' or 'ALL'
			-- @cMakeBuy - if need to explore Make_Buy
			-- @lIgnoreScrap - calculate scrap or not, kit, costroll, MRP calculation can ignore scrap
			-- @lLeaveParentPart - Filter out the parent part numbers from the record set or not

	-- 02/17/15 VL added Status field	
	--06/05/15 YS replace all stdcost with lastpocost

--08/14/17 split the result based on the FC setting
/*
None FC installation
*/
IF dbo.fn_IsFCInstalled() = 0

	select	B1.Item_no,B1.Part_no,B1.Revision,B1.Custpartno,B1.Custrev,B1.Part_class,B1.Part_type,B1.Descript,B1.Qty,B1.Scrap_qty
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.LastPoCostper1Build END AS LastPoCostper1Build  --,B1.LastPoCostper1Build
			,CASE WHEN B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.Qty+B1.Scrap_qty END AS QtyWScrap   	-- 06/25/2014 DRP Added
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.SetupScrap_Cost END AS SetupScrap_cost  --,B1.SetupScrap_Cost
			,case when b1.Phant_make = 1 OR b1.part_sourc = 'PHANTOM' then 0.00 else b1.Scrap_Cost end as Scrap_Cost		--,B1.Scrap_Cost
			,B1.Dept_id,B1.Item_note,B1.Term_dt,B1.Eff_dt,B1.Custno,B1.U_of_meas,B1.Inv_note,B1.Part_sourc
			,B1.Perpanel,B1.Used_inkit,B1.Scrap,B1.Setupscrap,B1.Buyer_type,B1.LastPoCost,B1.Phant_make,B1.Make_buy,B1.MatlType
			,CASE WHEN B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.TopLastPoCost END AS TopLastPoCost  --,B1.TopLastPoCost
			,B1.LeadTime,B1.UseSetScrp,B1.SerialYes,B1.StdBldQty,B1.Level,B1.ReqQty,t2.*,depts.DEPT_NAME
			,case when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'
				when i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom' 
				 when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource
			,case when t2.ParentUniqKey = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) end as SubParent
			,B1.sort,B1.Bomparent,B1.Uniq_key,B1.Offset,B1.UniqBomNo, B1.Status
	from	@BOM as B1
			left outer join INVENTOR I3 on B1.UNIQ_KEY = i3.UNIQ_KEY
			left outer join INVENTOR i4 on b1.Bomparent = I4.UNIQ_KEY
			left outer join depts on b1.Dept_id = depts.DEPT_ID
			cross join @t T2 
			cross join MICSSYS
	ORDER BY 
	CASE @sortBy WHEN 'Item Number' THEN SORT END,
	CASE @sortBy WHEN 'Part Number' THEN b1.Part_no END,
	case @sortBy when 'Descending Extended Cost' then case when b1.Phant_make = 1 OR b1.part_sourc = 'PHANTOM' then 0.00 else b1.Scrap_Cost end else Scrap_Cost end desc
ELSE --- dbo.fn_IsFCInstalled() = 1
	select	B1.Item_no,B1.Part_no,B1.Revision,B1.Custpartno,B1.Custrev,B1.Part_class,B1.Part_type,B1.Descript,B1.Qty,B1.Scrap_qty
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.LastPoCostper1Build END AS LastPoCostper1Build  --,B1.LastPoCostper1Build
			,CASE WHEN B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.Qty+B1.Scrap_qty END AS QtyWScrap   	-- 06/25/2014 DRP Added
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.SetupScrap_Cost END AS SetupScrap_cost  --,B1.SetupScrap_Cost
			,case when b1.Phant_make = 1 OR b1.part_sourc = 'PHANTOM' then 0.00 else b1.Scrap_Cost end as Scrap_Cost		--,B1.Scrap_Cost
			,B1.Dept_id,B1.Item_note,B1.Term_dt,B1.Eff_dt,B1.Custno,B1.U_of_meas,B1.Inv_note,B1.Part_sourc
			,B1.Perpanel,B1.Used_inkit,B1.Scrap,B1.Setupscrap,B1.Buyer_type,B1.LastPoCost,B1.Phant_make,B1.Make_buy,B1.MatlType
			,CASE WHEN B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.TopLastPoCost END AS TopLastPoCost  --,B1.TopLastPoCost
			,B1.LeadTime,B1.UseSetScrp,B1.SerialYes,B1.StdBldQty,B1.Level,B1.ReqQty,t2.*,depts.DEPT_NAME
			,case when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'
				when i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom' 
				 when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource
			,case when t2.ParentUniqKey = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) end as SubParent
			,B1.sort,B1.Bomparent,B1.Uniq_key,B1.Offset,B1.UniqBomNo, B1.Status,
			---08/14/17 YS added currency
			b1.LastPoCostper1Buildpr, b1.Scrap_Costpr, b1.SetupScrap_CostPR,b1.TopLastPoCostpr,costeachPr
	from	@BOM as B1
			left outer join INVENTOR I3 on B1.UNIQ_KEY = i3.UNIQ_KEY
			left outer join INVENTOR i4 on b1.Bomparent = I4.UNIQ_KEY
			left outer join depts on b1.Dept_id = depts.DEPT_ID
			cross join @t T2 
			--cross join MICSSYS
	ORDER BY 
	CASE @sortBy WHEN 'Item Number' THEN SORT END,
	CASE @sortBy WHEN 'Part Number' THEN b1.Part_no END,
	case @sortBy when 'Descending Extended Cost' then case when b1.Phant_make = 1 OR b1.part_sourc = 'PHANTOM' then 0.00 else b1.Scrap_Cost end else Scrap_Cost end desc
						
			
end