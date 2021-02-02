-- ===========================================================================================================================================================================  
-- Author:   Debbie & Vicky  
-- Create date:  10/12/2012  
-- Description:  Created for the Kit Pick List Work Sheet report within Kitting  
-- Reports Using Stored Procedure:  kitpickl.rpt   
-- Modifications: 10/29/2012 DRP:  Due to some changes within Crystal Report I changed @lcIgnore = '' to @lcIgnore = 'No'  
-- 11/26/2012 DRP:  Work orders that where not yet in process was pulling fwd ALL items from the BOM regardless of the Eff and OB Dates.  Modifications have been made below so that it pulls according to the WO Due Date  
-- 11/26/2012 DRP:  Also found that if the BOM happen to have the same part number loaded on the BOM to different items (one active and one OB) and the kit was put in process.  
--     The results was displaying both active and inactive items.  Below corrections were made so that it will also consider the BOM Eff and OB dates.   
-- 11/26/2012 DRP:  Found that deleted locations were being displayed when a kit is not yet in process.  Modifications have been made to filter out deleted locations.  
-- 12/06/2012 DRP:  I was for some reason pulling the woentry.OrderDate when I should have been pulling the woentry.Due_date field.  Updated the @results declared table and the code that populates this table.   
-- 12/07/2012 VL:   I found the calculation of ReqDate is incorrect, the Kit_lUnit was mistakenly changed to use Prod_lUnit  
-- 02/15/2013 DRP:  Beta users were experiencing truncated data error.  Upon review I found that I used to have the Serial Yes at the end of the declared table @tbom within the [if (@SupUsedKit = 0)]section of code , when it really  
--      should have been after the UniqBomNo in the table.  They experienced a truncate error when the code tried to place a uniq_key into a Bit field.   
-- 02/15/2013 DRP:  Also found that it was not removing Not Used in Kit items.  The if (@SupUsedKit = 0)statement was commented out to address this issue.   
-- 02/15/2013 DRP:  Per Yelena's instrucitons I have moved these variables all to the First From Woentry line, instead of calling from the Woentry table multiple time throughout the procedure below.   
-- 03/13/2013 DRP:  I saw you comment out my select @lcKitStatus = ...." code and move to top that you gathered all variables from woentry at one time (2/15/13)  
--      , but the "@@ROWCOUNT<>0 was left there without the SELECT command anymore.  That's the reason the code didn't work.  Please comment out the "IF @@ROWCOUNT<>0 and BEGIN" code that below my comment on 10/01/12.  You might also need to check the "END" that's a pair of the IF/BEGIN  
-- 04/22/2013 DRP:  reported that when the users selected to suppress zero on hand locations, if the part had absolutely zero on hand as a total, that the entire part was falling from the kit pick list.   
--      below I removed the @lcSupZero parameter from the SP and any location within the SP that it was used.  This parameter filter was then added within Crystal Report itelf.   
-- 05/22/2013 DRP:  there was a spot within the code where I was calling BomIndented procedure and I had incorrectly had the ParentMatlType as char(8) when it should have been char(10).  It was causing truncating issues.   
-- 09/24/2013 VL :   Fix the issue that all partmfgrs are displayed, only should show AVL  
-- 09/24/2013 DRP:  the PnlBlank in the @results section used to be numeric(4,0) it needed to be numeric(7,0)  
-- 10/02/2013 DRP:  Found that I had MatlType char (8) when it should have been MatlType char (10)  
-- 10/31/2013 VL :   DED reported a problem that customer part number has less AVL than internal part number AVL, but it shows all AVL from internal part number AVL, fix it  
-- 11/01/13 DRP  :  the Qty Not Reserved was not working properly in case the Qty was actually allocated to the kit that was pulled in the procedure.   
-- 11/05/13 VL   :  Remove Invt_res table from the insert of @Result, need to use SUM()   
-- 12/16/13 DRP  : it was reported that obsoleted items from the make/phantom level of the bom was incorrectly displaying on the results for when the kit was not yet in process section.   I added the filter that checks for the obsolete dates.        
-- 01/17/14 DRP  : found that I needed to added CEILING() to the ReqQty and ShortQty fields in order to ensure that they would always round up to the next whole number  
-- 03/28/14 VL   : in @lcKitStatus <> '' part that Debbie had code to add items that's not in Kitmainview, changed from USED_INKIT = 'N' to USED_INKIT<>'Y' so it include 'N' and 'F' for the items that has 'F'  
-- 04/02/2014 DRP: If the Kit is in process it will now always take from the KitMainView Req_qty and ShortQty regardless of the Ignore Scrap the user might make on the report  
--     If the Kit is NOT in process then it will first take into consideration the Kit Default setting.  Then if the user refreshes the report and changes the   
--     Ignore Scrap parameter the Required Qty should update accordingly.    
-- 11/18/2014 DR :  With Yelena's help we found in one case that the user used to have the part listed on the top level of the BOM with only one of the AVL's marked as approved.   
--     They then added a sub-assm to the bom that used the same part.  While on the sub-assm it had all of the AVL's approved.  But when exploded out into the results it was still pulling the inactive top level part.  
--     added <<zresults.bomparent = AntiAvl4BomParentView.bomparent>> to the section of code that is used when the Kit has not been put in process yet.   
-- 02/17/2015 VL : Only pick active parts  
-- 03/12/15 YS   : replaced invtmfhd table with 2 new tables  
-- 04/14/15 YS   : Location length is changed to varchar(256)  
-- 05/26/2015 DRP: Needed to change <<PnlBlank numeric(4,0)>> within the @results to be <<PnlBlank numeric(7,0)>>  . . a user was experiencing truncation erorr.  
-- 05/27/2015 DRP: Adding PhParentWc to the results as requested by user.  
-- 01/29/16 DRP: reports of slow response time for some work orders.  Changed within INSERT @KitInvtView  section <<LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key+@BomCustno=Inventor.INT_UNIQ+Inventor.Custno>> to be  
--     <<LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key=inventor.int_uniq and @BomCustno=Inventor.Custno>>  
-- 03/29/16 DRP: for the Kit not in process section the code was incorrectly pulling for the MfgrMtlType from the Inventory part number level, not the Mfgr level.    
--     <<B2.MatlType as MfgrMatlType>> to be <<invtmfhd.MatlType as MfgrMatlType>>  
-- 11/08/16 DRP:  needed to add @KitIgnoreScrap and lKitIgnoreScrap to the results so we could determine if the kit is in process if it already removed the scrap values or not  
--     under the Kit In Process section I had to change the formula used for the Req_QTy and ShortQty   
-- 11/09/16 DRP:  found that by using the kitmainview already created that the phantom part were already calculated out for the required qty. this means that I had to consider a different formula when ignoring Scrap parameter was calcultated when it comesto the Phantom items.   
-- 01/12/17 DRP:  I needed to account for the situation where the buy parts on the bom had Setup Scrap but the bom that it was used on happen to be set to not use Setup Scrap.  I also took out the use of the @KitIgnoreScrap within the formulas, I was trying to get the default setting from the system ,but that was just confusing the results on screen  
-- 03/28/17 YS changed length of the part_no column from 25 to 35   
-- 09/08/17 VL I fixed the code in manex_fc, but not here.  Only problem found in manex_fc, just added comment here so we know we didn't forget to fix. Urtech reported an issue that "Ignore Both Scrap" return 0 short qty, I found Debbie removed the use of@KitIgnoreScrap in everywhere on 01/12/17 except in the case of "Ignore Both Scrap" for Kit exist case, I will just remove the use of @KitIgnoreScrap here too  
-- 01/09,14/18 VL change the SP for only one wono to work for wono list, tried not to rewrite much, so keep most of the code for one wono (no need to change those SPs), and loop the wono table to insert into final SQL  
-- 03/01/18 YS lotcode size change to 25  
-- 07/16/18 VL changed custname from char(35) to char(50)  
-- 04/24/18 SatyawanH: removed Rej_qty,Rej_date and Rej_reson from @ZKitMainView table variable  
-- 04/24/18 SatyawanH: Only pick parts that are USED_INKIT = 'Y' to get all the records that are used into Kit  
  
-- EXEC rptKitPickList @lcWono='ALL', @lcDeptId='All', @lcIgnore='No', @lcSupUsedKit='No', @userId='49f80792-e15e-4b62-b720-21b360e3108a'  
  
-- 05/01/19 VL 1. comment out 04/28/18 changes USED_INKIT = 'Y' to get all records. Found Debbie created this section of code for NOT used in Kit records, so if user choose to see not used in KIT records,   
--    those records will be inserted into @results.  The records inserted into @results later from  @ZKitMainView don't have those not used_inkit item, change back to USED_INKIT <> 'Y'  
--    2. Also, found the changes Debbie did on 11/16/15 was not here: 11/16/15 DRP: added the /*DEPARTMENT LIST*/  
--    3. Added new parameter @lcUniqWH to let user filter by warehouse  
--    4. Change kit default setting from kitdef and invtsetup to mnxsettingmanagement table  
-- 07/15/2019 Rajendra K : Added table and get all WONO if "All" work order are selected
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
-- 10/22/20 VL added BEGIN and END for the @lcWoNo<>'All' selection, otherwise the @lnWonoCount got incorrect @@ROWCOUNT
-- 12/30/20	VL Use 5 days(was 7) for WK and 20 days (was 30) for MO to calcualte leadtime/requied date, also added sublead time to work the same as QkViewKitRequiredView that YS changed in 2018, Zendesk #6812
-- ===========================================================================================================================================================================  
CREATE procedure [dbo].[rptKitPickList]  
  -- 01/09/18 VL changed to use multiple wono, not just one  
  -- @lcWono AS char(10) = '' -- Work order number  
  @lcWoNo as varchar(max) = '',  
  @lcIgnore as char(20) = 'No', -- used within the report to indicate if the user elects to ignore any of the scrap settings.  
  --04/22/2013 DRP removed--,@lcSupZero char (18) = 'Use System Default',  -- here the report will use the System Default, but give the users to change if the suppress Zero Qty on hand records or not.  
  @lcSupUsedKit char(18) = 'Use System Default', -- here the report will use the system default for Suppress Not Used in Kit, but the users have the option to change manually within the report.   
  -- 01/15/18 VL chagned from char(4) to varchar(max) = 'All', and added @userId, copied code from maenx_fc to update here  
  --@lcDeptId char(4) = '*', -- here the user will select individual dept ID's or leave '*' if they wish to see all  
  @lcDeptId varchar(max) = 'All', -- here the user will select individual dept ID's or leave '*' if they wish to see all  
  -- 05/01/19 VL added warehouse   
  @lcUniqWH varchar(max)='All',  
  @userId uniqueidentifier=null  
