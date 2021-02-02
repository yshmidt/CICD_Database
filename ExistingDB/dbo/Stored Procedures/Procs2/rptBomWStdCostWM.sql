
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
-- 08/27/15 VL changed StdCostper1Build from numeric(14,6) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
--					10/19/15 DRP:  needed to change "LeadTime numeric (3)" to be "LeadTime numeric" otherwise it was causing a numeric overflow on some datasets (within "declare @BOM table")
-- 					2/24/17	Vijay G: Added column @BOM.Qty_each numeric(12,2). Also increase TopStdCost numeric (14,6) to TopStdCost numeric (20,5)
-- 05/22/17 YS Vicky updated return table from [fn_PhantomSubSelect], but have not updated this SP to match
--- 08/09/17 YS functional currency changes
-- 08/16/17 DRP:  added StdCostPR to the results it was missed on 08/09
-- 05/30/19 VL added CutSheet
-- 10/11/19 VL changed part_no from char(25) to char(35)
-- =============================================
	CREATE PROCEDURE [dbo].[rptBomWStdCostWM] 

--declare	
		@lcUniqBomParent varchar(max)= null			--top Bom Parent Product #'s Uniq_key
		,@sortBy char(35)='Item Number'				--Item Number, Part Number or Descending Extended Cost
		,@userID uniqueidentifier = null
		,@lcStatus char(8) = 'Active'
		
		
as
begin


-- 10/11/19 VL changed part_no from char(25) to char(35)
DECLARE @t TABLE	(ParentPartNo CHAR (35),ParentRev CHAR(8),Parent_Desc char (45),ParentUniqkey CHAR (10),ParentMatlType char(10),ParentBomCustNo char(10)
					,ParentCustName char(35),PUseSetScrap bit,PStdBldQty numeric(8),LaborCost numeric (14,6),Bom_Note text)	
		
