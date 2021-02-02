-- =============================================
	-- Author:		Vicky/Debbie
	-- Create date: 03/11/2014
	-- Description:	This Stored Procedure was created for the Customer Consigned Shortage Summary Report
	-- Report:		shrtcnp 
	-- Modified:	09/01/15 DRP:  needed to change the <<AND Kd.AUDITDATE IN (SELECT MAX(AuditDate) FROM KADETAIL WHERE KASEQNUM = Kd.KASEQNUM))>>  to be <<and kd.SHQUALIFY='Add'>>  within the zKit section because otherwise it was duplicating some of the results. 
	--							   This change will cause the results of the report to not match VFP exactly.  In VFP we used to grae the Last Audit Date from the kadetail table for the Auditdate and shreason.  With the above changes it will just grab the Add date and that shreason.  
	--							   If the users later come back stating that the need the latest Audit Date then we will have to take the approach to first pull the kadetail and get the max Audit date then pull it again and only get the latest uniquerec record to get the exact shreason.  But this approach will slow the response time. 
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
-- =============================================
	CREATE PROCEDURE [dbo].[rptKitCustConsgShortageSummaryPN]

	@lcCustNo as varchar (max) = 'All'
	,@userid uniqueidentifier = null

as
begin

	/*comma seperator*/
	declare @Cust table(Custno char(10))
	if @lcCustNo is not null and @lcCustNo <> ''  and @lcCustNo <>'All'
		insert into @Cust select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')

-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
DECLARE @lSuppressNotUsedInKit int
SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)
	FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
	ON mnx.settingId = wm.settingId 
	-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
	--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
	WHERE mnx.settingName='suppressNotUsedInKitItems'	

	;WITH ZOpenWO AS (
		SELECT Wono, Woentry.Custno, CustName, Part_no AS Prod_no, Revision AS Prod_Rev, DESCRIPT AS Prod_Desc, 
			ISNULL(Pono, SPACE(20)) AS Pono, Woentry.Sono
			FROM CUSTOMER, INVENTOR, WOENTRY LEFT OUTER JOIN SOMAIN
			ON Woentry.SONO = Somain.Sono
			WHERE Woentry.CUSTNO = Customer.CUSTNO 
			AND Woentry.UNIQ_KEY = Inventor.UNIQ_KEY 
			AND LEFT(Woentry.OPENCLOS,1)<> 'C'
			and 1= CASE WHEN @lcCustNo = 'All' then 1 WHEN  Customer.CustNo IN (select Custno from @Cust ) then 1 ELSE 0 END)
			,
	ZKit AS (
		SELECT ZOpenWO.*, Part_no, Revision, CustPartNo, CustRev, Descript, Kamain.ShortQty, Part_class, Part_type, Auditdate, Shreason, 
			Qty, Part_Sourc, ISNULL(Dept_name, SPACE(25)) AS Dept_name, Kamain.UNIQ_KEY, Kamain.Dept_id, Kamain.KASEQNUM
			FROM ZOpenWO, Inventor, Kadetail AS Kd, KAMAIN LEFT OUTER JOIN DEPTS
			ON Kamain.DEPT_ID = Depts.DEPT_ID
			WHERE ZOpenWo.WONO = Kamain.WONO
			AND Kamain.UNIQ_KEY = Inventor.UNIQ_KEY 
			AND Kamain.SHORTQTY > 0
			-- 01/29/18 VL: Added to use KitDef.lSuppressNotUsedInKit to filter out IgnoreKit record
			--AND Kamain.IGNOREKIT = 0
			AND 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END
			AND PART_SOURC = 'CONSG' 
			AND Kd.KASEQNUM = Kamain.Kaseqnum
			and kd.SHQUALIFY='Add'),
			--AND Kd.AUDITDATE IN (SELECT MAX(AuditDate) FROM KADETAIL WHERE KASEQNUM = Kd.KASEQNUM)),	--09/01/15 DRP:  replaced by the above
	ZMiscmain AS (
		SELECT ZOpenWo.*, SPACE(25) AS Part_no, SPACE(8) AS Revision, Part_no AS CustPartNo, Revision AS CustRev, Descript, Miscmain.ShortQty, Part_class,
			Part_type, AuditDate, Miscmain.Shreason, Qty, Part_sourc, ISNULL(Dept_name, SPACE(25)) AS Dept_name, SPACE(10) AS Uniq_key, Miscmain.Dept_id, SPACE(10) AS Kaseqnum
			FROM ZOpenWo, MISCDET, MISCMAIN LEFT OUTER JOIN Depts
			ON Miscmain.DEPT_ID = Depts.Dept_id
			WHERE ZOpenWo.WONO = Miscmain.WONO
			AND Miscmain.SHORTQTY > 0
			AND PART_SOURC = 'CONSG'
			AND Miscdet.MISCKEY = Miscmain.MISCKEY
			AND SHQUALIFY = 'ADD')

	-- By part number
	SELECT * FROM ZKit
		UNION ALL
	SELECT * FROM ZMiscmain
		ORDER BY CustName,CustPartNo,Wono

end