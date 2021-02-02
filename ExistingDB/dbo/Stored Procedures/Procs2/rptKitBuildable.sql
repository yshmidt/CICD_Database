  
-- =============================================  
-- Author:   Debbie  
-- Create date:  12/16/15  
-- Description:  Compiles the details for the Buildable report  
-- Used On:   shrtbld  
-- Modified:  05/06/16 DRP:  changed revision char(4) to be char(8) throughout the script   
 --- 03/28/17 YS changed length of the part_no column from 25 to 35   
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record  
-- 07/16/18 VL changed custname from char(35) to char(50)  
-- 07/08/2019 : Rajendra K : Changed shortqty numeric(7,0) to numeric(12,2)  
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
-- 12/08/20 VL found if Kit has not started (kamain has no record) can not use IgnoreKit = 0, need to add IgnoreKit is null too
-- EXEC [dbo].[rptKitBuildable]  'all','49F80792-E15E-4B62-B720-21B360E3108A'  
-- =============================================  
 CREATE PROCEDURE  [dbo].[rptKitBuildable]  
  
--DECLARE   
@lcCustNo varchar(max) = 'all'  
,@userId uniqueidentifier = null  
  
  
as  
begin  
  
/*CUSTOMER LIST*/    
 DECLARE  @tCustomer as tCustomer  
  DECLARE @Customer TABLE (custno char(10))  
  -- get list of customers for @userid with access  
  INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;  
  --SELECT * FROM @tCustomer   
    
  IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'  
   insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')  
     where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)  
  ELSE  
  
  IF  @lcCustNo='All'   
  BEGIN  
   INSERT INTO @Customer SELECT CustNo FROM @tCustomer  
  END  
  
-- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record  
DECLARE @lSuppressNotUsedInKit int  
SELECT @lSuppressNotUsedInKit = ISNULL(wm.settingValue,mnx.settingValue)  
 FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm   
 ON mnx.settingId = wm.settingId   
-- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems'
--WHERE mnx.settingName='Suppress Not Used in Kit items ?'
WHERE mnx.settingName='suppressNotUsedInKitItems'	
  
/*RECORD SELECTION SECTION*/  
  
/*GATHER WORK ORDER DETAIL AND CALCULATE THE AFFECTED VALUE*/  
--- 03/28/17 YS changed length of the part_no column from 25 to 35   
-- 07/16/18 VL changed custname from char(35) to char(50)  
declare @zAffected as table (wono char(10),custname char(50),part_no char(35),revision char(8),Prod_id char(10),descript char(45),bldqty numeric(7,0),  
      balance numeric(7,0),due_date smalldatetime, status char(10),kit bit  
      ,kitstatus char(10),kitcomplete bit,shortqty numeric(12,2),qty numeric(7,0),affected numeric(7,0),Buildable numeric(7,0))  
;  
with zWo as (  
  select WoNo,CUSTNAME,part_no,revision,woentry.UNIQ_KEY,DESCRIPT,woentry.BLDQTY,WOENTRY.balance,woentry.due_date,woentry.openclos,woentry.KIT  
  ,woentry.KITSTATUS,woentry.KITCOMPLETE  
  from woentry  
    inner join customer on woentry.CUSTNO = customer.CUSTNO  
    inner join inventor on woentry.uniq_key = inventor.UNIQ_KEY  
  WHERE (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=WOENTRY.custno))  
    and woentry.balance > 0  
    and woentry.openclos not in ('Closed','Cancel')   
   )  
  
insert into @zAffected  
  
  select  z.*,isnull(k.SHORTQTY,0) as ShortQty, isnull(k.QTY,0) as qty,isnull(case when qty <> 0 then ceiling(shortqty/qty) else ceiling(shortqty) end ,0) as affected,cast (0.00 as numeric(7,0)) as Buildable  
  from zWo as z  
    left outer join kamain k  on z.wono = k.wono  
    -- 01/29/18 VL: Added to use mnx setting to filter out IgnoreKit record  
	-- 12/08/20 VL found if Kit has not started (kamain has no record) can not use IgnoreKit = 0, need to add IgnoreKit is null too
    --WHERE 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN IgnoreKit = 0 THEN 1 ELSE 0 END END  
	WHERE 1 = CASE WHEN @lSuppressNotUsedInKit = 0 THEN 1 ELSE CASE WHEN (IgnoreKit = 0 OR IgnoreKit IS NULL) THEN 1 ELSE 0 END END  
  order by custname,due_date,wono  
  
  
  
/*CALCULATE THE RECORD NUMBER BASED ON AFFECTED VALUE DECENDING THEN UPDATE THE BUILDABLE QTY*/  
--- 03/28/17 YS changed length of the part_no column from 25 to 35   
-- 07/16/18 VL changed custname from char(35) to char(50)  
declare @zRnCount as table (wono char(10),custname char(50),part_no char(35),revision char(8),Prod_id char(10),descript char(45),bldqty numeric(7,0),balance numeric(7,0),due_date smalldatetime, status char(10),kit bit  
      ,kitstatus char(10),kitcomplete bit,shortqty numeric(12,2),qty numeric(7,0),affected numeric(7,0),Buildable numeric(7,0)  
      ,RN numeric)  
  
insert into @zRnCount  
 select  A.*,ROW_NUMBER () OVER(PARTITION BY custname,due_date,wono ORDER BY custname,due_date,wono,affected desc)  as RN  
 from @zAffected A   
  
update @zRncount set buildable = case when x.kit = 1 and x.kitstatus <> '' then case when x.balance - x.affected<0 then 0 else x.balance-x.affected end else 0 end   
from @zRnCount X   
  
  
  
/*FINAL SELECTION THAT WILL UPDATE BUILDABLE WITH KIT STANDING OR BUILDABLE QTY*/  
--- 03/28/17 YS changed length of the part_no column from 25 to 35   
declare @zbldrep as table(wono char(10),custname char(35),part_no char(35),revision char(8),Prod_id char(10),descript char(45),bldqty numeric(7,0),balance numeric(7,0),due_date smalldatetime, status char(10),Buildable char (8))  
  
insert into @zbldrep  
 select  wono,custname,part_no,revision,prod_id,descript,bldqty,balance,due_date,status  
   ,case when B.kitcomplete = 1 then 'KC' else   
    case when B.kitcomplete = 0 then case when B.kitstatus = ''   
     then 'KNS' when B.kitstatus = 'KIT PROCSS' then 'KIP' else CAST(B.Buildable  AS  CHAR(7)) end end end as BuildableStatus  
 from @zRnCount B   
 where B.RN = 1  
 order by custname, wono  
  
  
select * from @zbldrep order by custname,due_date,wono  
  
end