INSERT @T	select	part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''),USESETSCRP,STDBLDQTY,LABORCOST, bom_note
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
	--05/22/17 YS table returned by [fn_PhantomSubSelect] was updated	
	-- 05/30/19 VL added CutSheet varchar(max)	
	declare @BOM table (Item_no char(10),Part_no char(35),Revision char(8),Custpartno char (35),Custrev char (8),Part_class char(8),Part_type char(8),Descript char(45),
			Qty numeric(9,2),Scrap_qty numeric(9,2),StdCostper1Build numeric(29,5),Scrap_Cost numeric (14,6),SetupScrap_Cost numeric(14,6),sort varchar(max),Bomparent char(10)
			,Uniq_key char(10),Dept_id char(8),Item_note text,Offset bit,Term_dt smalldatetime,Eff_dt smalldatetime,Custno char(10),U_of_meas char (4),Inv_note text
			,Part_sourc char(10),Perpanel numeric(4),Used_inkit char(1),Scrap numeric (6,2),Setupscrap numeric (4),UniqBomNo char(10),Buyer_type char(3),StdCost numeric(13,5)
			,Phant_make bit,Make_buy bit,MatlType char(10),TopStdCost numeric (20,5),LeadTime numeric,UseSetScrp bit,SerialYes bit,StdBldQty numeric (8),Level Integer
			, Status char(8),Qty_each numeric(12,2),ReqQty numeric (14,6),
			-- 05/22/17 YS table returned by [fn_PhantomSubSelect] was updated
			StdCostper1BuildPR numeric(29,5), Scrap_CostPR numeric(14,6), SetupScrap_CostPR numeric(14,6), StdCostPR numeric(13,5), TopStdCostPR numeric(14,6)
			-- 05/30/19 VL added CutSheet varchar(max)
			, CutSheet varchar(max), nId int Identity)

	-- 02/17/15 VL added 10th parameter
	--insert @BOM select * FROM [dbo].[fn_PhantomSubSelect] (@lcBomParent , 1, 'T', GETDATE(), 'F', 'T', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no	--05/13/2015 DRP: replaced by below
-- 05/30/19 VL added Cut Sheet, so need to list all fields 
	DECLARE @lnTotalCnt int, @lnCnt int, @UniqBomno char(10), @output varchar(max)
	
	--insert @BOM select * FROM [dbo].[fn_PhantomSubSelect] (@lcBomParent , 1, 'T', GETDATE(), 'F', 'All', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no
	insert @BOM (Item_no,Part_no,Revision,Custpartno,Custrev,Part_class,Part_type,Descript,Qty,Scrap_qty,StdCostper1Build,Scrap_Cost,SetupScrap_Cost,sort,Bomparent
			,Uniq_key,Dept_id,Item_note,Offset,Term_dt,Eff_dt,Custno,U_of_meas,Inv_note,Part_sourc,Perpanel,Used_inkit,Scrap,Setupscrap,UniqBomNo,Buyer_type,StdCost
			,Phant_make,Make_buy,MatlType,TopStdCost,LeadTime,UseSetScrp,SerialYes,StdBldQty,Level,Status,Qty_each,ReqQty,StdCostper1BuildPR, Scrap_CostPR, SetupScrap_CostPR, StdCostPR, TopStdCostPR)
		SELECT * FROM [dbo].[fn_PhantomSubSelect] (@lcBomParent , 1, 'T', GETDATE(), 'F', 'All', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no

			-- @cTopUniq_key - the top BOM parent uniq_key
			-- @nNeedQty - Required qty
			-- @cChkDate - Need to check date or not -- 'T' or 'F'
			-- @dDate - The WO due date
			-- @cMake - Want to explore MAKE part or not -- 'T' or 'F'
			-- @cKitInUse - Kit in use or not -- 'T' or 'F' or 'ALL'
			-- @cMakeBuy - if need to explore Make_Buy
			-- @lIgnoreScrap - calculate scrap or not, kit, costroll, MRP calculation can ignore scrap
			-- @lLeaveParentPart - Filter out the parent part numbers from the record set or not

	-- 05/30/19 VL added Cut Sheet
	SELECT @lnTotalCnt = @@ROWCOUNT
	SELECT @lnCnt = 0

	IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'udtBOM_Details')
	BEGIN
		WHILE @lnCnt < @lnTotalCnt
		BEGIN
			SELECT @lnCnt = @lnCnt + 1
			SELECT @UniqBomno = UniqBomno FROM @Bom WHERE nId = @lnCnt
			EXEC GetBomDetCutSheet @uniqBomno, @output OUTPUT
			UPDATE @Bom SET CutSheet = @output WHERE nId = @lnCnt
	
		END
	END
	-- 05/30/19 VL End}		

	-- 02/17/15 VL added Status field	
	---08/09/17 YS insert datainto #tResult and select from #tResult at the end to separate function from none functional values
	---08/09/17 YS follow Debbie's suggestion to create a result table and use it at the end to select appropriate columns
	--- use temp table 
	if OBJECT_ID('tempdb..#tResult') is not null
	drop table #tResult;

	select	B1.Item_no,B1.Part_no,B1.Revision,B1.Custpartno,B1.Custrev,B1.Part_class,B1.Part_type,B1.Descript,B1.Qty,B1.Scrap_qty
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.StdCostper1Build END AS StdCostper1Build  --,B1.StdCostper1Build
			,CASE WHEN B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.Qty+B1.Scrap_qty END AS QtyWScrap   	-- 06/25/2014 DRP Added
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.SetupScrap_Cost END AS SetupScrap_cost  --,B1.SetupScrap_Cost
			,case when b1.Phant_make = 1 OR b1.part_sourc = 'PHANTOM' then 0.00 else b1.Scrap_Cost end as Scrap_Cost		--,B1.Scrap_Cost
			---08/09/17 added presentatio values
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.StdCostper1BuildPr END AS StdCostper1BuildPr  --,B1.StdCostper1Buildpr
			,case when B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.SetupScrap_CostPr END AS SetupScrap_costPr  --,B1.SetupScrap_Costpr
			,case when b1.Phant_make = 1 OR b1.part_sourc = 'PHANTOM' then 0.00 else b1.Scrap_CostPr end as Scrap_CostPr		--,B1.Scrap_CostPr
			,CASE WHEN B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.TopStdCostPr END AS TopStdCostPr  --B1.TopStdCostpr
			,B1.Dept_id,B1.Item_note,B1.Term_dt,B1.Eff_dt,B1.Custno,B1.U_of_meas,B1.Inv_note,B1.Part_sourc
			,B1.Perpanel,B1.Used_inkit,B1.Scrap,B1.Setupscrap,B1.Buyer_type,B1.StdCost
			,B1.StdCostPR	--08/16/17 DRP:  added
			,B1.Phant_make,B1.Make_buy,B1.MatlType
			,CASE WHEN B1.Phant_make = 1 or B1.Part_sourc = 'PHANTOM' then 0.00 else B1.TopStdCost END AS TopStdCost  --,B1.TopStdCost
			,B1.LeadTime,B1.UseSetScrp,B1.SerialYes,B1.StdBldQty,B1.Level,B1.ReqQty,t2.*,depts.DEPT_NAME
			,case when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'
				when i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom' 
				 when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource
			,case when t2.ParentUniqKey = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) end as SubParent
			,B1.sort,B1.Bomparent,B1.Uniq_key,B1.Offset,B1.UniqBomNo, B1.Status,
			--08/09/17 added currency symbol
			ISNULL(ff.Symbol,space(3)) as funcCurr,ISNULL(pf.Symbol,space(3)) as prCurr
			-- 05/30/19 VL added Cut Sheet
			,B1.CutSheet
			INTO #tResults
	from	@BOM as B1
			---08/09/17 YS I am not seeing the reason to use left outer join instead of inner join here
			INNER join INVENTOR I3 on B1.UNIQ_KEY = i3.UNIQ_KEY
			INNER join INVENTOR i4 on b1.Bomparent = I4.UNIQ_KEY
			left outer join depts on b1.Dept_id = depts.DEPT_ID
			cross join @t T2 
			--cross join MICSSYS
			OUTER APPLY (select FcUsed_Uniq,symbol from fcused where fcused.FcUsed_Uniq=i4.FUNCFCUSED_UNIQ) FF
			OUTER APPLY (select FcUsed_Uniq,symbol from fcused where fcused.FcUsed_Uniq=i4.PRFCUSED_UNIQ) PF

