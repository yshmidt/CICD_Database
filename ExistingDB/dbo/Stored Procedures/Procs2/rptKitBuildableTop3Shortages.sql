-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/22/2013
-- Description:	Kit Buildable Top 3 Shortage Report
-- Modified: 12/03/13 YS use 'All' for all instead of '' or null
--			 01/23/14 DRP: we found that if the user left All for the cUSTOMER that it was bringing forward all customers regardless if the user was approved for the Userid or not. 
--			 01/06/2015 DRP:  Added @customerStatus Filter
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
-- =============================================
CREATE PROCEDURE [dbo].[rptKitBuildableTop3Shortages] 
	--12/03/13 YS use 'All' for all instead of '' or null
	 @lcCustNo varchar(max)='All' ,		-- if null will select all customers, @lcCustomer could have a single value for a custno or a CSV
	 @customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
	 ,@UserId uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @tCustomers tCustomer
	DECLARE @tCustno tCustno ;
	DECLARE @tWo as tWono
	
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;

	-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
	DECLARE @lSuppressNotUsedInKit int
	SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)
		FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm 
		ON mnx.settingId = wm.settingId 
		-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
		--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
		WHERE mnx.settingName='suppressNotUsedInKitItems'	

    -- Insert statements for procedure here
    -- list all given customers if any
     --12/03/13 YS use 'All' for all instead of '' or null
--01/23/2014 DRP:  REMOVED BELOW
--*/*
	--IF  @lcCustomer <>'All'
	--	INSERT INTO @tCustno SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustomer,',')
	--		WHERE cast(ID as char(10)) IN (SELECT Custno from @tCustomer)
	--ELSE
	--BEGIN
	----12/03/13 YS empty or null means no selection
	--IF @lcCustomer <>'' and @lcCustomer is not null 
	--	-- get all the customers to which @userid has accees
	--	-- selct from the list of all customers for which @userid has acceess
	--	INSERT INTO @tCustno SELECT Custno FROM @tCustomer	
	--END
--*/*
--01/23/214 DRP:  REPLACED THE ABOVE WITH THE BELOW	
	IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
		insert into @tCustno select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',') where CAST (id as CHAR(10)) in (select Custno from @tCustomers)
	ELSE
		IF  @lcCustNo='All'	
	BEGIN
		INSERT INTO @tCustno SELECT Custno FROM @tCustomers
	END	
	
		 	 
	;
	WITH ZOpenWO4Cust
	AS
	(
		SELECT Wono, BLDQTY, BALANCE, KIT, KITSTATUS, DUE_DATE, KITCOMPLETE, Custno, Uniq_key  
			FROM WOENTRY 
			WHERE OPENCLOS <> 'Cancel'
			AND OPENCLOS <> 'Closed'
			AND BALANCE <> 0
			AND CUSTNO IN 
				(SELECT CUSTNO 
					FROM @tCustno)
	),
	ZTop
	AS
	(
	SELECT Kamain.Uniq_key, CASE WHEN Part_sourc = 'CONSG' THEN CustPartno ELSE Part_no END AS Part_no,
				CASE WHEN Part_sourc = 'CONSG' THEN CustRev ELSE Revision END AS Revision, Part_sourc, Part_class, Part_type, 
				Descript, ShortQty, Qty, Dept_id, CASE WHEN Qty<>0 THEN CEILING(ShortQty/Qty) ELSE CEILING(ShortQty) END AS Affected, Wono,
				PartitionedRowNum = ROW_NUMBER() OVER (PARTITION BY wono ORDER BY CASE WHEN Qty<>0 THEN CEILING(ShortQty/Qty) ELSE CEILING(ShortQty) END DESC)
		FROM Kamain,Inventor
		WHERE ShortQty > 0 
		-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record
		--AND IgnoreKit = 0
		AND 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END
		AND Inventor.Uniq_key = Kamain.Uniq_key
		AND WONO IN (SELECT WONO FROM ZOpenWO4Cust)
	)		
	SELECT ZOpenWO4Cust.Wono, Custname, A.Part_no AS ProdNo, A.Revision AS ProdRevision, A.Descript AS ProdDescript, BldQty, Balance, 
		CASE WHEN (ZOpenWO4Cust.Kit = 1 AND ZOpenWO4Cust.KitStatus <> '') THEN 
			CASE WHEN ZOpenWO4Cust.Balance - ZTop.Affected < 0 THEN 0 ELSE ZOpenWO4Cust.Balance - ZTop.Affected END 
			ELSE 0 END AS BuildAble, 
		Dept_name, ZTop.Part_class, ZTop.Part_Type, ZTop.Part_no, ZTop.Revision, ZTop.Part_Sourc, ZTop.Descript, Ztop.ShortQty,
		ZTop.Qty, ZTop.Affected, Due_date, CASE WHEN ZOpenWO4Cust.KitComplete = 1 THEN 'KC' ELSE CASE WHEN ZOpenWO4Cust.KitStatus = '' THEN 'KNS' ELSE 
			CASE WHEN ZOpenWO4Cust.KitStatus = 'KIT PROCSS' THEN 'KIP' ELSE '' END END END AS Status
		FROM ZOpenWO4Cust, Customer, Inventor A, ZTop LEFT OUTER JOIN Depts
		ON ZTop.DEPT_ID = Depts.DEPT_ID 
		WHERE ZOpenWO4Cust.WONO = Ztop.WONO
		AND ZOpenWO4Cust.Custno = Customer.CUSTNO
		AND ZOpenWO4Cust.UNIQ_KEY = A.UNIQ_KEY
		AND PartitionedRowNum <= 3
	UNION
	(SELECT ZOpenWO4Cust.Wono, Custname, A.Part_no AS ProdNo, A.Revision AS ProdRevision, A.Descript AS ProdDescript, BldQty, Balance, 
		0 AS BuildAble, SPACE(25) AS Dept_name, SPACE(8) AS Part_class, SPACE(8) AS Part_type, SPACE(25) AS Part_no,
		SPACE(8) AS Revision, SPACE(10) AS Part_Sourc, SPACE(45) AS Descript, 000000000.00 AS ShortQty, 000000000.00 AS Qty, 
		000000000.00 AS Affected, ZOpenWO4Cust.Due_date, CASE WHEN ZOpenWO4Cust.KitComplete = 1 THEN 'KC' ELSE CASE WHEN ZOpenWO4Cust.KitStatus = '' THEN 'KNS' ELSE 
			CASE WHEN ZOpenWO4Cust.KitStatus = 'KIT PROCSS' THEN 'KIP' ELSE '' END END END AS Status
		FROM ZOpenWO4Cust, CUSTOMER, Inventor A
		WHERE ZOpenWO4Cust.CUSTNO = Customer.CUSTNO
		AND ZOpenWO4Cust.UNIQ_KEY = A.UNIQ_KEY
		AND WONO NOT IN (SELECT WONO FROM ZTop))
	ORDER BY CUSTNAME, Due_date, Wono ASC, Affected DESC	
END