
-- =============================================
-- Author:		Vicky & Debbie
-- Create date: 01/30/2013
-- Description:	Created for the Credit Memo Form
-- Reports:		kitnotcl.rpt
-- Modified:	02/19/2015 DRP:  needed to add isnull to the @nRollupCost and  @nIssuCost insert below.  otherwise if there were no issues found it would be null value and then the Mfgr Variance in the QuickView would not calculate a value when it should have. 
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 04/10/17 VL: Added functional currency code
-- 10/31/17 VL moved the next line to after END, so even no WO is found (@lnTotalNo>0), still has basic columns for the output (with 0 records), so the output to Excel won't get "Column out of range" error
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 03/28/19 VL If the KIT is never put in proocess, then should not be apper in kit close report, filter out KitStauts=0 records.  Zendesk#3240
-- =============================================
	CREATE PROCEDURE [dbo].[rptKitToClose]
	@userId uniqueidentifier = null

as 
begin			
			
DECLARE @nComplete AS numeric(7,0), @cWono AS char(10), @lnTotalNo int, @lnCount int, @nRollupCost numeric(20,7), @nIssuCost numeric(20,7),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35	
		-- 07/16/18 VL changed custname from char(35) to char(50)
		@cPart_no char(35), @cRevision char(8), @cDescript char(45), @dComplDate smalldatetime, @cCustName char(50), @cSono char(10),
		@cPart_class char(8), @cPart_type char(8),
		-- 04/10/17 VL added functional currency code
		@nRollupCostPR numeric(20,7), @nIssuCostPR numeric(20,7)

--=========GATHERING WORK ORDER INFORMATION========================================

--=========ATTEMPTING TO PULL IN DATA FROM THE sp_RollupCost=====================================
--Here is where I was attempting to declare the parameters that you used in the SP_RollupCost procedure
declare @cUniq_key AS char(10) 
		, @dDue_Date AS smalldatetime
		, @nStdBldQty numeric (8,0) 
		, @nBldQty AS numeric(7,0)
		
--- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @Kit2Close as table (wono char(10),part_no char(35),Revision char(8),Descript char(45),ComplDate smalldatetime,Complete numeric(7,0),IssueCost numeric(13,5)
							,BomCost numeric (13,5),MfgrVar numeric(13,5),CustName char(50),SoNo char(10),Part_class char(8),Part_type char(8),
							-- 04/10/17 VL added functional currency code
							IssueCostPR numeric(13,5), BomCostPR numeric (13,5),MfgrVarPR numeric(13,5))

--I created a table that will be populated with the info from the procedure
declare @RollupCost as table	(uniq_key Char(10),Part_sourc char (10),std_cost numeric (13,5),qty numeric(9,2),U_of_Meas char(4),Scrap numeric(6,2),SetupScrap numeric (4,0)
								,Phant_Make bit,UniqBomNo char(10),Ext_cost numeric(13,5),SetupScrap_Cost numeric(13,5),Ext_Cost_Total numeric (13,5),QtyReqTotal numeric(13,5),StdBldQty numeric (8,0)
								,Ext_CostWithoutCEILING numeric(13,5),QtyReqWithoutCEILING numeric (13,2),Ext_Cost_totalWithoutCEILING numeric(13,5),QtyReqTotalWithoutCEILING numeric(13,2),
								-- 04/10/17 VL added functional currency code
								StdCostPR numeric(13,5), Ext_costPR numeric(25,5), SetupScrap_CostPR numeric(12,5), Ext_cost_totalPR numeric(25,5), Ext_costWithoutCEILINGPR numeric(12,5), Ext_cost_totalWithoutCEILINGPR numeric(25,5));

-- 01/18/13 VL created issue cost cursor
DECLARE @IssueCost AS TABLE (Uniq_key char(10), Qtyisu numeric(12,2), OldUnitCost numeric(13,5), OldCost numeric(20,7), NewUnitCost numeric(13,5), Part_Sourc char(10), NewCost numeric(20,7),
-- 04/10/17 VL added functional currency code
OldUnitCostPR numeric(13,5), OldCostPR numeric(20,7), NewUnitCostPR numeric(13,5), NewCostPR numeric(20,7))

--Here I declared the below table to gather all of the work order information for the Closed WO's
-- 01/18/13 VL added nrecno for scan through the WO records
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @WoNotCl as table(nrecno int identity, wono char(10),complete numeric (13,0),Due_Date smalldatetime,SONO char(10),UNIQ_KEY char(10),PART_NO char(35),REVISION char(8),DESCRIPT char(45),PART_CLASS char(8)
		,PART_TYPE char(8),CUSTNAME char(50),USESETSCRP bit,STDBLDQTY numeric(13,0),BLDQTY numeric(13,0))


