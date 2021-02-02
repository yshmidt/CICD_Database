-- =============================================    
-- Author:   Debbie     
-- Create date:  03/12/2013    
-- Description:  Created for the MRP PO Action Report ~ Detailed    
-- Reports:   mrppoact.rpt     
-- Modifications: 08/07-08/08/2013 YS adjusted for use with SS report     
--09/13/2013  DRP/YELEA:  REMOVED THE '*' FROM THE lcPartStart and lcPartEnd    
--10/01/2013 DRP:  Removed @lcWhere and modificed the MrpFullActionView call per Yelena changes.    
--12/03/13 YS use 'All' in place of ''    
--      get list of approved suppliers for this user    
--12/12/14 DS Added supplier status filter    
--03/02/15 DRP: changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key    
--06/24/2015 DRP:  Found that due to the fact that the MRPACT.DTTAKEACT would have a null value if there was no date to take action that the results would filter out those Null values.      
--     Removing the No Actions and Firm Planned records from the results.  Users reported that they need those records to display.     
--     Changed all locations from <<and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0>> to <<and (DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0 or MRPACT.DTTAKEACT is null)>>    
-- 06/15/17 DRP:  Per request added @lcAction.  This will allow the users to filter the results even further.  for example if they want to only see Release PO actions.     
-- 09/29/17 YS Contract structure is changed    
-- 07/16/18 VL changed supname from char(30) to char(50)    
-- 09/11/18 VL:   Added 'MRC' report parameter, request by Circuitronics, Zendesk#2465     
-- 09/27/18 VL added code to calculate qty_oh based on Mrpact.Mfgrs which has the partmfgr+mrgr_pt_no+`+next partmfgr....., Circuitronics requested, zendesk #2465    
-- 09/28/18 VL: Minor changes in the updating Qth_oh code to speed up    
-- 11/02/18 VL added @tMrpActDIST to only get uniq_key and qty_oh from the result of @tMrpActMPN, found if multiple MPN records for the same uniq_key, the result will returun duplicate record, Zendesk#2775    
-- 10/10/19 VL changed part_no from char(25) to char(35)    
-- 10/23/19 VL: Zendesk#5764, added last action date filter into the PO action criteria too, so the subquery of PO actions won't get the records outside of the date range  
-- 07/01/20 VL: Added EAU, ORD_POLICY, MINORD, ORDMULT, PUR_LTIME, PUR_LUNIT, REORDERQTY REORDPOINT, TARGETPRICE, zendesk#6396
-- 12/11/20 VL: now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer, CAPA 3284
-- =============================================    
CREATE PROCEDURE  [dbo].[rptMrpPoActionDetail]-- @lcContract='All'  
--10/01/2013 DRP: @lcWhere varchar(max)= '1=1' -- this will actually be populated from the MRP Filter screen, using Vicky's code    
  -- 08/08/13 YS remove bomparentrev parameter, changed @lcBomParentPart to @lcUniqBomParent    
  @lcUniqBomParent char(10)='' -- this is the Bom Parent Part.  This too will be populated by the MRP Filter Screen.    
  --  ,@lcBomPArentRev char(8)=''  -- this is the BOM Revision.  This too will be populated by the MRP Filter screen.    
  ,@lcUniq_keyStart char(10)=''    
  --,@lcPartStart as varchar(25)='' --This is the component start range that will be populated by the users within the report parameter selection screen --03/02/15 DRP:  replaced by @lcUniq_keyStart    
  --,@lcPartEnd as varchar(25)=''  --This is the component end range that will be populated by the users within the report parameter selection screen  --03/02/15 DRP:  replaced by @lcUniq_keyEnd    
  ,@lcUniq_keyEnd char(10)=''    
  ,@lcLastAction as smalldatetime = null --This is the Last Action Date filter which should defaulted from the MRP Find Filter screen.  Vicky will have to pass this to the procedure.    
  --08/08/13 YS allow CSV for the class, buyer code and supplier code    
  --12/03/13 YS use 'All' in place of ''    
  ,@lcClass as varchar (max) = 'All' --user would select to include all Classes or select from selection list.    
  ,@lcBuyer varchar(max) = 'All'   -- user would select to include ALL buyers or Select from Selection list.     
  ,@lcContract char(50) = 'All' -- All = All Parts Contract and Non-Contract    
         -- Parts with no Supplier Contract = results will only display parts with no Supplier Contract in the system.    
         -- Parts with Supplier Contract = results will only display parts with Supplier Contracts associated to it.     
  --12/03/13 YS use 'All' in place of ''    
  ,@lcUniqSupNo varchar(max) = 'All'     -- if user selects "Parts with Supplier Contracts" then this second parameter will be display to select from a Supplier Selection box.      
  , @userId uniqueidentifier=null      
  --,@supplierStatus varchar(20) = 'All' --03/02/2015 DRP:  Removed and just type 'All' in the section below.     
  ,@lcAction char(15) = 'All PO Actions' --  All PO Actions, Pull Ins,Push Outs, Release PO,Cancel PO  --06/15/17 DRP:  added    
  -- 09/11/18 VL added MRC    
  ,@lcMRC char(15) = 'All'    
    
aS    
BEGIN    
    
/*PART RANGE*/    
SET NOCOUNT ON;    
--03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key    
-- 10/10/19 VL changed part_no from char(25) to char(35)    
declare @lcPartStart char(35)='',@lcRevisionStart char(8)='',    
 @lcPartEnd char(35)='',@lcRevisionEnd char(8)=''    
      
  --03/02/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key     
  --09/13/2013 DRP: If null or '*' then pass ''    
  IF  @lcUniq_keyStart IS NULL or  @lcUniq_keyStart =''     
   SELECT @lcPartStart=' ', @lcRevisionStart=' '    
  ELSE    
  SELECT @lcPartStart = ISNULL(I.Part_no,' '),     
   @lcRevisionStart = ISNULL(I.Revision,' ')     
  FROM Inventor I where Uniq_key=@lcUniq_keyStart    
      
  -- find ending part number    
  IF  @lcUniq_keyEnd IS NULL or  @lcUniq_keyEnd =''     
   -- 10/10/19 VL changed part_no from char(25) to char(35)    
   SELECT @lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)    
  ELSE    
   SELECT @lcPartEnd =ISNULL(I.Part_no,' '),     
    @lcRevisionEnd = ISNULL(I.Revision,' ')     
   FROM Inventor I where Uniq_key=@lcUniq_keyEnd     
        
  -- 08/07/13 YS if no @lcLastAction provided use default     
   if @lcLastAction is null    
   SELECT @lcLastAction=DATEADD(Day,Mpssys.VIEWDAYS,getdate()) FROM MPSSYS     
        
  --declaring the table so that it can be populated using Yelena Stored Procedured called MrpFullActionView    
   -- 10/10/19 VL changed part_no from char(25) to char(35)    
   Declare @MrpActionView as table (Uniq_key char(10),Part_class char(8),Part_Type char(8),Part_no char(35),Revision char(8)    
           ,CustPartNo char(35),CustRev char(8),Descript char(45),  
            Part_sourc char(10),UniqMrpAct char(10))    
   --08/08/13 YS changed to receive @lcUniqBomParent for the parameters have to send part and revision    
   DECLARE @lcBomParentPart char(35)='',@lcBomPArentRev char(8) =''    
   if @lcUniqBomParent is null OR @lcUniqBomParent=''    
    SELECT @lcBomParentPart ='',@lcBomPArentRev =''    
   else    
    SELECT @lcBomParentPart = I.Part_no,@lcBomPArentRev =I.Revision FROM INVENTOR I where UNIQ_KEY=@lcUniqBomParent     
   --08/08/13 YS}    
--10/01/2013 DRP:  modified the call to the MrpFullActionView below               
   --Insert into @MrpActionView exec MrpFullActionView @lcWhere,@lcBomParentPart,@lcBomPArentRev    
   Insert into @MrpActionView exec MrpFullActionView @lcBomParentPart=@lcBomParentPart,@lcBomPArentRev=@lcBomPArentRev    
       
   -- 09/27/18 VL added code to calculate qty_oh based on Mrpact.Mfgrs which has the partmfgr+mrgr_pt_no+`+next partmfgr....., Circuitronics requested, zendesk #2465    
   DECLARE @tMrpAct TABLE (Uniq_key char(10), Mfgrs varchar(max), nId int identity(1,1))    
   DECLARE @tMrpActMPN TABLE (Uniq_key char(10), Partmfgr char(8), Mfgr_pt_no char(30), Uniqmfgrhd char(10), Mfgrs varchar(255), Qty_oh numeric (12,2))    
   -- 11/02/18 VL added @tMrpActDIST to only get uniq_key and qty_oh from the result of @tMrpActMPN, found if multiple MPN records for the same uniq_key, the result will returun duplicate record, Zendesk#2775    
   DECLARE @tMrpActDIST TABLE (Uniq_key char(10), Qty_oh numeric(12,2))    
   DECLARE @lnCnt int = 0, @lnTotalCnt int, @lcUniq_key char(10), @lcMfgrs varchar(max)    
    
   -- use this table to get Mfgrs field first    
   INSERT INTO @tMrpAct (Uniq_key) SELECT DISTINCT Uniq_key FROM @MrpActionView    
   UPDATE @tMrpAct SET Mfgrs = MrpAct.Mfgrs FROM MrpAct WHERE [@tMrpAct].Uniq_key = MrpAct.Uniq_key    
    
   SELECT @lnTotalCnt = @@ROWCOUNT    
   -- didn't find a way to insert multiple record using dbo.fn_simpleVarcharlistToTable(), so scan through all records    
   WHILE @lnCnt < @lnTotalCnt    
   BEGIN    
    SELECT @lnCnt = @lnCnt + 1    
    SELECT @lcUniq_key = Uniq_key, @lcMfgrs = Mfgrs FROM @tMrpAct WHERE nId = @lnCnt    
    INSERT INTO @tMrpActMPN (Mfgrs) SELECT Id FROM dbo.fn_simpleVarcharlistToTable(@lcMfgrs,'`')    
    UPDATE @tMrpActMPN SET Uniq_key = @lcUniq_key WHERE Uniq_key IS NULL    
   END    
   UPDATE @tMrpActMPN SET Partmfgr = LEFT(Mfgrs,8), Mfgr_pt_no = SUBSTRING(Mfgrs,10,30)    
   -- 10/10/19 VL use new two tables    
   --UPDATE @tMrpActMPN SET Uniqmfgrhd = Invtmfhd.UNIQMFGRHD FROM INVTMFHD WHERE [@tMrpActMPN].Uniq_key = Invtmfhd.Uniq_key and [@tMrpActMPN].Partmfgr = Invtmfhd.Partmfgr AND [@tMrpActMPN].Mfgr_pt_no = Invtmfhd.Mfgr_pt_no    
   UPDATE @tMrpActMPN SET Uniqmfgrhd = L.UNIQMFGRHD FROM InvtMPNLink L INNER JOIN MfgrMaster M     
    ON L.MfgrMasterID = M.MfgrMasterID    
    WHERE [@tMrpActMPN].Uniq_key = L.Uniq_key and [@tMrpActMPN].Partmfgr = M.Partmfgr AND [@tMrpActMPN].Mfgr_pt_no = M.Mfgr_pt_no    
    
   -- Now all fields are updated, will use to calcualte qty OH    
   -- 09/28/18 VL changed from CTE cursor to Table variable to speed up    
   DECLARE @tQtyOHUpd TABLE (Uniq_key char(10), Qty_oh numeric(12,2))    
   INSERT INTO @tQtyOHUpd (Uniq_key, Qty_oh)    
    SELECT Uniq_key, ISNULL(SUM(QTY_oh),0) AS Qty_oh FROM Invtmfgr     
     WHERE EXISTS(SELECT 1 FROM @tMrpActMPN WHERE Uniq_key = Invtmfgr.Uniq_key AND Uniqmfgrhd = INVTMFGR.Uniqmfgrhd)    
     AND NETABLE = 1    
     AND Uniqwh NOT IN (SELECT UniqWh FROM WAREHOUS WHERE WAREHOUSE = 'MRB')    
     GROUP BY Uniq_key    
    
   UPDATE @tMrpActMPN SET Qty_oh = [@tQtyOHUpd].Qty_oh FROM @tQtyOHUpd WHERE [@tMrpActMPN].Uniq_key = [@tQtyOHUpd].Uniq_key    
   -- 09/27/18 VL End}    
   -- 11/02/18 VL added @tMrpActDIST to only get uniq_key and qty_oh from the result of @tMrpActMPN, found if multiple MPN records for the same uniq_key, the result will returun duplicate record, Zendesk#2775    
   INSERT INTO @tMrpActDIST (Uniq_key, Qty_oh) SELECT DISTINCT Uniq_key, Qty_oh FROM @tMrpActMPN    
    
   --12/03/13 YS get list of approved suppliers for this user    
   DECLARE @tSupplier tSupplier    
   INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All' ;    
       
   -- 08/08/13 YS added code to handle suplier list    
   DECLARE @Supplier TABLE (Uniqsupno char(10))    
   SELECT @lcUniqSupno =  CASE WHEN @lcContract <>'Parts with Supplier Contract' THEN ''     
         ELSE @lcUniqSupno END    
   --12/03/13 YS use 'All' in place of ''    
   IF @lcUniqSupNo<>'All' and @lcUniqSupNo<>'' and @lcUniqSupNo is not null    
    insert into @Supplier  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')     
     WHERE cast(ID as char(10)) IN (SELECT UniqSupno from @tSupplier)    
   ELSE    
   BEGIN    
   IF @lcUniqSupNo='All'    
   BEGIN    
    -- select only one with access    
    insert into @Supplier select UniqSupno from @tSupplier    
   END    
   END       
        
   -- 08/08/13 YS added code to handle buyer list  
   -- 12/11/20 now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer
   --DECLARE @BuyerList TABLE (BUYER_TYPE char(3))    
   DECLARE @BuyerList TABLE (BuyerId uniqueidentifier)    
   --12/03/13 YS use 'All' in place of ''    
   IF @lcBuyer is not null and @lcBuyer <>'' and @lcBuyer <>'All'    
    INSERT INTO @BuyerList SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcBuyer,',')    
    
   -- 08/08/13 YS added code to handle class list    
   DECLARE @PartClass TABLE (part_class char(8))    
   --12/03/13 YS use 'All' in place of ''    
   IF @lcClass is not null and @lcClass <>'' and @lcClass <>'All'    
    INSERT INTO @PartClass SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcClass,',')    
    
  --Below will gather all of the MRP Action information that pertain to PO Actions    
    
  --&&& Begin "ALL":  This section will collect all PO Actions regardless if it has a Contract or not    
   --08/07/13 YS no need for the license information, SS report will have it    
   -- 12/03/13 @userid controls which supplier user can see    
   if (@lcContract = 'All')    
    Begin    
    -- 08/07/13 YS cif left outer join is in use in this case left outer join with CONTRACT table need to be carefull with any were for the contract table    
    -- and contract.PRIM_SUP = 1 will remove all the records that have no contract even though left outer join is used    
        
    select m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,I.STDCOST,i.buyer_type,MrpAct.*     
      ,isnull(h.UniqSupno,'')as UniqSupno,isnull(supinfo.SupName,'')as SupName,ISNULL(supinfo.phone,'') as Phone,ISNULL(supinfo.fax,'') as Fax    
      --09/29/17 YS added contractheader    
      ,H.STARTDATE as ContractStartDt,H.EXPIREDATE as ContractExpDt,    
      --,micssys.LIC_NAME    
      MPSSYS.MRPDATE    
      -- 09/11/18 VL added MRC    
      ,MRC    
      -- 09/27/18 VL Added Qty_oh    
      -- 11/02/18 VL changed to use tMrpActDIST    
      ,tMrpActDist.Qty_oh    
		-- 07/01/20 VL: Added EAU, ORD_POLICY, MINORD, ORDMULT, PUR_LTIME, PUR_LUNIT, REORDERQTY REORDPOINT, TARGETPRICE, zendesk#6396
		,EAU, ORD_POLICY, MINORD, ORDMULT, PUR_LTIME, PUR_LUNIT, REORDERQTY REORDPOINT, TARGETPRICE
    from @MrpActionView M     
      inner join INVENTOR I on m.Uniq_key = i.uniq_key     
      INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct    
      -- 09/27/18 VL added @tMrpActMPN to get Qty_oh    
      -- 11/02/18 VL changed to use tMrpActDIST    
      --INNER JOIN @tMrpActMPN tMrpActMPN ON m.Uniq_key = tMrpActMPN.Uniq_key    
      INNER JOIN @tMrpActDIST tMrpActDIST ON m.Uniq_key = tMrpActDIST.Uniq_key    
      left outer join CONTRACT on MRPACT.UNIQ_KEY = contract.UNIQ_KEY     
      --09/29/17 YS added contractheader    
      left outer join ContractHeader H on contract.contracth_unique=h.contracth_unique    
      and h.primSupplier  = 1    
      left outer join SUPINFO on H.UniqSupno = SUPINFO.UNIQSUPNO     
      --cross join MICSSYS     
      cross join MPSSYS    
    where CHARINDEX('PO',Action)<>0    
      -- 08/08/13 YS change default for part number from '*' to '', indicating all parts are to be selected    
      and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END    
      and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END    
      --08/08/13 YS change to be able to use multiple part clasees CSV    
      --12/03/13 YS use 'All' in place of ''    
      AND 1= CASE WHEN @lcClass ='All' THEN 1    -- any class    
      WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END    
      --08/08/13 YS change to be able to use multiple buyers CSV    
      --12/03/13 YS use 'All' in place of ''    
      AND 1= CASE WHEN @lcBuyer ='All' THEN 1    -- any class    
	  -- 12/11/20 now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer
      --WHEN I.BUYER_TYPE IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END    
	  WHEN I.AspnetBuyer IN (SELECT BuyerId FROM @BuyerList) THEN 1 ELSE 0  END    
      and (DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0 or MRPACT.DTTAKEACT is null)  --06/24/2015 DRP  Replaced:  and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0     
      --12/03/13 if contract is available show only contract for which the user has an acess, based on a supplier    
      -- use @tSupplier here, b/c @Supplier will be empty    
      and 1 = CASE WHEN H.UniqSupno  IS null then 1 --- no supplier/contract no restrictions    
         when H.UniqSupno IN (select UniqSupno from @tSupplier) THEN 1 ELSE 0 END     
      -- 08/07/13 YS move this code to the LEFT OUTER JOIN    
      --and contract.PRIM_SUP = 1    
      and M.Uniq_key in (select uniq_key from mrpact where     
       ((@lcAction = 'All PO Actions' and MRPACT.ACTION like '%PO%')    
       OR (@lcAction = 'Pull Ins' and (MRPACT.ACTION  like '%RESCH PO%' and DATEDIFF(day,REQDATE,DUE_DATE)>0))    
       OR (@lcAction = 'Push Outs' and (MRPACT.ACTION  like '%RESCH PO%' and DATEDIFF(day,REQDATE,DUE_DATE)<0))    
       or (@lcAction = 'Release PO' and MRPACT.ACTION = 'Release PO')    
       OR (@lcAction = 'Cancel PO' and MRPACT.ACTION = 'Cancel PO' ))    
       -- 10/23/19 VL: Zendesk#5764, added last action date filter into the PO action criteria too, so the subquery of PO actions won't get the records outside of the date range    
       AND (DATEDIFF(Day,DTTAKEACT,@lcLastAction)>=0 or DTTAKEACT is null)    
       ) --06/15/17 DRP  Added    
      -- 09/11/18 VL added filter for MRC    
      AND 1 = CASE WHEN (@lcMRC = 'All' OR @lcMRC IS NULL OR @lcMRC = '') THEN 1    
       WHEN MRC = @lcMRC THEN 1 ELSE 0 END    
    ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT    
   end    
  --&&& END "ALL"    
    
  --&&& Begin "No Supplier Contract":  This will list all PO Actions for parts that have no existing Supplier Contract.     
   else if (@lcContract = 'Parts with no Supplier Contract')     
    Begin    
    -- 07/16/18 VL changed supname from char(30) to char(50)    
    select m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,I.STDCOST,i.buyer_type,MrpAct.*     
      ,CAST('' as CHAR(10)) as UniqSupNo,CAST('' as char(50)) as SupName,CAST('' as CHAR(15)) as Phone,CAST('' as CHAR(15)) as Fax    
      ,cast(null as smalldatetime) as   ContractStartDt,cast(null as smalldatetime) as  ContractExpDt,    
      --,micssys.LIC_NAME,    
      MPSSYS.MRPDATE    
      -- 09/11/18 VL added MRC    
      ,MRC    
      -- 09/27/18 VL Added Qty_oh    
      -- 11/02/18 VL changed to use tMrpActDIST    
      ,tMrpActDist.Qty_oh    
		-- 07/01/20 VL: Added EAU, ORD_POLICY, MINORD, ORDMULT, PUR_LTIME, PUR_LUNIT, REORDERQTY REORDPOINT, TARGETPRICE, zendesk#6396
		,EAU, ORD_POLICY, MINORD, ORDMULT, PUR_LTIME, PUR_LUNIT, REORDERQTY REORDPOINT, TARGETPRICE
    from @MrpActionView M     
      inner join INVENTOR I on m.Uniq_key = i.uniq_key     
      INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct    
      -- 09/27/18 VL added @tMrpActMPN to get Qty_oh    
      -- 11/02/18 VL changed to use tMrpActDIST    
      --INNER JOIN @tMrpActMPN tMrpActMPN ON m.Uniq_key = tMrpActMPN.Uniq_key    
      INNER JOIN @tMrpActDIST tMrpActDIST ON m.Uniq_key = tMrpActDIST.Uniq_key    
      --cross join MICSSYS     
      cross join MPSSYS    
    where CHARINDEX('PO',Action)<>0    
      -- 08/08/13 YS change default for part number from '*' to '', indicating all parts are to be selected    
      and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END    
      and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END    
      --08/08/13 YS change to be able to use multiple part clasees CSV    
      --12/03/13 YS use 'All' in place of ''    
      AND 1= CASE WHEN @lcClass ='All' THEN 1    -- any class    
      WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END    
      --08/08/13 YS change to be able to use multiple buyers CSV    
      AND 1= CASE WHEN @lcBuyer ='All' THEN 1    -- any class    
	  -- 12/11/20 now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer
      --WHEN I.BUYER_TYPE IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END    
	  WHEN I.AspnetBuyer IN (SELECT BuyerId FROM @BuyerList) THEN 1 ELSE 0  END    
      and (DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0 or MRPACT.DTTAKEACT is null)  --06/24/2015 DRP  Replaced:  and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0     
      and i.UNIQ_KEY not in (select UNIQ_KEY from CONTRACT)    
      and M.Uniq_key in (select uniq_key from mrpact where     
       ((@lcAction = 'All PO Actions' and MRPACT.ACTION like '%PO%')    
       OR (@lcAction = 'Pull Ins' and (MRPACT.ACTION  like '%RESCH PO%' and DATEDIFF(day,REQDATE,DUE_DATE)>0))    
       OR (@lcAction = 'Push Outs' and (MRPACT.ACTION  like '%RESCH PO%' and DATEDIFF(day,REQDATE,DUE_DATE)<0))    
       or (@lcAction = 'Release PO' and MRPACT.ACTION = 'Release PO')    
       OR (@lcAction = 'Cancel PO' and MRPACT.ACTION = 'Cancel PO' ))    
       -- 10/23/19 VL: Zendesk#5764, added last action date filter into the PO action criteria too, so the subquery of PO actions won't get the records outside of the date range    
       AND (DATEDIFF(Day,DTTAKEACT,@lcLastAction)>=0 or DTTAKEACT is null)    
       ) --06/15/17 DRP  Added    
      -- 09/11/18 VL added filter for MRC    
      AND 1 = CASE WHEN (@lcMRC = 'All' OR @lcMRC IS NULL OR @lcMRC = '') THEN 1    
       WHEN MRC = @lcMRC THEN 1 ELSE 0 END    
    ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT    
   end    
  --&&& END "No Supplier Contract"    
    
  --&&& Begin "With Supplier Contract":  This will list all PO Actions for parts that have existing Supplier Contract.     
   else if (@lcContract = 'Parts with Supplier Contract')     
    Begin    
    select m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,I.STDCOST,i.buyer_type,MrpAct.*     
    --09/29/17 YS added contractheader    
      ,supinfo.UniqSupNo,supinfo.SupName,supinfo.phone,supinfo.fax,H.STARTDATE as ContractStartDt,H.EXPIREDATE as ContractExpDt,    
      --,micssys.LIC_NAME,    
      MPSSYS.MRPDATE    
      -- 09/11/18 VL added MRC    
      ,MRC    
      -- 09/27/18 VL Added Qty_oh    
      -- 11/02/18 VL changed to use tMrpActDIST    
      ,tMrpActDist.Qty_oh    
		-- 07/01/20 VL: Added EAU, ORD_POLICY, MINORD, ORDMULT, PUR_LTIME, PUR_LUNIT, REORDERQTY REORDPOINT, TARGETPRICE, zendesk#6396
		,EAU, ORD_POLICY, MINORD, ORDMULT, PUR_LTIME, PUR_LUNIT, REORDERQTY REORDPOINT, TARGETPRICE
    from @MrpActionView M     
      inner join INVENTOR I on m.Uniq_key = i.uniq_key     
      INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct    
      -- 09/27/18 VL added @tMrpActMPN to get Qty_oh    
      -- 11/02/18 VL changed to use tMrpActDIST    
      --INNER JOIN @tMrpActMPN tMrpActMPN ON m.Uniq_key = tMrpActMPN.Uniq_key    
      INNER JOIN @tMrpActDIST tMrpActDIST ON m.Uniq_key = tMrpActDIST.Uniq_key    
      inner join CONTRACT on i.UNIQ_KEY = contract.UNIQ_KEY    
      inner join contractHeader H on h.ContractH_unique=contract.contractH_unique    
      inner join SUPINFO on H.UniqSupno = SUPINFO.UNIQSUPNO    
      --cross join MICSSYS     
      cross join MPSSYS    
    where CHARINDEX('PO',Action)<>0    
      -- 08/08/13 YS change default for part number from '*' to '', indicating all parts are to be selected    
      and m.Part_no>= case when @lcPartStart='' then m.Part_no else @lcPartStart END    
      and m.PART_NO<= CASE WHEN @lcPartEnd='' THEN m.PART_NO ELSE @lcPartEnd END    
      --08/08/13 YS change to be able to use multiple part clasees CSV    
      --12/03/13 YS use 'All' in place of ''    
      AND 1= CASE WHEN @lcClass ='All' THEN 1    -- any class    
      WHEN m.Part_class IN (SELECT Part_class FROM @PartClass) THEN 1 ELSE 0  END    
      --08/08/13 YS change to be able to use multiple buyers CSV    
      --12/03/13 YS use 'All' in place of ''    
      AND 1= CASE WHEN @lcBuyer ='All' THEN 1    -- any class    
	  -- 12/11/20 now the buyer is not saved in Buyer_type, it's saved in AspnetBuyer
      --WHEN I.BUYER_TYPE IN (SELECT BUYER_TYPE FROM @BuyerList) THEN 1 ELSE 0  END    
      WHEN I.AspnetBuyer IN (SELECT BuyerId FROM @BuyerList) THEN 1 ELSE 0  END    
      and (DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0 or MRPACT.DTTAKEACT is null)  --06/24/2015 DRP  Replaced:  and DATEDIFF(Day,MRPACT.DTTAKEACT,@lcLastAction)>=0     
      and H.primSupplier = 1    
      -- 08/08/13 YS added ability to have CSV for the supplier    
      --12/03/13 YS use 'All' in place of ''    
      AND 1= CASE WHEN @lcUniqSupno ='All' THEN 1    -- any supplier    
      WHEN SUPINFO.UNIQSUPNO IN (SELECT UniqSupno FROM @Supplier) THEN 1 ELSE 0  END    
      and M.Uniq_key in (select uniq_key from mrpact where     
       ((@lcAction = 'All PO Actions' and MRPACT.ACTION like '%PO%')    
       OR (@lcAction = 'Pull Ins' and (MRPACT.ACTION  like '%RESCH PO%' and DATEDIFF(day,REQDATE,DUE_DATE)>0))    
       OR (@lcAction = 'Push Outs' and (MRPACT.ACTION  like '%RESCH PO%' and DATEDIFF(day,REQDATE,DUE_DATE)<0))    
       or (@lcAction = 'Release PO' and MRPACT.ACTION = 'Release PO')    
       OR (@lcAction = 'Cancel PO' and MRPACT.ACTION = 'Cancel PO' ))    
       -- 10/23/19 VL: Zendesk#5764, added last action date filter into the PO action criteria too, so the subquery of PO actions won't get the records outside of the date range    
       AND (DATEDIFF(Day,DTTAKEACT,@lcLastAction)>=0 or DTTAKEACT is null)    
       ) --06/15/17 DRP  Added    
      -- 09/11/18 VL added filter for MRC    
      AND 1 = CASE WHEN (@lcMRC = 'All' OR @lcMRC IS NULL OR @lcMRC = '') THEN 1    
       WHEN MRC = @lcMRC THEN 1 ELSE 0 END    
    ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT    
   end    
  --&&& END "With Supplier Contract"    
    
    
 END