as   
begin  
 -- 01/15/18 VL copied from manex_fc for dept selection  
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
  
 IF @lcDeptId='All'   
 BEGIN  
  INSERT INTO @Depts SELECT Dept_id FROM @tDepts  
 END  
   
 -- 05/01/19 VL added warehouse  
 DECLARE @Warehouse TABLE (UniqWH char(10))  
 IF (@lcUniqWH<>'All' and @lcUniqWH<>' ' and @lcUniqWH IS NOT NULL)  
  INSERT INTO @Warehouse (UniqWH) select id  from dbo.[fn_simpleVarcharlistToTable](@lcUniqWH,',')  
  
 -- {01/09/18 VL insert wono into tWono  
 DECLARE @lnWonoCount int, @lnCnt int = 0  
 DECLARE @tWono TABLE (Wono char(10), nId Int IDENTITY(1,1))   
 IF @lcWoNo  = 'All' -- 07/15/2019 Rajendra K : Added table and get all WONO if "All" work order are selected
	 BEGIN  
	  DECLARE @tCustomer tCustomer;  
	   INSERT INTO @tCustomer EXEC [aspmnxSP_GetCustomers4User] @userid,null,'All';  
	   INSERT INTO  @tWono    
	   SELECT W.Wono     
	   FROM Woentry W     
	   INNER JOIN @tCustomer C ON W.CUSTNO=C.Custno    
	   WHERE 1=CASE WHEN ( OpenClos<>'Closed' and OpenClos<>'Cancel') THEN 1 ELSE 0 END 
	   SELECT @lnWonoCount = @@ROWCOUNT     
	 END  
 ELSE  
 -- 10/22/20 VL added BEGIN and END for the @lcWoNo<>'All' selection, otherwise the @lnWonoCount got incorrect @@ROWCOUNT
	BEGIN
	  INSERT INTO @tWono SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcwono,',')  
	  SELECT @lnWonoCount = @@ROWCOUNT  
	END

 SET NOCOUNT ON;  
   -- 01/09/18 VL moved to later place (after DECLARE code)  
   --SET @lcWono=dbo.PADL(@lcWono,10,'0')  
   DECLARE @lcKitStatus CHAR(10)  
  
   --Main Kitting information   
   --- 03/28/17 YS changed length of the part_no column from 25 to 35   
   -- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
   DECLARE @ZKitMainView TABLE (DispPart_no char(35),Req_Qty numeric(12,2),Phantom char(1),DispRevision char(8),Part_class char(8),Part_type char(8),Kaseqnum char(10)  
          ,Entrydate smalldatetime,Initials char(8),  
          --Rej_qty numeric(12,2),Rej_date smalldatetime,Rej_reson char(10),  
          -- 04/24/18 removed Rej_qty,Rej_date and Rej_reson from @ZKitMainView table variable  
          Kitclosed bit,Act_qty numeric(12,2),Uniq_key char(10),Dept_id char(4),Dept_name char(25),Wono char(10),Scrap numeric(6,2),Setupscrap numeric(4,0),  
          Bomparent char(10),Shortqty numeric(12,2),Lineshort bit,Part_sourc char(10),Qty numeric(12,2),Descript char(45),Inv_note text,U_of_meas char(4),  
          Pur_uofm char(4),Ref_des char(15),  
          --- 03/28/17 YS changed length of the part_no column from 25 to 35   
          Part_no char(35),Custpartno char(35),Ignorekit bit,Phant_make bit,Revision char(8),Serialyes bit,Matltype char(10),CustRev char(8)
		-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
		,allocatedQty numeric(12,2), userid uniqueidentifier)
  
   --Inventory mfgr and qty detail from the Kitting Main information above  
   --04/14/15 YS Location length is changed to varchar(256)  
   DECLARE @KitInvtView TABLE (Qty_oh numeric(12,2),QtyNotReserved numeric(12,2),QtyAllocKit numeric(12,2),Kaseqnum char(10),Uniq_key char(10),BomParent char(10)  
          ,Part_sourc char(10),AntiAvl char(2),Partmfgr char(8),Mfgr_pt_no char(30),Wh_gl_nbr char(13),UniqWh char(10),Location varchar(256)  
          ,W_key char(10),InStore bit,UniqSupno char(10),Warehouse char(6),CountFlag char(1),OrderPref numeric(2,0),UniqMfgrhd char(10),MfgrMtlType char(10)  
          ,cUniq_key char(10));  
       
   --Table that will compile the final results  
   -- 09/24/2013 DRP:  changed the PnlBlank from numeric(4,0) to numeric(7,0)  
   -- 10/31/13 VL added cUniq_key to save customer uniq_key if exist  
   -- 11/01/13 VL Added w_key used to update QtyNotReserved  
   -- 04/14/15 YS Location length is changed to varchar(256)  
   -- 03/28/17 YS changed length of the part_no column from 25 to 35   
   -- 01/09/18 VL added one more field KitStatus(), found Debbie's code on 11/08/16 that in final SQL select, lKitIgnoreScrap treated differently if KitStatus is not empty or not (IF KitStatus is not empty, then @KitIgnoreScrap as lKitIgnoreScrap, else 0AS lKitIgnoreScrap)  
   -- 07/16/18 VL changed custname from char(35) to char(50)  
   DECLARE @results TABLE  (Custname char(50),Due_Date smalldatetime,KitReqDate smalldatetime,ParentBomPn char(35),ParentBomRev char(8),ParentBomDesc char(45),ParentMatlType char(10)  
         ,BldQty numeric (7,0),PerPanel numeric (7,0),PnlBlank numeric(7,0),Item_No numeric(4,0),Used_InKit char(1),DispPart_No varchar(max),DispRevision char(8),Req_Qty numeric(12,2)  
         ,Phantom char(1),Part_Class char(8),Part_Type char(8),Kaseqnum char(10),KitClosed bit,Act_Qty numeric(12,2),Uniq_key char(10),Dept_Id char(4)  
         ,Dept_Name char(25),Wono char(10),SoNo char(10),Scrap numeric (6,2),SetupScrap numeric (4,0),BomParent char(10),ShortQty numeric(12,2),LineShort bit,Part_Sourc char(10)  
         ,Qty numeric(12,2),Descript char(45),U_of_Meas char(4),  
         --- 03/28/17 YS changed length of the part_no column from 25 to 35   
         Part_No char(35),CustPartNo char(35),IgnoreKit bit,Phant_Make bit,SerialYes bit,Revision char(8),MatlType char(10)  
         ,CustRev char(8),location varchar(256),whse char(6),Qty_Oh numeric(12,2),QtyNotReserved numeric(12,2),QtyAllocKit numeric (12,2)  
          --03/01/18 YS lotcode size change to 25  
         ,AntiAvl char(2),PartMfgr char(8),Mfgr_Pt_No char(30),MfgrMtlType char(10),OrderPref numeric(2,0),UniqMfgrHd char(10),LotCode char(25),ExpDate smalldatetime  
         ,Reference char(12),PoNum char(15),LotQty numeric(12,2),LotQtyAvail numeric(12,2),UniqLot char(10),PhParentPn char(35),PhParentWc char(25),Instore bit, cUniq_key char(10), W_key char(10)  
         -- 01/09/18 VL added KitStatus  
         ,KitStatus char(10))   
            
   -- 09/28/12 VL   
   -- This table will keep all anti avl info for this bomparent  
   DECLARE @AntiAvl4BomParentView TABLE (BomParent char(10), Uniq_key char(10), PartMfgr char(8), Mfgr_pt_no char(30), UNIQANTI char(10))  
  
   -- 11/01/13 VL create ZWoalloc and ZPjAlloc that will be used to calculate Qty available  
    --03/01/18 YS lotcode size change to 25  
   DECLARE @ZWoAlloc TABLE (W_key char(10), Uniq_key char(10), LotCode char(25), ExpDate smalldatetime, QtyAlloc numeric(12,2), Reference char(12), PoNum char(15))  
   DECLARE @ZPJAlloc TABLE (W_key char(10), Uniq_key char(10), QtyAlloc numeric(12,2), LotCode char(25), ExpDate smalldatetime, Reference char(12), PoNum char(15), Fk_prjunique char(10))  
     
   -- 05/01/19 VL added @SupZero back and changed from invtsetup.lSuppressZeroInvt to mnxsettingmanagement.settingname = 'suppressLocationsWith0Qty'      
   DECLARE @llKitAllowNonNettable bit,@AllMftr bit, @WOuniq_key char(10), @BomCustno char(10),@SupZero char(18), @SupUsedKit char(18)  
     ,@KitIgnoreScrap char(20); --11/08/16 DRP:  Added @KitIgnoreScrap  
     
   SELECT @SupZero =  ISNULL(wm.settingValue,mnx.settingValue)  
          FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm   
          ON mnx.settingId = wm.settingId   
          WHERE mnx.settingName='suppressLocationsWith0Qty'  
  
   -- 01/09/18 VL comment out duplicate code  
   --SET @lcWono=dbo.PADL(@lcWono,10,'0') --repopulating the work order number with the leading zeros  
      
   -- 02/15/2013 DRP:  Per Yelenas instructions I moved these Declared items to the top portion of the Procedure  
   -- 11/01/13 VL added PrjUnique that used for get allocation for PJ  
   DECLARE  @lcBomParent char(10)  
      ,@IncludeMakebuy bit = 1   
      ,@ShowIndentation bit =1  
      --,@UserId uniqueidentifier=NULL  
      ,@gridId varchar(50)= null   
      ,@lcWoDuedate as smalldatetime = ''  
      ,@lcPrjUnique char(10)  
     
   -- 05/01/19 VL change allow non nettable warehouse location setting from kitdef.lKitAllowNonNettable to mnxsettingmanagement.settingname = 'allowUseOfNonNettableWarehouseLocation'  
   --SELECT @llKitAllowNonNettable = lKitAllowNonNettable FROM KitDef  
   SELECT @llKitAllowNonNettable =  ISNULL(wm.settingValue,mnx.settingValue)  
          FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm   
          ON mnx.settingId = wm.settingId   
          WHERE mnx.settingName='allowUseOfNonNettableWarehouseLocation'  
  
   SELECT @AllMftr = allmftr from KITDEF  
   --02/15/2013 DRP:  Per Yelena's instrucitons I have moved these variables all to this one From Woentry line, instead of calling from the Woentry table multiple time throughout the procedure below.   
   --04/22/2013 DRP removed and added to the crystal report      
   --select @SupZero = (select case when @lcSupZero = 'Use System Default' or @lcSupZero = '' then lSuppressZeroInvt   
   --       else case when @lcSupZero = 'Yes' then 1   
   --        else case when @lcSupZero = 'No' then 0 end end end  from INVTSETUP)  
   -- 05/01/19 VL we changed the kit supress not used in kit setting from kitdef.lsuppressnotusedinkit to mnxsettingmanagement.settname='suppressNotUsedInKitItems'  
   --select @SupUsedKit = (select case when @lcSupUsedKit = 'Use System Default' OR @lcSupUsedKit = '' then Lsuppressnotusedinkit  
   --      else case when @lcSupUsedKit = 'Yes' then 1  
   --      else case when @lcSupUsedKit = 'No'  then 0 end end end from KITDEF)   
  
   select @SupUsedKit = (select case when @lcSupUsedKit = 'Use System Default' OR @lcSupUsedKit = '' then ISNULL(wm.settingValue,mnx.settingValue)  
         else case when @lcSupUsedKit = 'Yes' then 1  
         else case when @lcSupUsedKit = 'No'  then 0 end end end   
         FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm   
         ON mnx.settingId = wm.settingId   
         WHERE mnx.settingName='suppressNotUsedInKitItems')   
  
  
   -- 05/01/19 VL changed the ignore scrap setting is changed from kitdef.lkitignorescrap to mnxsettingmanagement.settingname = 'Kitting' -- I think we need to change the settingname  
   --select @KitIgnoreScrap = (select LKITIGNORESCRAP from kitdef) --11/08/16 DRP:  Added  
   select @KitIgnoreScrap =  ISNULL(wm.settingValue,mnx.settingValue)  
          FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm   
          ON mnx.settingId = wm.settingId   
          WHERE mnx.settingName='Kitting'  
  
   --select @lcBomParent = woentry.UNIQ_KEY from WOENTRY where @lcWono = woentry.wono      
   -- 10/02/2013 DRP: Found that I had MatlType char (8) when it should have been MatlType char (10)  
   -- 03/28/14 VL changed from USED_INKIT = 'N' to USED_INKIT<>'Y' so it include 'N' and 'F'  
   -- 03/28/17 YS changed length of the part_no column from 25 to 35   
   -- 01/09/18 VL moved from later to here, also added phantomwcid char(8) that original was only in @tBom2 that Debbie added, so only need to use one table variable  
   DECLARE @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10)   
        ,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8)  
        ,Item_note varchar(max),Offset numeric(4,0),Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max)  
        ,U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5)  
        ,Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer,path varchar(max),sort varchar(max),UniqBomNo char(10)  
        --- 03/28/17 YS changed length of the part_no column from 25 to 35   
        ,SerialYes bit,phantomwcid char(8),CustPartNo char(35),CustRev char(8),CustUniqKey char(10))  
  
 -- 01/09/18 VL added to loop all wono  
 IF @lnWonoCount <> 0    
 BEGIN  
  WHILE @lnWonoCount > @lnCnt  
  BEGIN  
  SET @lnCnt = @lnCnt + 1   
  SELECT @lcWono = Wono FROM @tWono WHERE nId = @lnCnt  
  -- 01/09/18 VL moved from top  
  SET @lcWono=dbo.PADL(@lcWono,10,'0')  
  
     --11/01/13 VL added @lcPrjUnique  
     SELECT @WOuniq_key = Uniq_key,@lcKitStatus = woentry.KITSTATUS,@lcBomParent = woentry.UNIQ_KEY,@lcWoDueDate = Woentry.DUE_DATE, @lcPrjUnique =  PRJUNIQUE FROM WOENTRY WHERE WONO = @lcWoNo  
     SELECT @BomCustno = BomCustno FROM INVENTOR WHERE Uniq_key = @WOuniq_key  
  
     -- 09/28/12 VL   
     -- 01/09/18 VL delete all old records because the table variable will be used multiple times  
     DELETE FROM @AntiAvl4BomParentView WHERE 1 = 1  
     INSERT @AntiAvl4BomParentView EXEC [AntiAvl4BomParentView] @WoUniq_key  
  
     -- 10/01/12 VL moved SELECT @lcKitStatus from top to here, and return empty set if @@ROWCOUNT = 0  
     --select @lcKitStatus = woentry.KITSTATUS from WOENTRY where @lcWono = woentry.WONO   
     --03/13/2013 DRP:  IF @@ROWCOUNT <> 0  
     --03/13/2013 DRP:  BEGIN  
     --This section will then pull all of the detailed information from the KaMAIN tables because the kit has been put into process.    
     --Otherwise, if not in process ever we will then have to later pull from the BOM information    
       
      if ( @lcKitStatus <> '')  
      Begin  
       
      --The below will insert all of the detailed infromation that exists within the Kitting Module.  
      -- 01/09/18 VL delete all old records because the table variable will be used multiple times  
      DELETE FROM @ZKitMainView WHERE 1 = 1  
      INSERT @ZKitMainView EXEC [KitMainView] @lcwono   
        
        --This section of code had to be inserted to pull only the Not Used In Kit items from the BOM if the users elect to see those items. and add it to the KitMainView inserted above.   
        ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
        --02/15/2013 DRP:  Beta users were experiencing truncated data error.  Upon review I found that I used to have the Serial Yes at the end of the declared table @tbom, when it really  
        --     should have been after the UniqBomNo in the table.  They experienced a truncate error when the code tried to place a uniq_key into a Bit field.   
        --02/15/2013 DRP:  Also found that it was not removing Not Used in Kit items.  The if (@SupUsedKit = 0)statement was commented out to address this issue.   
        --if (@SupUsedKit = 0)  
         --begin  
  
         --declare  @lcBomParent char(10)  
           --@IncludeMakebuy bit = 1   
           -- ,@ShowIndentation bit =1  
           -- ,@UserId uniqueidentifier=NULL  
           -- ,@gridId varchar(50)= null   
              
         -- 01/09/18 VL delete all old record because the table variable will be used multiple times  
         DELETE FROM @tBom WHERE 1 = 1  
  
         ;  
         WITH BomExplode as (  
              SELECT B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc  
                ,CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo  
                ,CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,C.Part_class,C.Part_type,C.Descript,c.MATLTYPE  
                ,B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap, C.Setupscrap,M.USESETSCRP  
                ,M.STDBLDQTY, C.Phant_Make, C.StdCost, C.Make_buy, C.Status,cast(1.00 as numeric(9,2)) as TopQty,B.qty as Qty, cast(0 as Integer) as Level  
                ,'/'+CAST(bomparent as varchar(max)) as path,CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort  
                ,B.UNIQBOMNO,c.SERIALYES, cast('' as char(4)) as phantomwcid -- 01/09/18 VL copied the code that Debbie added on 05/27/2015 DRP: Added     
              FROM BOM_DET B   
                INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY   
                INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY   
              WHERE B.BOMPARENT=@lcBomParent   
                --and USED_INKIT = 'N'  
                --AND USED_INKIT <> 'Y'  
                -- 05/01/19 VL comment out 04/28/18 changes USED_INKIT = 'Y' to get all records. Found Debbie created this section of code for NOT used in Kit records,   
                -- so if user choose to see not used in KIT records, those records will be inserted into @results.  The records inserted into @results later from   
                -- @ZKitMainView don't have those not used_inkit item, change back to USED_INKIT <> 'Y'  
                -- 04/24/18 changed USED_INKIT <> 'Y' To USED_INKIT = 'Y' to get all the records that are used into Kit  
                AND USED_INKIT <> 'Y'  
         UNION ALL  
              SELECT  B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no  ,C2.PART_NO,C2.Revision,c2.Part_sourc   
                ,CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo  
                ,CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,C2.Part_class, C2.Part_type, C2.Descript,c2.MATLTYPE,B2.Dept_id  
                ,B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno,C2.Inv_note, C2.U_of_meas, C2.Scrap, C2.Setupscrap,M2.USESETSCRP,M2.STDBLDQTY  
                ,C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status,P.Qty as TopQty,B2.QTY, P.Level+1,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path   
                ,CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,B2.UNIQBOMNO,c2.SERIALYES    
                ,p.dept_id as phantomwcid -- 01/09/18 VL copied the code Debbie added on --05/27/2015 DRP:  Added        
              FROM BomExplode as P   
                INNER JOIN BOM_DET  B2 ON P.UNIQ_KEY =B2.BOMPARENT   
                INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY   
                INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY   
              WHERE P.PART_SOURC='PHANTOM'  
                or (p.PART_SOURC = 'MAKE' and P.PHANT_MAKE = 1)   
                --and P.USED_INKIT = 'N'  
                --and P.USED_INKIT <> 'Y'  
                -- 05/01/19 VL comment out 04/28/18 changes USED_INKIT = 'Y' to get all records. Found Debbie created this section of code for NOT used in Kit records,   
                -- so if user choose to see not used in KIT records, those records will be inserted into @results.  The records inserted into @results later from   
                -- @ZKitMainView don't have those not used_inkit item, change back to USED_INKIT <> 'Y'  
                -- 04/24/18 changed USED_INKIT <> 'Y' To USED_INKIT = 'Y' to get all the records that are used into Kit  
                and P.USED_INKIT <> 'Y'   
              )  
         --- 03/28/17 YS changed length of the part_no column from 25 to 35   
         insert into @tbom SELECT E.*,isnull(CustI.CUSTPARTNO,space(35)) as CustPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey    
              from BomExplode E   
                LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ   
                and E.BOMCUSTNO=CustI.CUSTNO   
              --02/17/15 VL copied the code to FILTER OUT OBSOLETED DATES FOR MAKE/PHANTOM LEVELS OF THE BOM, and only active parts    
              WHERE 1 = case when NOT @lcWoDuedate IS null then  
               case when (E.Eff_dt is null or DATEDIFF(day,E.EFF_DT,@lcWoDuedate)>=0)  
               AND (E.Term_dt is Null or DATEDIFF(day,E.TERM_DT,@lcWoDuedate)<0) THEN 1 ELSE 0 END  
               else 1  
               end  
              AND E.Status = 'Active'  
              ORDER BY sort OPTION (MAXRECURSION 100)  
         ;  
           
         -- 09/28/12 VL change first SQL LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY to LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY   
         -- so it link with internal part number records  
         WITH BomWithAvl AS (  
          -- 03/12/15 YS replaced invtmfhd table with 2 new tables  
              select B.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,B.MatlType as MfgrMatlType,MF.MATLTYPEVALUE   
              FROM @tBom B   
                ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
                --LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY   
                LEFT OUTER JOIN   
                (select l.uniq_key,M.PARTMFGR ,M.MFGR_PT_NO,L.ORDERPREF ,L.UNIQMFGRHD,M.MatlType,M.MATLTYPEVALUE   
                 FROM Mfgrmaster M INNER JOIN InvtmpnLink L on m.mfgrmasterid=l.mfgrmasterid   
                 where m.is_deleted=0 and l.is_deleted=0) MF  
                ON b.uniq_key=mf.uniq_key  
              WHERE B.CustUniqKey<>' '  
                --AND Invtmfhd.IS_DELETED =0   
                and NOT EXISTS (SELECT bomParent,UNIQ_KEY   
                    FROM ANTIAVL A   
                    where A.BOMPARENT =B.bomParent   
                      and A.UNIQ_KEY = B.CustUniqKey   
                      and A.PARTMFGR =mf.PARTMFGR   
                      and A.MFGR_PT_NO =mf.MFGR_PT_NO )  
         UNION ALL  
              -- 03/12/15 YS replaced invtmfhd table with 2 new tables  
              select B.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,B.MatlType as MfgrMatlType,MF.MATLTYPEVALUE   
              --select B.*,InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD,B.MatlType as MfgrMatlType,INVTMFHD.MATLTYPEVALUE  
              FROM @tBom B   
                ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
                --LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY   
                LEFT OUTER JOIN   
                (select l.uniq_key, M.PARTMFGR ,m.MFGR_PT_NO,L.ORDERPREF ,L.UNIQMFGRHD,M.MatlType,M.MATLTYPEVALUE   
                 FROM Mfgrmaster M INNER JOIN InvtmpnLink L on m.mfgrmasterid=l.mfgrmasterid   
                 where m.is_deleted=0 and l.is_deleted=0) MF  
                ON b.uniq_key=mf.uniq_key   
              WHERE B.CustUniqKey=' '  
                --AND Invtmfhd.IS_DELETED =0   
                and NOT EXISTS (SELECT bomParent,UNIQ_KEY   
                    FROM ANTIAVL A   
                    where A.BOMPARENT =B.bomParent   
                      and A.UNIQ_KEY = B.UNIQ_KEY   
                      and A.PARTMFGR =mf.PARTMFGR   
                      and A.MFGR_PT_NO =mf.MFGR_PT_NO )  
              )  
               
        -- 12/07/12 VL changed the calculation of ReqDate  
        -- 10/31/13 VL added cUniq_key  
        -- 11/05/13 VL remove invt_res code, need to use SUM(), will upcate QtyAllocKit later  
        insert into @results  
         select ISNULL(customer.custname,'') as CustName,woentry.Due_date  
           ,dbo.fn_GetWorkDayWithOffset(Due_date, i4.Prod_ltime*(CASE WHEN i4.Prod_lunit = 'DY' THEN 1 ELSE  
           CASE WHEN i4.PROD_LUNIT = 'WK' THEN 7 ELSE  
           CASE WHEN i4.PROD_LUNIT = 'MO' THEN 30 ELSE 1 END END END) +   
           i4.KIT_LTIME*(CASE WHEN i4.KIT_LUNIT = 'DY' THEN 1 ELSE  
           CASE WHEN i4.KIT_LUNIT = 'WK' THEN 7 ELSE  
           CASE WHEN i4.KIT_LUNIT = 'MO' THEN 30 ELSE 1 END END END),'-') AS ReqDate  
           ,i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE  
           ,woentry.BLDQTY,I4.PERPANEL,case when I4.perpanel = 0 then woentry.BLDQTY else cast(woentry.bldqty/i4.perpanel as numeric (7,0))end as PnlBlank  
           ,b1.ITEM_NO,Used_inKit,b1.viewpartno as DispPart_no,b1.ViewRevision as DispRevision  
           ,CEILING(case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)   
            else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
             else case when @lcIgnore = 'Ignore Setup Scrap' then case when i3.usesetscrp=1 then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2) else ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap  end  
              else case when @lcIgnore = 'Ignore Both Scraps' then case when i3.usesetscrp = 1 then  ((b1.topqty*b1.qty)*woentry.BLDQTY) else ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap end  end end end end) as Req_Qty  
 --01/12/17 DRP:       ,CEILING(case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)   
            --else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
            -- else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)  
            --  else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end) as Req_Qty  
 --01/17/2014 DRP:      ,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)   
            --else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
            -- else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)  
            --  else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end as Req_Qty  
           ,CASE when woentry.UNIQ_KEY =  B1.BomParent THEN ' ' ELSE 'f' end as Phantom,b1.Part_class,b1.Part_type,CAST('' as char(10)) as kaseqnum  
           ,CAST(0 as bit) as kitclosed,CAST(0.00 as numeric(5,2)) as Act_qty,b1.UNIQ_KEY,b1.Dept_id,depts.DEPT_NAME,woentry.WONO,woentry.sono,b1.scrap  
           ,b1.SetupScrap,b1.bomParent  
           ,CEILING(case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)   
            else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
             else case when @lcIgnore = 'Ignore Setup Scrap' then case when i3.usesetscrp = 1 then  ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2) else ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap end  
              else case when @lcIgnore = 'Ignore Both Scraps' then case when i3.usesetscrp = 1 then ((b1.topqty*b1.qty)*woentry.BLDQTY) else ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap end end end end end) as ShortQty  
 --01/12/17 DRP:       ,CEILING(case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)   
            --else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
            -- else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)  
            --  else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end) as ShortQty  
 --01/17/2014 DRP:       ,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)   
 --           else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
 --            else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)  
 --             else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end as ShortQty  
           ,CAST (0 as bit) as lineshort,b1.Part_sourc,b1.TopQty*b1.qty as Qty,b1.Descript,b1.U_of_meas,b1.PART_NO,b1.CustPartNo,CAST(0 as bit) as Ignorekit  
           ,CAST (0 as bit) as Phant_make,B1.serialyes,b1.Revision,b1.MatlType,b1.CustRev,invtmfgr.location,warehous.WAREHOUSE,invtmfgr.QTY_OH  
           ,Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved  
           --,case when (invt_res.QTYALLOC IS null) then 0000000000.00 else invt_res.QTYALLOC end as QtyAllocKit  
           ,0000000000.00 AS QtyAllocKit    
           ,case when (antiavl.PARTMFGR is null) then 'A' else '' end as antiAVL  
           ,b1.PARTMFGR,b1.MFGR_PT_NO,b1.MfgrMatlType,b1.ORDERPREF,b1.UNIQMFGRHD,isnull(invtlot.LOTCODE,''),invtlot.expdate,ISNULL(invtlot.REFERENCE,''),ISNULL(invtlot.ponum,'')  
           ,isnull(invtlot.LOTQTY,0.00),isnull(invtlot.LOTQTY-invtlot.LOTRESQTY,0.00),isnull(invtlot.UNIQ_LOT,''),case when woentry.uniq_key = B1.bomparent then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn  
           ,cast ('' as char(25)) as phparentwc --05/27/2015 DRP:  Added  
           ,INVTMFGR.INSTORE, B1.CustUniqKey AS cUniq_key, invtmfgr.w_key  
           -- 01/09/18 VL added KitStatus for update lKitIgnoreScrap later  
           ,KitStatus  
         from WOENTRY   
           inner join BomWithAvl as B1 on woentry.UNIQ_KEY =  right(Left(b1.path,11),10)  
           inner join CUSTOMER on woentry.CUSTNO = CUSTOMER.CUSTNO  
           inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY  
           left outer join DEPTS on b1.Dept_id = depts.DEPT_ID  
           inner join INVTMFGR on b1.uniqmfgrhd = invtmfgr.uniqmfgrhd  
           inner join warehous on invtmfgr.uniqwh = warehous.uniqwh  
           left outer join INVT_RES on woentry.Wono = invt_res.WONO and invtmfgr.W_KEY = invt_res.W_KEY   
           left outer join ANTIAVL on B1.Bomparent = ANTIAVL.BOMPARENT and b1.Uniq_key = ANTIAVL.UNIQ_KEY and b1.PARTMFGR = ANTIAVL.PARTMFGR and b1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO  
           left outer join INVENTOR as I3 on b1.BomParent = I3.UNIQ_KEY  
           left outer join INVTLOT on invtmfgr.W_KEY = INVTLOT.W_KEY  
           
         where @lcWono = woentry.WONO  
           AND B1.part_sourc <> 'PHANTOM'  
           AND B1.Phantom_make <> 1  
           and used_inkit = case when @SupUsedKit = 0 then Used_inKit else (select Used_inKit where Used_inKit <> 'N') end  
           and woentry.OPENCLOS not in ('ClOSED','CANCEL','ARCHIVED')     
           and WAREHOUS.WAREHOUSE <> 'MRB'  
           -- 05/01/19 VL added warehouse filter  
           and (@lcUniqWH='All' OR EXISTS (SELECT 1 FROM @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=Invtmfgr.uniqwh))  
           -- 10/31/13 VL added to set antiavl is null (no antiavl)  
           AND antiavl.PARTMFGR is null  
         --end  
     ---------- End of the Not Used In Kit Code.  
     ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
      -- 01/09/18 VL delete all old record because the table variable will be used multiple times  
      DELETE FROM @KitInvtView WHERE 1 = 1  
 ;        
      ;  
      -- 11/01/13 VL remove invt_res because can not link directly, has to use SUM() then link to get right qty, otherwise if a part is reserved more than one time, here will cause multiple records  
      WITH ZKitInvt1 AS  
       (  
       SELECT DISTINCT invtmfgr.qty_oh  
        ,Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved  
        --,case when kitmainview.Wono = invt_res.WONO and invtmfgr.W_KEY = invt_res.W_KEY   
        -- then Invtmfgr.qty_oh-Invtmfgr.reserved + (case when (invt_res.QTYALLOC IS null) then 0000000000.00 else invt_res.QTYALLOC end)   
        --  else Invtmfgr.qty_oh-Invtmfgr.reserved end AS QtyNotReserved  
        --,case when (invt_res.QTYALLOC IS null) then 0000000000.00 else invt_res.QTYALLOC end as QtyAllocKit,  
        , 0000000000.00 AS QtyAllocKit,  
        Kitmainview.Kaseqnum, Kitmainview.uniq_key, Kitmainview.BomParent, Kitmainview.Part_sourc,  
        ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
        M.Partmfgr, M.Mfgr_pt_no, Warehous.Wh_gl_nbr, Invtmfgr.UniqWh,  
        Invtmfgr.Location, Invtmfgr.W_key, Invtmfgr.InStore, InvtMfgr.UniqSupNo, Invtmfgr.CountFlag,  
        Warehous.Warehouse, l.OrderPref, L.UniqMfgrHd, Invtmfgr.NetAble, M.lDisallowKit,M.MATLTYPE as MfgrMtlType  
       FROM @ZKitMainView as KitMainView  
        inner join invtmfgr on KitMainView.Uniq_key = invtmfgr.uniq_key  
        ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
        --inner join invtmfhd on invtmfgr.uniqmfgrhd = invtmfhd.uniqmfgrhd  
        INNER JOIN Invtmpnlink L ON invtmfgr.uniqmfgrhd = L.uniqmfgrhd  
        INNER JOIN Mfgrmaster M ON m.mfgrmasterid=l.mfgrmasterid  
        inner join warehous on invtmfgr.uniqwh = warehous.uniqwh  
        --left outer join INVT_RES on kitmainview.Wono = invt_res.WONO and invtmfgr.W_KEY = invt_res.W_KEY    
       WHERE Kitmainview.Uniq_key = Invtmfgr.uniq_key   
        --03/12/15 YS already joined  
        --AND Invtmfhd.UniqMfgrHd = Invtmfgr.UniqMfgrHd   
        AND M.lDisallowKit = 0  
        AND ((@llKitAllowNonNettable = 1) OR (@llKitAllowNonNettable = 0 and Invtmfgr.NetAble=1))  
        AND L.Is_deleted = 0 and m.is_deleted=0  
        --03/12/15 YS already joined  
        --AND Invtmfgr.UniqWh = Warehous.UniqWh  
        AND  Warehouse<>'MRB'  
        -- 05/01/19 VL added warehouse filter  
        and (@lcUniqWH='All' OR EXISTS (SELECT 1 FROM @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=Invtmfgr.uniqwh))  
        AND Invtmfgr.Is_Deleted = 0  
       )  
  
      INSERT @KitInvtView   
  
      SELECT DISTINCT qty_oh,QtyNotReserved,QtyAllocKit,ZKitInvt1.Kaseqnum, ZKitInvt1.Uniq_key, ZKitInvt1.BomParent, ZKitInvt1.Part_sourc  
          ,case when (antiavl.PARTMFGR is null) then 'A' else '' end as antiAVL, ZKitInvt1.Partmfgr,ZKitInvt1.Mfgr_pt_no  
          ,ZKitInvt1.wh_gl_nbr,ZKitInvt1.UniqWh,ZKitInvt1.Location,ZKitInvt1.W_key,ZKitInvt1.InStore,ZKitInvt1.UniqSupno  
          ,ZKitInvt1.Warehouse,ZKitInvt1.CountFlag, ZKitInvt1.OrderPref, ZKitInvt1.UniqMfgrhd,ZKitInvt1.MfgrMtlType  
          ,CASE WHEN (Inventor.UNIQ_KEY IS NULL) THEN ZKitInvt1.Uniq_key ELSE Inventor.UNIQ_KEY END AS cUniq_key  
      FROM   ZKitInvt1   
          left outer join ANTIAVL on ZKitInvt1.Bomparent = ANTIAVL.BOMPARENT   
              and ZKitInvt1.Uniq_key = ANTIAVL.UNIQ_KEY   
              and ZKitInvt1.PARTMFGR = ANTIAVL.PARTMFGR   
              and ZKitInvt1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO  
          LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key=inventor.int_uniq and @BomCustno=Inventor.Custno  
          --LEFT OUTER JOIN INVENTOR ON ZKitInvt1.Uniq_key+@BomCustno=Inventor.INT_UNIQ+Inventor.Custno --01/29/16 DRP:  replaced with the above  
      ORDER BY  Partmfgr, Warehouse, Location  
   
     -- 09/28/12 VL   
     
     -- Now the cUniq_key can link to Antiavl info  
     -- will join with antiavl (with cUniq_key) and invtmfhd, if no record in invtmfhd, will not update Antiavl with 'A'  
     -- 10/31/13 VL changed to use LEFT OUTER JOIN and set criterial to have cUniq_key<>''  
     ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
     UPDATE @KitInvtView  
      SET AntiAvl = CASE WHEN (Mf.UNIQ_KEY IS NULL) THEN ' ' ELSE 'A' END  
      FROM @KitInvtView KitInvtView LEFT OUTER JOIN   
      (SELECT Uniq_key,partmfgr,mfgr_pt_no,uniqmfgrhd   
       FROM INVTMPNLINK L INNER JOIN Mfgrmaster M   
        on l.mfgrmasterid=m.mfgrmasterid and m.is_deleted=0 and l.is_deleted=0) MF  
      ON KitInvtView.cUniq_key = MF.UNIQ_KEY  
      AND KitInvtView.Partmfgr = MF.PARTMFGR  
      AND KitInvtView.Mfgr_pt_no = MF.MFGR_PT_NO  
      --AND InvtMfhd.IS_DELETED = 0  
      WHERE KitInvtView.cUniq_key<>''  
  
     -- 09/24/13 VL changed the update SQL to use LEFT OUTER JOIN, so the antiavl can be updated correctly, also changed the antiavl field  
     -- 10/31/13 VL changed to use LEFT OUTER JOIN and set criterial to have cUniq_key<>'', also added antiavl = 'A' that some records in previous UPDATE SQL might already set to ' ', this SQL might cause it to have 'A' again, need to filter out  
     ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
     UPDATE @KitInvtView  
      SET AntiAvl = CASE WHEN (AntiAvl4BomParentView.UNIQ_KEY IS NULL) THEN 'A' ELSE ' ' END  
      FROM @KitInvtView KitInvtView LEFT OUTER JOIN @AntiAvl4BomParentView AntiAvl4BomParentView  
      ON KitInvtView.cUniq_key = AntiAvl4BomParentView.UNIQ_KEY  
      AND KitInvtView.Partmfgr = AntiAvl4BomParentView.PARTMFGR  
      AND KitInvtView.Mfgr_pt_no = AntiAvl4BomParentView.MFGR_PT_NO  
      WHERE cUniq_key<>''  
      AND AntiAvl = 'A'  
      
      -- SQL result   
      -- 12/07/12 VL changed the calculation of ReqDate  
      -- 11/01/13 VL added w_key  
     insert into @results  
      SELECT DISTINCT isnull(CUSTOMER.CUSTNAME,'') as CustName,woentry.DUE_DATE  
        ,dbo.fn_GetWorkDayWithOffset(Due_date,i4.Prod_ltime*(CASE WHEN i4.Prod_lunit = 'DY' THEN 1 ELSE  
           CASE WHEN i4.PROD_LUNIT = 'WK' THEN 7 ELSE  
           CASE WHEN i4.PROD_LUNIT = 'MO' THEN 30 ELSE 1 END END END) +   
           i4.KIT_LTIME*(CASE WHEN i4.KIT_LUNIT = 'DY' THEN 1 ELSE  
           CASE WHEN i4.KIT_LUNIT = 'WK' THEN 7 ELSE  
           CASE WHEN i4.KIT_LUNIT = 'MO' THEN 30 ELSE 1 END END END),'-') AS ReqDate  
        ,i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE  
        ,woentry.BLDQTY,I4.PERPANEL,case when I4.perpanel = 0 then woentry.BLDQTY else cast(woentry.bldqty/i4.perpanel as numeric (7,0))end as PnlBlank  
        ,bom_det.ITEM_NO,USED_INKIT,zmain2.DispPart_no,ZMain2.DispRevision  
        --,zmain2.Req_Qty --11/08/16 DRP:  replaced with the below  
          --,ceiling(case when @KitIgnoreScrap = 0 and @lcIgnore = 'No' then zmain2.Req_Qty  
          --   else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Scrap' then ZMain2.Req_Qty - ZMain2.Scrap   
          --    else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Setup Scrap' then ZMain2.Req_Qty - ZMain2.Setupscrap  
          --     else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Both Scraps' then ZMain2.Req_Qty - ZMain2.Setupscrap - zmain2.scrap   
          --      else case when @KitIgnoreScrap = 1 then zmain2.req_qty  
          --      end  end  end  end end ) as ReqQty --11/09/16 DRP:  replaced with the below  to account for Phantam items already calculated into the kitmainview that I am using  
          ,ceiling (case when @lcIgnore = 'No' then zmain2.Req_Qty  
           else case when @lcIgnore = 'Ignore Scrap' then   
           case when zmain2.phantom = 'f' then zmain2.Req_Qty - round((zmain2.qty *zmain2.Scrap)/100,0) else ZMain2.Req_Qty - round(((zmain2.Qty * woentry.bldqty)* zmain2.scrap)/100,0) end  
             else case when  @lcIgnore = 'Ignore Setup Scrap' then case when i4.usesetscrp = 1 then ZMain2.Req_Qty - ZMain2.Setupscrap else  case when zmain2.phantom = 'f' then zmain2.Req_Qty - round((zmain2.qty *zmain2.Scrap)/100,0)   
             else ZMain2.Req_Qty - round(((zmain2.Qty * woentry.bldqty)* zmain2.scrap)/100,0) end end  
             else case when  @lcIgnore = 'Ignore Both Scraps' then case when i4.usesetscrp = 1 then   
                case when zmain2.phantom = 'f' then zmain2.Req_Qty - ZMain2.Setupscrap - round((zmain2.qty *zmain2.Scrap)/100,0) else ZMain2.Req_Qty - zmain2.Setupscrap- round(((zmain2.Qty * woentry.bldqty)* zmain2.scrap)/100,0) end else case when zmain2
.phantom = 'f' then zmain2.Req_Qty - round((zmain2.qty *zmain2.Scrap)/100,0) else ZMain2.Req_Qty - round(((zmain2.Qty * woentry.bldqty)* zmain2.scrap)/100,0) end end  
            end end end end) as ReqQty  
 --01/12/17 DRP:      ,ceiling (case when @KitIgnoreScrap = 0 and @lcIgnore = 'No' then zmain2.Req_Qty  
           --else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Scrap' then   
           --case when zmain2.phantom = 'f' then zmain2.Req_Qty - round((zmain2.qty *zmain2.Scrap)/100,0) else ZMain2.Req_Qty - round(((zmain2.Qty * woentry.bldqty)* zmain2.scrap)/100,0) end  
           --  else case when  @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Setup Scrap' then ZMain2.Req_Qty - ZMain2.Setupscrap   
           --   else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Both Scraps' then   
           --   case when zmain2.phantom = 'f' then zmain2.Req_Qty - ZMain2.Setupscrap - round((zmain2.qty *zmain2.Scrap)/100,0) else ZMain2.Req_Qty - zmain2.Setupscrap- round(((zmain2.Qty * woentry.bldqty)* zmain2.scrap)/100,0) end  
           -- end end end end) as ReqQty  
 --/*04/02/2014*/    ,CEILING(case when @lcIgnore = 'No' then ZMain2.Req_Qty  
 --        else case when @lcIgnore = 'Ignore Scrap' then zmain2.Req_Qty-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,2)  
 --         else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.req_qty-zmain2.setupscrap  
 --          else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.req_qty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,2) end end end end) as Req_Qty  
 --01/17/2014 DRP:   ,case when @lcIgnore = 'No' then ZMain2.Req_Qty  
         --else case when @lcIgnore = 'Ignore Scrap' then zmain2.Req_Qty-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)  
         -- else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.req_qty-zmain2.setupscrap  
         --  else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.req_qty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as Req_Qty  
        ,ZMain2.Phantom,ZMain2.Part_class,ZMain2.Part_type,ZMain2.Kaseqnum,ZMain2.Kitclosed,ZMain2.Act_qty,zmain2.Uniq_key,ZMain2.Dept_id,ZMain2.Dept_name  
        ,ZMain2.Wono,woentry.SONO,ZMain2.Scrap,ZMain2.Setupscrap,ZMain2.Bomparent  
        --,zmain2.Shortqty 11/08/16 DRP: replaced with the below  
        --,ceiling(case when @KitIgnoreScrap = 0 and @lcIgnore = 'No' then zmain2.Shortqty  
          --   else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Scrap' then ZMain2.Shortqty - ZMain2.Scrap   
          --    else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Setup Scrap' then ZMain2.Shortqty - ZMain2.Setupscrap  
          --     else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Both Scraps' then ZMain2.Shortqty - ZMain2.Setupscrap - zmain2.scrap   
          --      else case when @KitIgnoreScrap = 1 then zmain2.Shortqty  
          --      end  end  end  end end ) as Shortqty --11/09/16 DRP: replaced with the below  to account for Phantam items already calculated into the kitmainview that I am using   
        ,ceiling(case when @lcIgnore = 'No' then zmain2.Shortqty  
             else case when @lcIgnore = 'Ignore Scrap' then   
             case when ZMain2.Phantom = 'f' then  ZMain2.Shortqty - round((zmain2.qty *zmain2.Scrap)/100,0) else zmain2.shortqty - round(((zmain2.Qty * woentry.BLDQTY) * zmain2.scrap)/100,0) end   
              else case when  @lcIgnore = 'Ignore Setup Scrap' then case when i4.usesetscrp = 1 then ZMain2.Shortqty - ZMain2.Setupscrap   
              else case when ZMain2.Phantom = 'f' then  ZMain2.Shortqty - round((zmain2.qty *zmain2.Scrap)/100,0) else zmain2.shortqty - round(((zmain2.Qty * woentry.BLDQTY) * zmain2.scrap)/100,0) end end  
              else case when  @lcIgnore = 'Ignore Both Scraps' then case when i4.usesetscrp = 1 then   
             case when zmain2.phantom = 'f' then zmain2.Shortqty - ZMain2.Setupscrap - round((zmain2.qty *zmain2.Scrap)/100,0) else    ZMain2.Shortqty - zmain2.Setupscrap - round(((zmain2.Qty * woentry.bldqty) * zmain2.scrap)/100,0) end   
             else case when ZMain2.Phantom = 'f' then  ZMain2.Shortqty - round((zmain2.qty *zmain2.Scrap)/100,0) else zmain2.shortqty - round(((zmain2.Qty * woentry.BLDQTY) * zmain2.scrap)/100,0) end  end   
             end  end  end  end ) as Shortqty  
 --01/12/17 DRP:     ,ceiling(case when @KitIgnoreScrap = 0 and @lcIgnore = 'No' then zmain2.Shortqty  
             --else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Scrap' then   
             --case when ZMain2.Phantom = 'f' then  ZMain2.Shortqty - round((zmain2.qty *zmain2.Scrap)/100,0) else zmain2.shortqty - round(((zmain2.Qty * woentry.BLDQTY) * zmain2.scrap)/100,0) end   
             -- else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Setup Scrap' then ZMain2.Shortqty - ZMain2.Setupscrap  
             --  else case when @KitIgnoreScrap = 0 and @lcIgnore = 'Ignore Both Scraps' then   
             --  case when zmain2.phantom = 'f' then zmain2.Shortqty - ZMain2.Setupscrap - round((zmain2.qty *zmain2.Scrap)/100,0) else   ZMain2.Shortqty - zmain2.Setupscrap - round(((zmain2.Qty * woentry.bldqty) * zmain2.scrap)/100,0) end  
             --   else case when @KitIgnoreScrap = 1 then zmain2.Shortqty  
             --   end  end  end  end end ) as Shortqty  
 --/*04/02/2014*/    ,CEILING(case when @lcIgnore = 'No' then ZMain2.ShortQty  
 --        else case when @lcIgnore = 'Ignore Scrap' then zmain2.Shortqty - round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,2)  
 --         else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.shortqty-zmain2.setupscrap  
 --          else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.shortqty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,2) end end end end) as ShortQty  
 --01/17/2014 DRP:   ,case when @lcIgnore = 'No' then ZMain2.ShortQty  
         --else case when @lcIgnore = 'Ignore Scrap' then zmain2.Shortqty - round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0)  
         -- else case when @lcIgnore = 'Ignore Setup Scrap' then zmain2.shortqty-zmain2.setupscrap  
         --  else case when @lcIgnore = 'Ignore Both Scraps' then zmain2.shortqty-zmain2.setupscrap-round(((WOENTRY.bldqty*zmain2.Qty)*zmain2.scrap)/100,0) end end end end as ShortQty  
        ,ZMain2.Lineshort,ZMain2.Part_sourc,ZMain2.Qty,ZMain2.Descript,ZMain2.U_of_meas,ZMain2.Part_no,ZMain2.Custpartno,ZMain2.Ignorekit  
        ,ZMain2.Phant_make,ZMain2.Serialyes,ZMain2.Revision,ZMain2.Matltype,ZMain2.CustRev,zinvtv2.location,zinvtv2.Warehouse,zinvtv2.qty_oh, ZInvtV2.QtyNotReserved, zinvtv2.QtyAllocKit, zinvtV2.AntiAvl  
        , ZInvtV2.Partmfgr, ZInvtV2.Mfgr_pt_no, zinvtv2.MfgrMtlType, ZInvtV2.OrderPref, ZInvtV2.UniqMfgrhd,isnull(invtlot.LOTCODE,''),invtlot.expdate,ISNULL(invtlot.REFERENCE,''),ISNULL(invtlot.ponum,'')  
        ,isnull(invtlot.LOTQTY,0.00),isnull(invtlot.LOTQTY-invtlot.LOTRESQTY,0.00),isnull(invtlot.uniq_lot,''),case when ZMain2.Phantom = 'f' then rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) else ''end as PhParentPn  
        ,cast('' as char(25)) as phparentwc --05/27/2015 DRP:  Added  
        ,INSTORE, ZInvtV2.cUniq_key, ZinvtV2.W_key  
        -- 01/09/18 VL added KitStatus for update lKitIgnoreScrap later  
        ,KitStatus  
      FROM @ZKitMainView as ZMain2  
        inner join @KitInvtView as ZInvtV2  on ZMain2.Uniq_key = ZInvtV2.Uniq_key  
        left outer join INVENTOR as I3 on ZInvtV2.BomParent = I3.UNIQ_KEY  
        left outer join BOM_DET on ZInvtV2.BomParent = bom_det.BOMPARENT and ZInvtV2.Uniq_key = bom_det.UNIQ_KEY AND ZMain2.Dept_id = Bom_det.DEPT_ID              
        inner join WOENTRY on zmain2.Wono = woentry.wono  
        inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO  
        inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY  
        left outer join INVTLOT on ZInvtV2.W_key = INVTLOT.W_KEY  
  
      WHERE woentry.OPENCLOS not in ('ClOSED','CANCEL','ARCHIVED')   
        --AND zmain2.Dept_id like case when @lcDeptId ='*' then '%' else @lcDeptId+'%' end  --08/07/15 DRP:  replaced with the above and /*DEPARTMET LIST*/--11/16/15 DRP:  replaced by the above.  
        AND (@lcDeptId='All' OR exists (select 1 from @Depts d inner join Depts d2 on d.dept_id=d2.DEPT_ID where d.dept_id=zmain2.dept_id))  
   --11/26/2012 DRP:  added the below filter in the situation that the same part could be associated to more than one item Actvie or OB    
        and 1 = case when NOT woentry.DUE_DATE IS null then   
             case when (Eff_dt is null or DATEDIFF(day,EFF_DT,woentry.DUE_DATE)>=0)  
             AND (Term_dt is Null or DATEDIFF(day,TERM_DT,woentry.DUE_DATE)<0) THEN 1 ELSE 0 END  
            ELSE 1  
            END  
        -- 09/24/13 VL added Antiavl = 'A' criteria  
        AND ANTIAVL='A'   
            
      -- 11/01/13 VL added code to update QtyNotReserved from WO/PJ allocation  
      -- 01/09/18 VL delete all old record because the table variable will be used multiple times  
      DELETE FROM @ZWoAlloc WHERE 1 = 1  
      INSERT @ZWoAlloc EXEC WoAllocatedView @lcWono  
              
      -- Update LotQtyAvail field  
      UPDATE @results SET LotQtyAvail = CASE WHEN ZWoAlloc.QtyAlloc IS NULL THEN LotQtyAvail ELSE LotQtyAvail+ZWoAlloc.Qtyalloc END  
       FROM @results Results LEFT OUTER JOIN @ZWoAlloc ZWoAlloc  
       ON Results.W_key = ZWoAlloc.W_key  
       AND Results.LotCode = ZWoAlloc.LotCode  
       AND ISNULL(Results.ExpDate,1) = ISNULL(ZWoAlloc.ExpDate,1)  
       AND Results.Reference = ZWoAlloc.REFERENCE  
       AND Results.PoNum = ZWoAlloc.PoNum  
       WHERE Results.LotCode<>''  
       -- 01/09/18 VL added to only update wono = @lcWono  
       AND Results.Wono = @lcWoNo  
      -- Update QtyNotReserved, need to group @ZWoAlloc by W_key  
      ;WITH ZWoAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZWoAlloc GROUP BY W_key)  
      UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZWoAllocSumW_key WHERE Results.W_key=ZWoAllocSumW_key.W_key  
       -- 01/09/18 VL added to only update wono = @lcWono  
       AND Results.Wono = @lcWoNo  
  
  
      -- If this WO link to PJ  
      IF @lcPrjUnique<>''  
       BEGIN  
       -- 01/09/18 VL delete all old record because the table variable will be used multiple times  
       DELETE FROM @ZPJAlloc WHERE 1 = 1  
  
       INSERT @ZPJAlloc EXEC Invt_res4PJView @lcPrjUnique  
       UPDATE @results SET LotQtyAvail = CASE WHEN ZPjAlloc.QtyAlloc IS NULL THEN LotQtyAvail ELSE LotQtyAvail+ZPjAlloc.Qtyalloc END  
        FROM @results Results LEFT OUTER JOIN @ZPJAlloc ZPjAlloc  
        ON Results.W_key = ZPjAlloc.W_key  
        AND Results.LotCode = ZPjAlloc.LotCode  
        AND ISNULL(Results.ExpDate,1) = ISNULL(ZPjAlloc.ExpDate,1)  
        AND Results.Reference = ZPjAlloc.REFERENCE  
        AND Results.PoNum = ZPjAlloc.PoNum  
        WHERE Results.LotCode<>''  
        -- 01/09/18 VL added to only update wono = @lcWono  
        AND Results.Wono = @lcWoNo  
  
      -- Update QtyNotReserved, need to group @ZPJAlloc by W_key  
      ;WITH ZPJAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZPJAlloc GROUP BY W_key)  
      UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZPJAllocSumW_key WHERE Results.W_key=ZPJAllocSumW_key.W_key  
       -- 01/09/18 VL added to only update wono = @lcWono  
       AND Results.Wono = @lcWoNo  
         
      END  
      -- 11/01/13 VL End}  
  
  
     /*updating the PhParentWc information*/ --05/27/2015 DRP:  Added  
      update @results set phparentwc = d.dept_name   
      from depts d   
        inner join bom_det b on d.DEPT_ID=b.DEPT_ID   
        inner join @results R on r.BomParent=b.UNIQ_KEY and b.BOMPARENT=@lcBomParent and r.phantom='f'  
        -- 01/09/18 VL added to only update wono = @lcWono  
        WHERE Wono = @lcWoNo  
        -- end of Updating PhParentWc  
     -- 01/09/18 VL moved the final SQL part to the last, outside of the loop  
      --select R1.*,MICSSYS.lic_name ,invtsetup.lSuppressZeroInvt,  
      --  @KitIgnoreScrap as lKitIgnoreScrap --11/08/16 DRP:  Added  
      --from @results as R1   
      --  cross join MICSSYS   
      --  cross join invtsetup  
     --04/22/2013 DRP removed and added to the crystal report  
      --where Qty_Oh = case when @SupZero = 0 then Qty_Oh else (select Qty_Oh where Qty_Oh > 0.00) end  
  
     end  
  
  
     --if the kit has never been put into process then the below section will gather the information from the Bill of Material  
      else if ( @lcKitStatus = '')  
      begin  
       
      --declare @lcWoDuedate as smalldatetime = ''  
            
      --select @lcBomParent = woentry.UNIQ_KEY,@lcWoDueDate = Woentry.DUE_DATE from WOENTRY where @lcWono = woentry.wono      
  
   --10/02/2013 DRP:  Found that I had MatlType char (8) when it should have been MatlType char (10)  
   --- 03/28/17 YS changed length of the part_no column from 25 to 35   
   -- 01/09/18 VL moved the declare code to the beginning  
      --declare @tBom2 table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10)   
      --     ,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8)  
      --     ,Item_note varchar(max),Offset numeric(4,0),Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max)  
      --     ,U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5)  
      --     ,Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer,path varchar(max),sort varchar(max),UniqBomNo char(10)  
      --     --- 03/28/17 YS changed length of the part_no column from 25 to 35   
      --     ,SerialYes bit,phantomwcid char(8),CustPartNo char(35),CustRev char(8),CustUniqKey char(10))  
  
      -- 01/09/18 VL delete all old record because the table variable will be used multiple times  
      DELETE FROM @tBom WHERE 1 = 1  
      ;  
      WITH BomExplode as (  
           SELECT B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc  
             ,CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END as varchar(max)) AS ViewPartNo  
             ,CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,C.Part_class,C.Part_type,C.Descript,c.MATLTYPE  
             ,B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap--, C.Setupscrap --01/12/17 DRP:  replaced with below  
             ,case when M.USESETSCRP = 1 then C.Setupscrap else 0 end as SetupScrap  
             ,M.USESETSCRP  
             ,M.STDBLDQTY, C.Phant_Make, C.StdCost, C.Make_buy, C.Status,cast(1.00 as numeric(9,2)) as TopQty,B.qty as Qty, cast(0 as Integer) as Level  
             ,'/'+CAST(bomparent as varchar(max)) as path,CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort  
             ,B.UNIQBOMNO,c.SERIALYES,cast('' as char(4)) as phantomwcid --05/27/2015 DRP: Added   
           FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY   
             INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY   
           WHERE B.BOMPARENT=@lcBomParent   
      --11/26/2012 DRP:  in the case that the kit is not in process yet the below needed to be added to make sure only active items are pulled from the BOM  
             and 1 = case when NOT @lcWoDuedate IS null then   
             case when (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcWoDuedate)>=0)  
             AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcWoDuedate)<0) THEN 1 ELSE 0 END  
            ELSE 1  
            END  
            --)   
            -- 02/17/15 VL added to only pick active parts  
            AND C.Status = 'Active'  
  --    select * from BomExplode       
  --end       
      UNION ALL  
        
           SELECT  B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no  ,C2.PART_NO,C2.Revision,c2.Part_sourc   
             ,CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo  
             ,CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,C2.Part_class, C2.Part_type, C2.Descript,c2.MATLTYPE,B2.Dept_id  
             ,B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno,C2.Inv_note, C2.U_of_meas, C2.Scrap-- C2.Setupscrap --01/12/17 DRP:  replaced with below  
             ,case when M2.USESETSCRP = 1 then C2.Setupscrap else 0 end as SetupScrap   
             ,M2.USESETSCRP,M2.STDBLDQTY  
             ,C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status,P.Qty as TopQty,B2.QTY, P.Level+1,CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path   
             ,CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,B2.UNIQBOMNO,C2.SERIALYES     
             ,p.dept_id as phantomwcid --05/27/2015 DRP:  Added    
           FROM BomExplode as P   
             INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT   
             INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY   
             INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY   
           WHERE P.PART_SOURC='PHANTOM'  
             or (p.PART_SOURC = 'MAKE' and P.PHANT_MAKE = 1)   
      --12/16/2013 DRP:  NEEDED TO ADD THE STATEMENT BELOW SO THAT THE RESULTS WOULD PROPERLY FILTER OUT OBSOLETED DATES FOR MAKE/PHANTOM LEVELS OF THE BOM      
             and 1 = case when NOT @lcWoDuedate IS null then   
             case when (B2.Eff_dt is null or DATEDIFF(day,b2.EFF_DT,@lcWoDuedate)>=0)  
             AND (b2.Term_dt is Null or DATEDIFF(day,b2.TERM_DT,@lcWoDuedate)<0) THEN 1 ELSE 0 END  
             else 1  
             end  
             -- 02/17/15 VL added to only pick active parts  
             AND C2.Status = 'Active'  
             
           --**THE BELOW WAS THE CODE THAT YELENA WAS USING WITHIN THE BOMINDENTED PROCEDURE, BUT IT DID NOT WORK FOR THIS REPORT  
           --**SO I TOOK THE ENTIRE CODE FROM THE PROCEDURE AND MADE THE BELOW CHANGES BY REMOVING THE BELOW   
             --or (P.PART_SOURC = 'MAKE' and P.MAKE_BUY = 1)   
             --or (P.PART_SOURC='MAKE' and P.MAKE_BUY=CASE WHEN @IncludeMakeBuy=1 THEN P.MAKE_BUY ELSE 0 END)  
           )  
            
      --- 03/28/17 YS changed length of the part_no column from 25 to 35   
      -- 01/09/18 VL changed from @tBom2 to @tBom  
      insert into @tbom SELECT E.*,isnull(CustI.CUSTPARTNO,space(25)) as CustPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey    
           from BomExplode E   
             LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ   
             and E.BOMCUSTNO=CustI.CUSTNO   
           ORDER BY sort OPTION (MAXRECURSION 100)  
      ;  
      -- 09/28/12 VL change first SQL LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY to LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY   
      -- so it link with internal part number records  
      -- 03/29/16 DRP:  Changed <<B2.MatlType as MfgrMatlType>> to be <<invtmfhd.MatlType as MfgrMatlType>> so it pulled from the mfgr material type not part number level.   
      -- 01/09/18 VL changed from @tBom2 to @tBom  
      WITH BomWithAvl AS (  
           ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
           select B2.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,MF.MatlType as MfgrMatlType,MF.MATLTYPEVALUE   
           FROM @tBom B2   
             --LEFT OUTER JOIN INVTMFHD ON B2.Uniq_Key=INVTMFHD.UNIQ_KEY   
             ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
             LEFT OUTER JOIN   
             (Select l.uniq_key,m.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MatlType ,M.MATLTYPEVALUE   
              FROM mfgrMaster M INNER JOIN Invtmpnlink L on m.mfgrmasterid=l.mfgrmasterid where m.is_deleted=0 and l.is_deleted=0) mf  
             ON B2.Uniq_Key=MF.UNIQ_KEY   
           WHERE B2.CustUniqKey<>' '  
            -- AND Invtmfhd.IS_DELETED =0   
             and NOT EXISTS (SELECT bomParent,UNIQ_KEY   
                 FROM ANTIAVL A   
                 where A.BOMPARENT =B2.bomParent   
                   and A.UNIQ_KEY = B2.CustUniqKey   
                   and A.PARTMFGR =MF.PARTMFGR   
                   and A.MFGR_PT_NO =MF.MFGR_PT_NO )  
      UNION ALL  
           --select B2.*,InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD,B2.MatlType as MfgrMatlType,INVTMFHD.MATLTYPEVALUE  
           ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
           select B2.*,MF.PARTMFGR ,MF.MFGR_PT_NO,MF.ORDERPREF ,MF.UNIQMFGRHD,B2.MatlType as MfgrMatlType,MF.MATLTYPEVALUE    
           FROM @tBom B2   
             --LEFT OUTER JOIN INVTMFHD ON B2.UNIQ_KEY=INVTMFHD.UNIQ_KEY   
             ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
             LEFT OUTER JOIN   
             (Select l.uniq_key, m.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MatlType ,M.MATLTYPEVALUE   
              FROM mfgrMaster M INNER JOIN Invtmpnlink L on m.mfgrmasterid=l.mfgrmasterid where m.is_deleted=0 and l.is_deleted=0) mf  
             ON B2.Uniq_Key=MF.UNIQ_KEY   
           WHERE B2.CustUniqKey=' '  
             --AND Invtmfhd.IS_DELETED =0   
             and NOT EXISTS (SELECT bomParent,UNIQ_KEY   
                 FROM ANTIAVL A   
                 where A.BOMPARENT =B2.bomParent   
                   and A.UNIQ_KEY = B2.UNIQ_KEY   
                   and A.PARTMFGR =mf.PARTMFGR   
                   and A.MFGR_PT_NO =mf.MFGR_PT_NO )  
           )  
  
     -- 12/07/12 VL changed the calculation of ReqDate  
     -- 10/31/13 VL added cUniq_key  
     -- 11/01/13 VL added w_key  
     -- 11/05/13 VL remove Invt_res, will update allocated qty later  
     insert into @results  
      select ISNULL(customer.custname,'') as CustName,woentry.DUE_DATE  
      --,woentry.ORDERDATE  
        ,dbo.fn_GetWorkDayWithOffset(Due_date,i4.Prod_ltime*(CASE WHEN i4.Prod_lunit = 'DY' THEN 1 ELSE  
           CASE WHEN i4.PROD_LUNIT = 'WK' THEN 7 ELSE  
           CASE WHEN i4.PROD_LUNIT = 'MO' THEN 30 ELSE 1 END END END) +   
           i4.KIT_LTIME*(CASE WHEN i4.KIT_LUNIT = 'DY' THEN 1 ELSE  
           CASE WHEN i4.KIT_LUNIT = 'WK' THEN 7 ELSE  
           CASE WHEN i4.KIT_LUNIT = 'MO' THEN 30 ELSE 1 END END END),'-') AS ReqDate   
        ,i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE  
        ,woentry.BLDQTY,I4.PERPANEL,case when I4.perpanel = 0 then woentry.BLDQTY else cast(woentry.bldqty/i4.perpanel as numeric (7,0))end as PnlBlank  
        ,b1.ITEM_NO,Used_inKit,b1.viewpartno as DispPart_no,b1.ViewRevision as DispRevision  
        ,CEILING(case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)   
         else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
          else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)  
           else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end) as Req_Qty  
 --01/17/2014 DRP:   ,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)   
 --        else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
 --         else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)  
 --          else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end as Req_Qty  
        ,CASE when woentry.UNIQ_KEY =  B1.BomParent THEN ' ' ELSE 'f' end as Phantom,b1.Part_class,b1.Part_type,CAST('' as char(10)) as kaseqnum  
        ,CAST(0 as bit) as kitclosed,CAST(0.00 as numeric(5,2)) as Act_qty,b1.UNIQ_KEY,b1.Dept_id,depts.DEPT_NAME,woentry.WONO,woentry.SONO,b1.scrap  
        ,b1.SetupScrap,b1.bomParent  
        ,CEILING(case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)   
         else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
          else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),2)  
           else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end) as ShortQty  
 --01/17/2014 DRP:   --,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap+ round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)   
        -- else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY)+b1.SetupScrap   
        --  else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*woentry.BLDQTY) + round((((B1.Qty * woentry.BldQty)*B1.Scrap)/100),0)  
        --   else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*woentry.BLDQTY) end end end end as ShortQty  
        ,CAST (0 as bit) as lineshort,b1.Part_sourc,b1.TopQty*b1.qty as Qty,b1.Descript,b1.U_of_meas,b1.PART_NO,b1.CustPartNo,CAST(0 as bit) as Ignorekit  
        ,CAST (0 as bit) as Phant_make,B1.SERIALYES,b1.Revision,b1.MatlType,b1.CustRev,invtmfgr.location,warehous.WAREHOUSE,invtmfgr.QTY_OH  
        ,Invtmfgr.qty_oh-Invtmfgr.reserved AS QtyNotReserved  
        -- 11/05/13 VL remove Invt_res field, need to use SUM() on invt_res table, will update this field later  
        --,case when (invt_res.QTYALLOC IS null) then 0000000000.00 else invt_res.QTYALLOC end as QtyAllocKit  
        , 0000000000.00 AS QtyAllocKit         
        ,case when (antiavl.PARTMFGR is null) then 'A' else '' end as antiAVL  
        ,b1.PARTMFGR,b1.MFGR_PT_NO,b1.MfgrMatlType,b1.ORDERPREF,b1.UNIQMFGRHD,isnull(invtlot.LOTCODE,''),invtlot.expdate,ISNULL(invtlot.REFERENCE,''),ISNULL(invtlot.ponum,'')  
        ,isnull(invtlot.LOTQTY,0.00),isnull(invtlot.LOTQTY-invtlot.LOTRESQTY,0.00),isnull(invtlot.UNIQ_LOT,''),case when woentry.uniq_key = B1.bomparent then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn  
        ,ISNULL(dp.dept_name,space(25)) as phparentwc --05/27/2015 DRP: Added  
        ,INSTORE, B1.CustUniqKey AS cUniq_key, Invtmfgr.W_key  
        -- 01/09/18 VL added KitStatus for update lKitIgnoreScrap later  
        ,KitStatus         
      from WOENTRY   
        inner join BomWithAvl as B1 on woentry.UNIQ_KEY =  right(Left(b1.path,11),10)  
        inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO  
        inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY  
        left outer join DEPTS on b1.Dept_id = depts.DEPT_ID  
        left outer join depts DP on b1.phantomwcid=dp.dept_id --05/27/2015 DRP:  Added  
        inner join INVTMFGR on b1.uniqmfgrhd = invtmfgr.uniqmfgrhd  
        inner join warehous on invtmfgr.uniqwh = warehous.uniqwh  
        --left outer join INVT_RES on woentry.Wono = invt_res.WONO and invtmfgr.W_KEY = invt_res.W_KEY   
        left outer join ANTIAVL on B1.Bomparent = ANTIAVL.BOMPARENT and b1.Uniq_key = ANTIAVL.UNIQ_KEY and b1.PARTMFGR = ANTIAVL.PARTMFGR and b1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO  
        left outer join INVENTOR as I3 on b1.BomParent = I3.UNIQ_KEY  
        left outer join INVTLOT on invtmfgr.W_KEY = invtlot.W_KEY  
      where @lcWono = woentry.WONO  
        AND B1.part_sourc <> 'PHANTOM'  
        AND B1.Phantom_make <> 1  
        and used_inkit = case when @SupUsedKit = 0 then Used_inKit else (select Used_inKit where Used_inKit <> 'N') end     
        and woentry.OPENCLOS not in ('ClOSED','CANCEL','ARCHIVED')   
        AND WAREHOUS.WAREHOUSE <> 'MRB'  
        -- 05/01/19 VL added warehouse filter  
        and (@lcUniqWH='All' OR EXISTS (SELECT 1 FROM @warehouse t inner join warehous w on t.uniqwh=w.uniqwh where w.uniqwh=Invtmfgr.uniqwh))  
        --and B1.Dept_id like case when @lcDeptId ='*' then '%' else @lcDeptId+'%' end --08/07/15 DRP:  replaced with the above and /*DEPARTMET LIST*/ --11/16/15 DRP:  replaced by the above   
        and (@lcDeptId='All' OR exists (select 1 from @Depts d inner join Depts d2 on d.dept_id=d2.DEPT_ID where d.dept_id=B1.dept_id))  
    --11/26/2012 DRP:  the results were pulling fwd locations that had been deleted.  Below was added to filter out the deleted items.   
        AND INVTMFGR.IS_DELETED <> 1  
        -- 10/31/13 VL added netable = 1  
        AND Invtmfgr.NETABLE = 1  
  
     -- 10/31/13 VL DED reported a problem that internal part number has more AVLs and customer has less AVLs, if the BOM is assigned to a customer, here show all AVLs from internal, will fix to only show AVL for the customer  
     -- changed to use LEFT OUTER JOIN and set criterial to have cUniq_key<>''  
     ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
     --select * from @results  
     UPDATE @results  
      SET AntiAvl = CASE WHEN (mf.UNIQ_KEY IS NULL) THEN ' ' ELSE 'A' END  
      FROM @results Zresults LEFT OUTER JOIN   
      ---- 03/12/15 YS replaced invtmfhd table with 2 new tables  
      (Select l.Uniq_key, M.PARTMFGR ,M.MFGR_PT_NO,L.ORDERPREF ,L.UNIQMFGRHD,M.MatlType ,M.MATLTYPEVALUE   
      FROM mfgrMaster M INNER JOIN Invtmpnlink L on m.mfgrmasterid=l.mfgrmasterid where m.is_deleted=0 and l.is_deleted=0) mf  
      ON Zresults.cUniq_key = MF.UNIQ_KEY  
      AND Zresults.Partmfgr = mf.PARTMFGR  
      AND Zresults.Mfgr_pt_no = mf.MFGR_PT_NO  
      --AND InvtMfhd.IS_DELETED = 0  
      WHERE cUniq_key<>''  
      -- 01/09/18 VL added to only update wono = @lcWono  
      AND ZResults.Wono = @lcWoNo  
  
     -- 10/31/13 VL added Antiavl = 'A' at end, found in previous SQL might already correctly set antiavl = '' for those don't have invtmfhd record, but this update SQL might set to 'A' again, need to filter out those records  
     UPDATE @results  
      SET AntiAvl = CASE WHEN (AntiAvl4BomParentView.UNIQ_KEY IS NULL) THEN 'A' ELSE ' ' END  
      FROM @results Zresults LEFT OUTER JOIN @AntiAvl4BomParentView AntiAvl4BomParentView  
      ON Zresults.cUniq_key = AntiAvl4BomParentView.UNIQ_KEY  
      AND Zresults.Partmfgr = AntiAvl4BomParentView.PARTMFGR  
      AND Zresults.Mfgr_pt_no = AntiAvl4BomParentView.MFGR_PT_NO  
      and zresults.bomparent = AntiAvl4BomParentView.bomparent --11/18/2014 DRP:  needed to add this in case the part is inactive on top level but then is included on sublevel (but with different avl approvals)  
      WHERE cUniq_key<>''  
      AND AntiAvl='A'  
      -- 01/09/18 VL added to only update wono = @lcWono  
      AND ZResults.Wono = @lcWoNo  
  
     DELETE FROM @results WHERE ANTIAVL<>'A'    
     -- 10/31/13 VL End}  
  
     -- 11/01/13 VL added code to update QtyNotReserved from WO/PJ allocation  
     -- 01/09/18 VL delete all old record because the table variable will be used multiple times  
     DELETE FROM @ZWoAlloc WHERE 1 = 1  
     INSERT @ZWoAlloc EXEC WoAllocatedView @lcWono  
       
     -- Update LotQtyAvail field  
     UPDATE @results SET LotQtyAvail = CASE WHEN ZWoAlloc.QtyAlloc IS NULL THEN LotQtyAvail ELSE LotQtyAvail+ZWoAlloc.Qtyalloc END  
      FROM @results Results LEFT OUTER JOIN @ZWoAlloc ZWoAlloc  
      ON Results.W_key = ZWoAlloc.W_key  
      AND Results.LotCode = ZWoAlloc.LotCode  
      AND ISNULL(Results.ExpDate,1) = ISNULL(ZWoAlloc.ExpDate,1)  
      AND Results.Reference = ZWoAlloc.REFERENCE  
      AND Results.PoNum = ZWoAlloc.PoNum  
      WHERE Results.LotCode<>''  
      -- 01/09/18 VL added to only update wono = @lcWono  
      AND Results.Wono = @lcWoNo  
     -- Update QtyNotReserved, need to group @ZWoAlloc by W_key  
     ;WITH ZWoAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZWoAlloc GROUP BY W_key)  
     UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZWoAllocSumW_key WHERE Results.W_key=ZWoAllocSumW_key.W_key  
       
     -- If this WO link to PJ  
     IF @lcPrjUnique<>''  
      BEGIN  
      -- 01/09/18 VL delete all old record because the table variable will be used multiple times  
      DELETE FROM @ZPJAlloc WHERE 1 = 1  
  
      INSERT @ZPJAlloc EXEC Invt_res4PJView @lcPrjUnique  
      UPDATE @results SET LotQtyAvail = CASE WHEN ZPjAlloc.QtyAlloc IS NULL THEN LotQtyAvail ELSE LotQtyAvail+ZPjAlloc.Qtyalloc END  
       FROM @results Results LEFT OUTER JOIN @ZPJAlloc ZPjAlloc  
       ON Results.W_key = ZPjAlloc.W_key  
       AND Results.LotCode = ZPjAlloc.LotCode  
       AND ISNULL(Results.ExpDate,1) = ISNULL(ZPjAlloc.ExpDate,1)  
       AND Results.Reference = ZPjAlloc.REFERENCE  
       AND Results.PoNum = ZPjAlloc.PoNum  
       WHERE Results.LotCode<>''  
       -- 01/09/18 VL added to only update wono = @lcWono  
       AND Results.Wono = @lcWoNo  
  
     -- Update QtyNotReserved, need to group @ZPJAlloc by W_key  
     ;WITH ZPJAllocSumW_key AS (SELECT W_key, SUM(QtyAlloc) AS QtyAlloc FROM @ZPJAlloc GROUP BY W_key)  
     UPDATE @results SET QtyNotReserved = QtyNotReserved+QtyAlloc, QtyAllocKit = QtyAllocKit+QtyAlloc FROM @results Results, ZPJAllocSumW_key WHERE Results.W_key=ZPJAllocSumW_key.W_key  
      -- 01/09/18 VL added to only update wono = @lcWono  
      AND Results.Wono = @lcWoNo  
        
     END  
     -- 11/01/13 VL End}  
      
     -- 01/09/18 VL comment out the code and use the final SQL select outside of the loop       
     --select R2.*,MICSSYS.LIC_NAME  
     --  ,invtsetup.lSuppressZeroInvt   
     --  , 0 as lKitIgnoreScrap --11/08/16 DRP:  Added  
     --from @results as R2   
     --  cross join MICSSYS  
     --  cross join invtsetup  
 --04/22/2013 DRP removed and added to the crystal report  
     --where Qty_Oh = case when @SupZero = 0 then Qty_Oh else (select Qty_Oh where Qty_Oh > 0.00) end  
        
  
     end  
  
     --END  
 ---------------- End of: if ( @lcKitStatus = '')  
 -- 01/09/18 VL added END  
  
  END --WHILE @lnWonoCount> @lnCnt  
  
 END -- IF @lnWonoCount <> 0    
   
    --ELSE -- ELSE of @@ROWCOUNT <> 0  
    -- SELECT R2.*,MICSSYS.LIC_NAME from @results as R2 cross join MICSSYS  
    --end  
