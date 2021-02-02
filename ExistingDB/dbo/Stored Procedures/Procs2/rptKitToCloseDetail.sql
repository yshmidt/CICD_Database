
-- =============================================
-- Author:			Debbie
-- Create date:		04/152013
-- Description:		Created for the Kit To Close Detail report.  Which will allow the users to see for a individual Work Order the detailed information that was compiled for the end Mfgr Variance cost
-- Reports:			
-- Modifications:   --- 03/28/17 YS changed length of the part_no column from 25 to 35	
-- 04/10/17 VL: Added functional currency code  
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 03/28/19 VL If the KIT is never put in proocess, then should not be apper in kit close report, filter out KitStauts=0 records.  Zendesk#3240
-- =============================================
 CREATE PROCEDURE [dbo].[rptKitToCloseDetail]

 @lcWoNo char(10) = ''
 ,@userId uniqueidentifier=null 

as 
Begin

SET @lcWono=dbo.PADL(@lcWono,10,'0')

DECLARE @nComplete AS numeric(7,0), @cWono AS char(10), @lnTotalNo int, @lnCount int, @nRollupCost numeric(20,7), @nIssuCost numeric(20,7),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35	
		-- 07/16/18 VL changed custname from char(35) to char(50)
		@cPart_no char(35), @cRevision char(8), @cDescript char(45), @dComplDate smalldatetime, @cCustName char(50), @cSono char(10),
		@cPart_class char(8), @cPart_type char(8),
		-- 04/10/17 VL: Added functional currency code  
		@nRollupCostPR numeric(20,7), @nIssuCostPR numeric(20,7)
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @WoNotCl as table	(nrecno int identity, wono char(10),complete numeric (13,0),Due_Date smalldatetime,SONO char(10),UNIQ_KEY char(10)
							,PART_NO char(35),REVISION char(8),DESCRIPT char(45),PART_CLASS char(8),PART_TYPE char(8),CUSTNAME char(50)
							,USESETSCRP bit,STDBLDQTY numeric(13,0),BLDQTY numeric(13,0))


--I created a table that will be populated with the info from the procedure
declare @RollupCost as table	(uniq_key Char(10),Part_sourc char (10),std_cost numeric (13,5),qty numeric(9,2),U_of_Meas char(4),Scrap numeric(6,2),SetupScrap numeric (4,0)
								,Phant_Make bit,UniqBomNo char(10),Ext_cost numeric(13,5),SetupScrap_Cost numeric(13,5),Ext_Cost_Total numeric (13,5),QtyReqTotal numeric(13,5),StdBldQty numeric (8,0)
								,Ext_CostWithoutCEILING numeric(13,5),QtyReqWithoutCEILING numeric (13,2),Ext_Cost_totalWithoutCEILING numeric(13,5),QtyReqTotalWithoutCEILING numeric(13,2),
								-- 04/07/17 VL added functional currency code
								StdCostPR numeric(13,5), Ext_costPR numeric(25,5), SetupScrap_CostPR numeric(12,5), Ext_cost_totalPR numeric(25,5), Ext_costWithoutCEILINGPR numeric(12,5), Ext_cost_totalWithoutCEILINGPR numeric(25,5));

-- 01/18/13 VL created issue cost cursor
-- 04/07/17 VL added functional currency code
DECLARE @IssueCost AS TABLE		(Uniq_key char(10), Qtyisu numeric(12,2), OldUnitCost numeric(13,5), OldCost numeric(20,7), NewUnitCost numeric(13,5), Part_Sourc char(10), NewCost numeric(20,7),
								OldUnitCostPR numeric(13,5), OldCostPR numeric(20,7), NewUnitCostPR numeric(13,5), NewCostPR numeric(20,7))

-- 07/16/18 VL changed custname from char(35) to char(50)
declare @Results as table	(wono char(10),complete numeric (13,0),Due_Date smalldatetime,SONO char(10),UNIQ_KEY char(10),PART_NO char(35),REVISION char(8),DESCRIPT char(45)
							,PART_CLASS char(8),PART_TYPE char(8),CUSTNAME char(50),USESETSCRP bit,STDBLDQTY numeric(13,0),BLDQTY numeric(13,0),RecType char(2))

declare @cUniq_key AS char(10) 
		, @dDue_Date AS smalldatetime
		, @nStdBldQty numeric (8,0) 
		, @nBldQty AS numeric(7,0)

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
			and @lcWoNo = wono


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


select	w1.Wono,w1.complete,w1.Part_no as ProdNo,W1.Revision as ProdRev,w1.DESCRIPT,w1.Custname,w1.USESETSCRP,w1.STDBLDQTY,w1.BLDQTY,CAST ('IssueCost' as CHAR (10)) as RecType
		,inventor.Part_no,inventor.Revision,I.Uniq_key,I.Part_sourc,Qtyisu as Qty,NewUnitCost as IssuedUnitCost,newcost as IssuedCost,cast (0.00 as numeric(15,2)) as BomCost
		,cast (0.00 as numeric(15,2)) as SetupScrap_cost,cast ('' as char(10)) as UniqBomNo,
		-- 04/07/17 VL added functional currency code 
		NewUnitCostPR as IssuedUnitCostPR,newcostPR as IssuedCostPR,cast (0.00 as numeric(15,2)) as BomCostPR, cast (0.00 as numeric(15,2)) as SetupScrap_costPR
from	@IssueCost as I	
		inner join INVENTOR on I.Uniq_key = inventor.UNIQ_KEY
		cross apply @WoNotCl as W1	

union all

select  w2.Wono,W2.complete,W2.Part_no as ProdNo,W2.Revision as ProdRev,w2.DESCRIPT,w2.Custname,w2.USESETSCRP,w2.STDBLDQTY,w2.BLDQTY,CAST ('BomCost' as CHAR (10)) as RecType
		,inventor.Part_no,inventor.Revision,R.Uniq_key,R.Part_sourc,Qty,cast (0.00 as numeric(15,2)) as IssuedUnitCost,cast (0.00 as numeric(15,2))  as IssuedCost 
		,R.Ext_Cost_totalWithoutCEILING as BomCost,R.SetupScrap_Cost,UniqBomNo,
		-- 04/07/17 VL added functional currency code 
		cast (0.00 as numeric(15,2)) as IssuedUnitCostPR,cast (0.00 as numeric(15,2))  as IssuedCostPR 
		,R.Ext_Cost_totalWithoutCEILINGPR as BomCostPR,R.SetupScrap_CostPR
from	@RollupCost as R 
		inner join INVENTOR on R.uniq_key = inventor.UNIQ_KEY
		cross apply @WoNotCl as W2

order by RecType,PART_NO
			
		end
		end
		end
end