insert into @WoNotCl 							
	select	WOENTRY.WONO,WOENTRY.COMPLETE,WOENTRY.DUE_DATE,WOENTRY.SONO,INVENTOR.UNIQ_KEY,INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.DESCRIPT,INVENTOR.PART_CLASS
			,INVENTOR.PART_TYPE,CUSTOMER.CUSTNAME,INVENTOR.USESETSCRP,iNVENTOR.STDBLDQTY,WOENTRY.BLDQTY
	from	WOENTRY
			INNER JOIN INVENTOR ON WOENTRY.UNIQ_KEY = INVENTOR.UNIQ_KEY
			INNER JOIN CUSTOMER ON WOENTRY.CUSTNO = CUSTOMER.CUSTNO
	where	woentry.OPENCLOS = 'Closed'
			and woentry.KITSTATUS <> 'KIT CLOSED'
			-- 03/28/19 VL If the KIT is never put in proocess, then should not be apper in kit close report, filter out KitStauts=0 records.  Zendesk#3240
			AND KitStatus <> ''
--select * from @WoNotCl

-- 01/18/13 VL SCAN through the WO to calculate cost
SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		--below I was attempting to populate the parameter with the information from the @WoNotCl table above		
		SELECT @cUniq_key = Uniq_key, @dDue_Date = Due_Date, @nStdBldQty = STDBLDQTY,@nBldQty = BLDQTY, 
				@cWono = Wono, @nComplete = Complete, @cDescript = DESCRIPT, 
				@cCustName = CUSTNAME, @cSono = Sono, @cPart_class = Part_class, @cPart_type = Part_type, @cPart_no = PART_NO, @cRevision = Revision
			FROM @WoNotCl AS W1
			WHERE nrecno = @lnCount
		
		IF (@@ROWCOUNT<>0)
		BEGIN
			--delete all records if exist
			DELETE FROM @RollupCost WHERE 1=1
			DELETE FROM @IssueCost WHERE 1=1
			
			INSERT @RollupCost EXEC sp_RollupCost @cUniq_key, @dDue_Date,@nStdBldQty,@nBldQty
			INSERT @IssueCost EXEC sp_IssuUpCost_IncludeOverIsu @cWono
			
			-- 04/10/17 VL added functional currency code
			SELECT @nRollupCost = isnull(SUM(Ext_cost_total)+SUM(SetupScrap_Cost)*@nComplete,0.00),
					@nRollupCostPR = isnull(SUM(Ext_cost_totalPR)+SUM(SetupScrap_CostPR)*@nComplete,0.00) FROM @RollupCost		--02/19/2015 DRP:  added isnull to the formula
			-- 04/10/17 VL added functional currency code
			SELECT @nIssuCost = isnull(SUM(newCost),0.00),
					@nIssuCostPR = isnull(SUM(newCostPR),0.00) FROM @IssueCost												--02/19/2015 DRP:  added isnull to the formula
				

			INSERT INTO @Kit2Close (Wono, Part_no, Revision, Descript, Complete, IssueCost, BomCost, MfgrVar,
									CustName, SoNo, Part_class, Part_type,
									-- 04/10/17 VL added functional currency code
									IssueCostPR, BomCostPR, MfgrVarPR) 
				VALUES (@cWono, @cPart_no, @cRevision, @cDescript, @nComplete, @nIssuCost, @nRollupCost, @nIssuCost-@nRollupCost,
									@cCustName, @cSono, @cPart_class, @cPart_type,
									@nIssuCostPR, @nRollupCostPR, @nIssuCostPR-@nRollupCostPR)
		END
	END
	
	-- Has all information except ComplDate,
	;WITH ZComplDate AS
	(SELECT Transfer.Wono, MAX(DATE) AS ComplDate
		FROM TRANSFER, @WoNotCl ZWoNotCl
		WHERE Transfer.WONO = ZWoNotCl.Wono
		AND Transfer.TO_DEPT_ID = 'FGI'
		GROUP BY Transfer.WONO
	)
	UPDATE @Kit2Close
	SET ComplDate = ZComplDate.ComplDate
	FROM @Kit2Close K2, ZComplDate
	WHERE K2.Wono = ZComplDate.WONO
	
	-- You might want to change the order in other report
	-- 10/31/17 VL moved the next line to after END, so even no WO is found (@lnTotalNo>0), still has basic columns for the output (with 0 records), so the output to Excel won't get "Column out of range" error
	--SELECT k.*,micssys.LIC_NAME FROM @Kit2Close as K cross join MICSSYS ORDER BY Wono
END	
	SELECT k.*,micssys.LIC_NAME FROM @Kit2Close as K cross join MICSSYS ORDER BY Wono
end
					
					
					
	