-- 01/09/18 VL moved the final SQL select outside of the loop, also added woentry.ORDERDATE  
-- 12/30/20	VL Use 5 days(was 7) for WK and 20 days (was 30) for MO to calcualte leadtime/requied date, also added sublead time to work the same as QkViewKitRequiredView that YS changed in 2018, Zendesk #6812
select R1.*, isnull(customer.custname,'') as CustName,woentry.DUE_DATE,woentry.ORDERDATE, woentry.sono  
   ,dbo.fn_GetWorkDayWithOffset(woentry.Due_date,i4.Prod_ltime*(CASE WHEN i4.Prod_lunit = 'DY' THEN 1 ELSE  
     CASE WHEN i4.PROD_LUNIT = 'WK' THEN 5 ELSE  
     CASE WHEN i4.PROD_LUNIT = 'MO' THEN 20 ELSE 1 END END END) +   
      i4.KIT_LTIME*(CASE WHEN i4.KIT_LUNIT = 'DY' THEN 1 ELSE  
     CASE WHEN i4.KIT_LUNIT = 'WK' THEN 5 ELSE  
     --CASE WHEN i4.KIT_LUNIT = 'MO' THEN 20 ELSE 1 END END END),'-') AS KitReqDate  
	 CASE WHEN i4.KIT_LUNIT = 'MO' THEN 20 ELSE 1 END END END)+ISNULL(H.SubLeadTime,0),'-') AS KitReqDate
   ,i4.part_no as ParentBomPn,i4.REVISION as ParentBomRev,i4.DESCRIPT as ParentBomDesc,i4.MATLTYPE as ParentMatlType  
   ,woentry.BLDQTY,I4.PERPANEL,case when I4.perpanel = 0 then woentry.BLDQTY else cast(woentry.bldqty/i4.perpanel as numeric (7,0))end as PnlBlank  
   -- 05/01/19 changed to use @SupZero that from mnxsettingmanagement  
   --,invtsetup.lSuppressZeroInvt  
   ,@SupZero AS lSuppressZeroInvt  
   -- 01/09/18 VL changed if KitStatus is not empty, use @KitIgnoreScrap, if empty use 0 per Debbie's 11/08/16 changes  
   --,@KitIgnoreScrap as lKitIgnoreScrap --11/08/16 DRP:  Added  
   ,CASE WHEN R1.KitStatus <> '' THEN @KitIgnoreScrap ELSE 0 END AS lKitIgnoreScrap  
   ,MICSSYS.lic_name  
 from @results as R1   
   inner join woentry on R1.Wono = WOENTRY.wono   
   inner join customer on WOENTRY.CUSTNO = customer.CUSTNO  
   inner join INVENTOR as I4 on woentry.UNIQ_KEY = i4.UNIQ_KEY  
	-- 12/30/20 VL added to get subleadtime
	cross apply (select nItems,subleadtime from dbo.fnGetTotalLeadTimeAndCount(Woentry.Uniq_key,Woentry.due_date) ) H
   -- 05/01/19 VL comment out invtsetup  
   --cross join invtsetup  
   cross join MICSSYS  
 where woentry.OPENCLOS not in ('ClOSED','CANCEL','ARCHIVED')   
   AND ANTIAVL='A'    
END