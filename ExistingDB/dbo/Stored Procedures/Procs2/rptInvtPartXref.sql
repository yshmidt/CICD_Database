
-- =============================================
-- Author:		<Debbie>
-- Create date: <07/05/2011>
-- Description:	<created for reports icrpt9a.rpt, icrpt9b.rpt>
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
--			06/10/2015 DRP:  started preparing the procedure to work with the Cloud:  Added the @lcSort and @lcType to the procedure.   Added the /*SOURCE LIST*/ and the If @lcType section at the end to control the view to match the screen seletions
--							 Added /*CUSTOMER LIST*/ Also so if they select 'CONSG' that it will only display the Customers that the user has rights to view. 
-- 10/13/14 YS replaced invtmfhd table with 2 new tables
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtPartXref] 


	@lcSource as varchar (max) = 'ALL'						--All,BUY,CONSG,MAKE,PHANTOM
	,@lcType as char (25) = 'Internal to Manufacturer'		--Internal to Manufacturer,Manufacturer to Internal
	,@lcSort as char (25) = 'Manufacturer Part Number'		--Manufacturer Part Number,Manufacturer
	,@userId uniqueidentifier= null

AS
BEGIN

/*SOURCE LIST*/
DECLARE @tSource as table ([source] char (10))
DECLARE @Source as table([source] char(10))

insert into @tSource select distinct part_sourc from INVENTOR

if @lcSource is not null and @lcSource <> '' and @lcSource <> 'All'
	insert into @Source select * from dbo.[fn_simpleVarcharlistToTable](@lcSource,',')
		where cast (id as char(12)) in (select [source] from @tSource)

else
	if @lcSource = 'All'
	Begin
		Insert into @Source select [source] from @tSource
	End

/*CUSTOMER LIST*/		
		DECLARE  @tCustomer as tCustomer
		
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' 	


/*RECORD SELECTION*/
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/16/18 VL changed custname from char(35) to char(50)
declare @Results as table (UNIQ_KEY char(10), PART_NO char(35), REV char(8), PART_SOURC char(10), CUSTNAME char(50), PART_CLASS char(8), PART_TYPE char(8), DESCRIPT char(45), PARTMFGR char(8), MFGRNAME char(35), MFGR_PT_NO char(30), 
							MATLTYPE char(10), Buyer char(3), UNIQMFGRHD char(10), Qty_oh numeric(15,2),custno char(10))

insert into @Results
select		UNIQ_KEY, PART_NO, REV, PART_SOURC, CUSTNAME, PART_CLASS, PART_TYPE, DESCRIPT, PARTMFGR, MFGRNAME, MFGR_PT_NO, 
			MATLTYPE, Buyer, UNIQMFGRHD, SUM(QTY_OH) AS Qty_oh,CUSTNO
from 
(
-- 07/16/18 VL changed custname from char(35) to char(50)
Select		dbo.INVENTOR.UNIQ_KEY, CASE WHEN PART_SOURC = 'CONSG' THEN CUSTPARTNO ELSE PART_NO END AS PART_NO, 
			CASE WHEN PART_SOURC = 'CONSG' THEN CUSTREV ELSE REVISION END AS REV, dbo.INVENTOR.PART_SOURC, ISNULL(dbo.CUSTOMER.CUSTNAME, 
			CAST(' ' AS CHAR(50))) AS CUSTNAME, dbo.INVENTOR.PART_CLASS, dbo.INVENTOR.PART_TYPE, dbo.INVENTOR.DESCRIPT, M.PARTMFGR, 
			dbo.SUPPORT.TEXT AS MFGRNAME, M.MFGR_PT_NO, M.MATLTYPE, dbo.INVENTOR.BUYER_TYPE AS Buyer, 
			dbo.INVTMFGR.UNIQMFGRHD, dbo.INVTMFGR.QTY_OH,inventor.CUSTNO
FROM		dbo.INVENTOR LEFT OUTER JOIN
			dbo.CUSTOMER ON dbo.INVENTOR.CUSTNO = dbo.CUSTOMER.CUSTNO LEFT OUTER JOIN
			-- 10/13/14 YS replaced invtmfhd table with 2 new tables
			--dbo.INVTMFHD ON dbo.INVENTOR.UNIQ_KEY = dbo.INVTMFHD.UNIQ_KEY INNER JOIN
			InvtMPNLink L ON Inventor.uniq_key=L.uniq_key LEFT OUTER JOIN 
			-- 10/13/14 YS replaced invtmfhd table with 2 new tables
			MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId LEFT OUTER JOIN
			--dbo.SUPPORT ON dbo.SUPPORT.TEXT2 = dbo.INVTMFHD.PARTMFGR LEFT OUTER JOIN
			SUPPORT ON dbo.SUPPORT.TEXT2 = M.PARTMFGR LEFT OUTER JOIN
			-- 10/13/14 YS replaced invtmfhd table with 2 new tables
			--dbo.INVTMFGR ON dbo.INVTMFHD.UNIQMFGRHD = dbo.INVTMFGR.UNIQMFGRHD
			INVTMFGR ON L.UNIQMFGRHD = dbo.INVTMFGR.UNIQMFGRHD

WHERE
-- 10/13/14 YS replaced invtmfhd table with 2 new tables
--dbo.INVTMFHD.IS_DELETED = 0 
		(L.is_deleted=0 or l.is_deleted is null)
		and 1 = case when inventor.PART_SOURC in (select [source] from @Source ) then 1 else 0 end
		--and Part_sourc LIKE CASE WHEN @lcSource = '*' then '%' else @lcSource+'%' end	--06/10/2015 DRP:  REMOVED
		and 1 = case when inventor.CUSTNO in (select CUSTNO from @tcustomer ) then 1 else 0 end

) t1 GROUP BY	UNIQ_KEY, PART_NO, REV, PART_SOURC, CUSTNAME, PART_CLASS, PART_TYPE, DESCRIPT, PARTMFGR, MFGRNAME, MFGR_PT_NO, MATLTYPE, Buyer, UNIQMFGRHD,custno


--06/10/2015 DRP:  added the below section to make sure that the quickview results match the selections made on screen
if @lcType = 'Internal to Manufacturer'
	Begin
		select PART_SOURC,PART_NO,REV,PART_CLASS,PART_TYPE,DESCRIPT,CUSTNAME,PARTMFGR,MFGR_PT_NO,MATLTYPE,BUYER,Qty_oh,UNIQMFGRHD,UNIQ_KEY from @Results 
		order by  PART_SOURC,PART_NO,REV,UNIQ_KEY, case when @lcSort = 'Manufacturer Part Number' then MFGR_PT_NO else PARTMFGR end
	End
else if @lcType = 'Manufacturer to Internal'
	Begin
		Select PARTMFGR,MFGR_PT_NO,PART_CLASS,PART_TYPE,PART_NO,REV,DESCRIPT,PART_SOURC,CUSTNAME,MATLTYPE,BUYER,Qty_oh,UNIQMFGRHD,UNIQ_KEY from @Results
		order by case when @lcSort = 'Manufacturer Part Number' then MFGR_PT_NO else PARTMFGR end,PART_NO,REV,UNIQ_KEY
	End
		

END