/*
None FC installation
*/
IF dbo.fn_IsFCInstalled() = 0
	select	Item_no,Part_no,Revision,Custpartno,Custrev,Part_class,Part_type,Descript,Qty,Scrap_qty,
			 StdCostper1Build  --,B1.StdCostper1Build
			,QtyWScrap   	-- 06/25/2014 DRP Added
			,SetupScrap_cost  --,B1.SetupScrap_Cost
			,Scrap_Cost		--,Scrap_Cost
			,Dept_id,Item_note,Term_dt,Eff_dt,Custno,U_of_meas,Inv_note,Part_sourc
			,Perpanel,Used_inkit,Scrap,Setupscrap,Buyer_type,StdCost,Phant_make,Make_buy,MatlType
			,TopStdCost  --,TopStdCost
			,LeadTime,UseSetScrp,SerialYes,StdBldQty,Level,ReqQty,
			ParentPartNo,ParentRev ,Parent_Desc ,ParentUniqkey,ParentMatlType ,ParentBomCustNo --- columns from @t
			,ParentCustName ,PUseSetScrap,PStdBldQty,LaborCost ,Bom_Note --- columns from @t
			DEPT_NAME
			,MbPhSource
			,SubParent
			,sort,Bomparent,Uniq_key,Offset,UniqBomNo, [Status]
			-- 05/30/19 VL added Cut Sheet
			,CutSheet
	FROM #tResults
	ORDER BY 
	CASE @sortBy WHEN 'Item Number' THEN SORT END,
	CASE @sortBy WHEN 'Part Number' THEN Part_no END,
	case @sortBy when 'Descending Extended Cost' then case when Phant_make = 1 OR part_sourc = 'PHANTOM' then 0.00 else Scrap_Cost end else Scrap_Cost end desc
	

ELSE
		
/*
FC installation
*/
	select 	* from #tResults
	ORDER BY 
	CASE @sortBy WHEN 'Item Number' THEN SORT END,
	CASE @sortBy WHEN 'Part Number' THEN Part_no END,
	case @sortBy when 'Descending Extended Cost' then case when Phant_make = 1 OR part_sourc = 'PHANTOM' then 0.00 else Scrap_Cost end else Scrap_Cost end desc
	
	-- drop the temp table
	if OBJECT_ID('tempdb..#tResult') is not null
	drop table #tResult;		
				
			
end