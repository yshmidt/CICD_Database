
-- =============================================
-- Author:		Debbie
-- Create date: 08/20/2012
-- Description:	Created for the Bill of Material with Standard Cost
-- Reports Using Stored Procedure:  bomrpt4a.rpt 
-- Modifications:	09/21/2012 DRP:  I needed to increase the Descript Char from (40) to (45), it was causing truncation error on the reports when the Description field was max'd out. 
--					02/17/2015 VL:	 Added 10th parameter to fn_phantomsubselect to show inactive part or not
--					05/13/2015 DRP:  customer reported that the items marked as Floor Stock Used in Kit = "F" where not being displayed on the report results.  Upon review found that it was due to the changes made on 02/17/2015 VL 
--									 I changed the section that inserts into the @BOM from the [dbo].[fn_PhantomSubSelect] . . by changing the @cKitInUse from "T" to "All"
--					08/27/2015	VL:	 changed StdCostper1Build from numeric(14,6) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
--- 06/13/18 YS PhantomSubSelect function was changed. I will use temp table in place of @BOM table variable, avoiding the errors 
-- 10/11/19 VL changed part_no from char(25) to char(35)
-- =============================================
		CREATE PROCEDURE [dbo].[rptBomWStdCost]
				-- 10/11/19 VL changed part_no from char(25) to char(35)
				@lcProd varchar(35) = ''
				,@lcRev char(8) = ''
				,@lcStatus char(8) = 'Active'
				
			-- Parameters:
			-- @lcProd - the top BOM parent Product #
			-- @lcRev - the Bom Parent Revision
				
			
		as
		begin
		-- 10/11/19 VL changed part_no from char(25) to char(35)
		DECLARE @t TABLE(ParentPartNo CHAR (35),ParentRev CHAR(8),Parent_Desc char (45),ParentUniqkey CHAR (10),ParentMatlType char(10),ParentBomCustNo char(10)
						,ParentCustName char(35),PUseSetScrap bit,PStdBldQty numeric(8),LaborCost numeric (14,6),Bom_Note text)	
				
			INSERT @T	select part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''),USESETSCRP,STDBLDQTY,LABORCOST, bom_note
						from inventor 
						left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO 
						where part_no = @lcProd and REVISION = @lcRev AND PART_SOURC <> 'CONSG'
						
						
		--I am declaring the below parameter so I can populate it with the Products uniq_key and then use it to pull the information fwd from the Function (fn_phantomSubSelect)		
			declare		@lcBomParent char(10) 
		--populat the parameter with the uniq_key for the parent bom 				
			select  @lcBomParent = t1.ParentUniqKey from @t as t1

		-- <<09/21/2012 DRP:  increased the descript char from (40) to (45)	
		-- 02/17/15 VL added Status field				
		--06/13/18 YS use temp table
		--declare @BOM table (Item_no char(10),Part_no char(35),Revision char(8),Custpartno char (35),Custrev char (8),Part_class char(8),Part_type char(8),Descript char(45),
		--		Qty numeric(9,2),Scrap_qty numeric(9,2),StdCostper1Build numeric(29,5),Scrap_Cost numeric (14,6),SetupScrap_Cost numeric(14,6),sort varchar(max),Bomparent char(10),Uniq_key char(10),Dept_id char(8)
		--		,Item_note text,Offset bit,Term_dt smalldatetime,Eff_dt smalldatetime,Custno char(10),U_of_meas char (4),Inv_note text,Part_sourc char(10),Perpanel numeric(4),Used_inkit char(1)
		--		,Scrap numeric (6,2),Setupscrap numeric (4),UniqBomNo char(10),Buyer_type char(3),StdCost numeric(13,5),Phant_make bit,Make_buy bit,MatlType char(10)
		--		,TopStdCost numeric (14,6),LeadTime numeric (3),UseSetScrp bit,SerialYes bit,StdBldQty numeric (8),Level Integer, Status char(8), ReqQty numeric (14,6))

		if object_ID('tempdb..#tBomFromPhant') is not null
		drop table #tBomFromPhant

		-- 02/17/15 VL added 10th parameter
		--insert @BOM select * FROM [dbo].[fn_PhantomSubSelect] (@lcBomParent , 1, 'T', GETDATE(), 'F', 'T', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no	--05/13/2015 DRP: replaced by below
		--06/13/18 YS use temp table
		--insert @BOM select * 
		select *
		INTO #tBomFromPhant
		FROM [dbo].[fn_PhantomSubSelect] 
		(@lcBomParent , 1, 'T', GETDATE(), 'F', 'All', 'T', 0, 1, CASE WHEN @lcStatus = 'Active' THEN 0 ELSE 1 END) order by Item_no
		
			-- @cTopUniq_key - the top BOM parent uniq_key
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
		select	B1.*,t2.*,depts.DEPT_NAME
				,case when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'
					when i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom' 
					 when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource
				,case when t2.ParentUniqKey = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) end as SubParent, B1.Status, MICSSYS.LIC_NAME
		from	#tBomFromPhant as B1
				left outer join INVENTOR I3 on B1.UNIQ_KEY = i3.UNIQ_KEY
				left outer join INVENTOR i4 on b1.Bomparent = I4.UNIQ_KEY
				left outer join depts on b1.Dept_id = depts.DEPT_ID
				cross join @t T2 
				cross join MICSSYS
				
		
		if object_ID('tempdb..#tBomFromPhant') is not null
		drop table #tBomFromPhant
		end