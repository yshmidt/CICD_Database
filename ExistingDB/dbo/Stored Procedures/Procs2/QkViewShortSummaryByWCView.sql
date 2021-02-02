
-- =============================================
	-- Author:			
	-- Create date:		
	-- Description:		Work Center Shortages QuickView
	-- Used On:			Work Center Shortages QuickView
	-- Modified:	09/30/2014 DRP:  with Yelena she discovered that most of the Selection statements used were not really needed and was slowing down the results.  we also had to make changes to how the Yeild was calculated. 
	--				04/27/2015 DRP:  the end users reported that the Work Center Shortage Quickview was not displaying any results.  Upon review I see that the Quick View existed on the Cloud but there were no parameters setup for it.  So it would not work with this procedure because Parameters are required
	--								 Added the /*DEPARTMENT LIST*/, changed the Parameter from @lcDept_id to be @lcDeptid to work with existing parameters already in the tables.  Changed the filter within the Where statements to work with the new Department List.  
	--				05/20/2016 DRP:  Added the /*CUSTOMER LIST*/, and then added the custname to the quickview results per request.  
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
-- 03/14/18 VL: removed using KitDef.lSuppressNotUsedInKit because user didn't want to see part was checked ignored (zendesk#1866)
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
	-- =============================================

CREATE PROCEDURE [dbo].[QkViewShortSummaryByWCView] 
--declare
@lcDeptid varchar(max) = 'All'
 , @userId uniqueidentifier=null

AS
BEGIN

/*DEPARTMENT LIST*/		
	DECLARE  @tDepts as tDepts
		DECLARE @Depts TABLE (dept_id char(4))
		-- get list of Departments for @userid with access
		INSERT INTO @tDepts (Dept_id,Dept_name,[Number]) EXEC DeptsView @userid ;
		--SELECT * FROM @tDepts	
		IF @lcDeptId is not null and @lcDeptId <>'' and @lcDeptId<>'All'
			insert into @Depts select * from dbo.[fn_simpleVarcharlistToTable](@lcDeptId,',') 
					where CAST (id as CHAR(4)) in (select Dept_id from @tDepts)
		ELSE

		IF  @lcDeptId='All'	
		BEGIN
			INSERT INTO @Depts SELECT Dept_id FROM @tDepts
		END


/*CUSTOMER LIST*/	--05/20/2016 DRP:  Added 	
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer


/*RECORD SELECTION SECTION*/
--05/20/2016 DRP:  added the custname 

SET NOCOUNT ON;

-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
DECLARE @lSuppressNotUsedInKit int
SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
	--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
	WHERE mnx.settingName='suppressNotUsedInKitItems'

SELECT ' ' AS Is_Misc,DEPT_ID, Kamain.Wono, CASE WHEN Part_sourc = 'CONSG' THEN CustPartno ELSE Part_no END AS Part_no,
	CASE WHEN Part_Sourc = 'CONSG' THEN CustRev ELSE Revision END AS Revision, 
	Part_class, Part_type, Descript, ShortQty, Kamain.Uniq_key,custname
	FROM Kamain, Inventor, Woentry,CUSTOMER 
	WHERE Kamain.Uniq_key = Inventor.Uniq_key 
	AND Kamain.Wono = Woentry.Wono 
	AND Woentry.Openclos <> 'Cancel'
	AND Woentry.OpenClos <> 'Closed'
	AND Woentry.Balance <> 0 
	AND Woentry.Kit = 1
	AND ShortQty > 0 
	--AND Kamain.Dept_id = @lcDeptid	--04/27/2015 DRP:  REPLACED WITH BELOW
	and (@lcDeptid='All' OR exists (select 1 from @Depts t where t.dept_id=kaMAIN.DEPT_ID))
	-- 03/14/18 VL: removed using KitDef.lSuppressNotUsedInKit because user didn't want to see part was checked ignored (zendesk#1866)
	-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
	AND IgnoreKit = 0
	--AND 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END
	and woentry.CUSTNO = customer.CUSTNO
	and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)
UNION ALL 
	(SELECT 'M' AS Is_Misc,DEPT_ID, miscmain.Wono, Part_no, Revision, Part_class, Part_type, Descript, ShortQty, SPACE(10) AS Uniq_key,custname 
	FROM	MiscMain
			inner join woentry on miscmain.wono = woentry.wono
			inner join customer on woentry.CUSTNO = customer.CUSTNO
	WHERE 
	--Dept_id = @lcDept_id	--04/27/2015 DRP:  REPLACED WITH BELOW
	 (@lcDeptid='All' OR exists (select 1 from @Depts t where t.dept_id=MISCMAIN.DEPT_ID))
	AND ShortQty > 0
	and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=woentry.custno)) 
	ORDER BY Wono,DEPT_ID

END