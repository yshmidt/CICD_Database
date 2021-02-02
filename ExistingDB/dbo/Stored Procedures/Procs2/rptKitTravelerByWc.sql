  
-- =============================================  
-- Author:   Debbie / Vicky  
-- Create date:  12/22/2015  
-- Description:  Created for the Kit Material Availability w/AVL Detail report within Kitting  
-- Reports:   kitissu.rpt   
-- Modified: 02/08/16 remove invtmfhd table and replace with invtmpnlink and mfgrmaster  
--- 03/28/17 YS changed length of the part_no column from 25 to 35   
-- 11/29/17 VL added @lcWoNo as Wono at the last SQL statement to show Wono in the result  
-- 07/16/18 VL changed custname from char(35) to char(50)  
-- 03/13/2019 Mahesh B; Fixed the issues of "Column name or number of supplied values does not match table definition".
--- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50    
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
-- exec rptKitTravelerByWc '0000000198','49F80792-E15E-4B62-B720-21B360E3108A'   
-- =============================================  
CREATE PROCEDURE  [dbo].[rptKitTravelerByWc]  
  
--declare  
     @lcWoNo AS char(10) = '' -- Work order number  
    ,@userId uniqueidentifier = null  
  
      
  
as   
begin  
  
SET @lcWono=dbo.PADL(@lcWono,10,'0')  
--- 03/28/17 YS changed length of the part_no column from 25 to 35   
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
DECLARE @ZKitMainView TABLE (DispPart_no char(35),Req_Qty numeric(12,2),Phantom char(1),DispRevision char(8),Part_class char(8),Part_type char(8),Kaseqnum char(10)  
       ,Entrydate smalldatetime,Initials char(8),Kitclosed bit,Act_qty numeric(12,2)  
       --Rej_qty numeric(12,2),Rej_date smalldatetime,Rej_reson char(10), 03/13/2019 Mahesh B; Fixed the issues of "Column name or number of supplied values does not match table definition".    
       ,Uniq_key char(10),Dept_id char(4),Dept_name char(25),Wono char(10),Scrap numeric(6,2),Setupscrap numeric(4,0),Bomparent char(10)  
       ,Shortqty numeric(12,2),Lineshort bit,Part_sourc char(10),Qty numeric(12,2),Descript char(45),Inv_note text,U_of_meas char(4),Pur_uofm char(4)  
       ,Ref_des char(15),  
       --- 03/28/17 YS changed length of the part_no column from 25 to 35   
       Part_no char(35),Custpartno char(35),Ignorekit bit,Phant_make bit,Revision char(8),Serialyes bit,Matltype char(10),CustRev char(8)
		-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
		,allocatedQty numeric(12,2), userid uniqueidentifier)
  
-- Create another temp table, so I can add FillFrom field  
--- 03/28/17 YS changed length of the part_no column from 25 to 35   
-- 07/16/18 VL changed custname from char(35) to char(50) 
--- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50 
-- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
DECLARE @ZKMView TABLE (Custname char(50), ProdNo char(50), ProdRev char(8), ProdDesc char(45), orderdate smalldatetime, bldqty numeric(7,0), perpanel numeric(4,0)  
       ,PnlBlank numeric(7,0)  
       --- 03/28/17 YS changed length of the part_no column from 25 to 35   
       ,DispPart_no char(35),Req_Qty numeric(12,2),Phantom char(1),DispRevision char(8),Part_class char(8),Part_type char(8),Kaseqnum char(10)  
       ,Entrydate smalldatetime,Initials char(8),Kitclosed bit,Act_qty numeric(12,2)  
       --Rej_qty numeric(12,2),Rej_date smalldatetime,Rej_reson char(10), 03/13/2019 Mahesh B; Fixed the issues of "Column name or number of supplied values does not match table definition".    
       ,Uniq_key char(10),Dept_id char(4),Dept_name char(25),Wono char(10),Scrap numeric(6,2),Setupscrap numeric(4,0),Bomparent char(10)  
       ,Shortqty numeric(12,2),Lineshort bit,Part_sourc char(10),Qty numeric(12,2),Descript char(45),Inv_note text,U_of_meas char(4),Pur_uofm char(4)  
       ,Ref_des char(15),  
       --- 03/28/17 YS changed length of the part_no column from 25 to 35   
       Part_no char(35),Custpartno char(35),Ignorekit bit,Phant_make bit,Revision char(8),Serialyes bit,Matltype char(10),CustRev char(8)
	   -- 10/02/20 VL added allocatedQty, userid into @ZKitMainView because [KitMainView] are changed
	   ,allocatedQty numeric(12,2), userid uniqueidentifier
       ,FillFrom varchar(max), nrecno int,DeptOrder numeric(3))  
  
DECLARE @AVL_View TABLE (Uniq_key char(10), Partmfgr char(8), Mfgr_pt_no char(30), nrecno int)  
-- 12/22/15 VL found need to create another temp table to save the qty_oh and location for each AVL_view, it might have more than one record after grouping by location  
DECLARE @QtyOH4Location TABLE (Qty_oh numeric(12,2), Location char(17), nrecno int)  
  
DECLARE @lnTableVarCnt int , @lnTotalNo int, @lnCount int, @BomCustno char(10), @CustUniq_key char(10), @Req_qty numeric(12,2), @Act_qty numeric(12,2), @Uniq_key char(10),  
  @Part_Sourc char(10), @Partmfgr char(8), @Mfgr_pt_no char(30), @lnTotalNo2 int, @lnCount2 int, @lnQtyNeed numeric(12,2), @Qty_oh numeric(12,2), @Location char(17),  
  @FillFrom varchar(max), @lnTotalNo3 int, @lnCount3 int  
  
declare @lcKitStatus Char(10), @lcWoDuedate as smalldatetime, @lcPrjUnique char(10)  
select @lcKitStatus = woentry.KITSTATUS from WOENTRY where @lcWono = woentry.WONO   
  
-- Need to get BomCustno to get AVL_view, if bomcustno is not empty, get CONSG AVL, otherwise, just get AVL from internal part  
SELECt @BomCustno = BomCustno FROM Inventor WHERE Uniq_key = (SELECT Uniq_key FROM Woentry WHERE Wono = @lcWono)  
  
  
if ( @lcKitStatus <> '')  
  Begin  
  
   INSERT @ZKitMainView EXEC [KitMainView] @lcwono   
  
   INSERT @ZKMView  
      SELECT c.Custname,I.part_no as ProdNo,I.revision as ProdRev,I.descript as ProdDesc  
     ,W.ORDERDATE,W.BLDQTY,I.PERPANEL,case when I.perpanel = 0 then w.BLDQTY else cast(w.bldqty/i.perpanel as numeric (7,0))end as PnlBlank  
     ,KM.*, '' AS FillFrom, 0 AS nrecno,D.NUMBER as DeptNumber  
   FROM @ZKITMAINVIEW KM   
     inner join woentry w on KM.wono = w.wono   
     inner join INVENTOR I on w.uniq_key = I.uniq_key  
     inner join customer C on w.custno = c.custno   
     inner join depts D on km.Dept_id = D.DEPT_ID  
   where Shortqty > 0  
  
  
  
  
   -- start the code that will scan through @ZKMView to update FillFrom field  
   SET @lnTableVarCnt = 0  
   UPDATE @ZKMView SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1  
   SET @lnTotalNo = @lnTableVarCnt -- total records in @ZKMView  
   SET @lnCount=0;  
   WHILE @lnTotalNo>@lnCount  
   BEGIN   
    SET @lnCount=@lnCount+1;  
    SELECT @Uniq_key = Uniq_key, @Req_qty = Req_qty, @Act_qty = Act_qty, @Part_Sourc = Part_Sourc, @lnQtyNeed = Req_qty-Act_qty   
     FROM @ZKMView WHERE nrecno = @lnCount  
  
     -- Get internal uniq_key or CONSG uniq_key first to get AVL records  
     BEGIN  
     IF @BomCustno <> '' AND @BomCustno <> '000000000~' AND @Part_Sourc <> 'CONSG' -- BUY part with customer, will get CONSG AVL  
      BEGIN  
       SELECT @CustUniq_key = Uniq_key FROM Inventor WHERE Int_uniq = @Uniq_key AND Custno = @BomCustno AND Part_Sourc = 'CONSG'  
       IF @@ROWCOUNT = 0 -- didn't find record, will use @Uniq_key  
        BEGIN  
        SELECT @CustUniq_key = @Uniq_key  
       END  
      END  
     ELSE  
      BEGIN  
       SELECT @CustUniq_key = @Uniq_key  
      END  
     END  
  
  
     -- Now will go through AVL for this part to get WO-WIP location qty  
     DELETE FROM @AVL_View WHERE 1=1  
     SET @lnTableVarCnt = 0  
     SET @FillFrom = ''  
     --02/08/16 remove invtmfhd table and replace with invtmpnlink and mfgrmaster  
     INSERT INTO @AVL_View (Uniq_key, Partmfgr, Mfgr_pt_no)  
      SELECT L.Uniq_key, Partmfgr, Mfgr_pt_no  
       --FROM Invtmfhd  
       FROM Invtmpnlink L INNER JOIN MfgrMaster M ON l.MfgrMasterId = M.MfgrMasterId  
       WHERE L.Uniq_key = @CustUniq_key  
       AND l.Is_deleted = 0 and m.is_deleted=0  
       ORDER BY l.Orderpref, Partmfgr, Mfgr_pt_no  
     UPDATE @AVL_View SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1  
     SET @lnTotalNo2 = @lnTableVarCnt -- total records in @ZKMView  
     SET @lnCount2=0;  
     WHILE @lnTotalNo2>@lnCount2 AND @lnQtyNeed>0  
     BEGIN   
      -- SCAN through the AVL records  
      SET @lnCount2=@lnCount2+1;  
      SELECT @Partmfgr = Partmfgr, @Mfgr_pt_no = Mfgr_pt_no  
       FROM @AVL_View WHERE nrecno = @lnCount2  
  
      -- 12/22/15 VL found need to create another scan to get qty_oh and location for each AVL_view record  
      DELETE FROM @QtyOH4Location WHERE 1=1  
      SET @lnTableVarCnt = 0  
      --02/08/16 remove invtmfhd table and replace with invtmpnlink and mfgrmaster  
      INSERT INTO @QtyOH4Location (Qty_oh, Location)  
       SELECT ISNULL(SUM(Qty_oh),0), Location   
        FROM Invtmfgr  
        --WHERE Uniqmfgrhd IN   
        -- (SELECT UniqMfgrhd  
        --  FROM Invtmfhd   
        --  WHERE Uniq_key = @Uniq_key  
        --  AND Partmfgr = @Partmfgr  
        --  AND Mfgr_pt_no = @Mfgr_pt_no)  
        where exists (select 1 from Invtmpnlink L inner join mfgrMaster M on l.MfgrMasterId=m.MfgrMasterId  
        where l.uniq_key=@Uniq_key  
        AND m.Partmfgr = @Partmfgr  
        AND m.Mfgr_pt_no = @Mfgr_pt_no)  
 -- 12/22/15 Debbie found we need to added Qty_oh>0 criteria  
        AND Qty_oh > 0  
        AND UniqWh IN (SELECT UniqWh FROM Warehous WHERE Warehouse = 'WO-WIP')  
        AND IS_DELETED = 0  
        GROUP BY Location  
      UPDATE @QtyOH4Location SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1  
      SET @lnTotalNo3 = @lnTableVarCnt -- total records in @ZKMView  
      SET @lnCount3=0;  
      WHILE @lnTotalNo3>@lnCount3  
      BEGIN   
       SET @lnCount3=@lnCount3+1;  
       SELECT @Qty_oh = Qty_oh, @Location = Location  
        FROM @QtyOH4Location WHERE nrecno = @lnCount3  
  
       -- Get all the location and qty_oh from WO-WIP for FillFrom field  
       IF @@ROWCOUNT >0  
        BEGIN  
        SET @FillFrom = CASE WHEN @FillFrom = '' THEN @FillFrom ELSE @FillFrom+',' END +  
          CASE WHEN @Qty_oh > 0 THEN LTRIM(RTRIM(SUBSTRING(@Location,3,10)))+'('+LTRIM(RTRIM(STR(@Qty_oh,12,2)))+')' ELSE '' END  
        -- If lnQtyNeed =< 0 then no need to update @FillFrom and can exit the loop  
        SET @lnQtyNeed = CASE WHEN @Qty_oh<@lnQtyNeed THEN @lnQtyNeed-@Qty_oh ELSE 0 END  
       END  
      END  
     END   
  
     -- Now update @ZKMView.FillFrom WITH @FillFrom   
     UPDATE @ZKMView SET FillFrom = @FillFrom WHERE nrecno = @lnCount  
  
   END  
  
   -- 11/29/17 VL added @lcWoNo as Wono at the last SQL statement to show Wono in the result  
   SELECT Dept_name,CustName,ProdNo,ProdRev,ProdDesc,orderdate,bldqty,perpanel,PnlBlank,Part_sourc,DispPart_no,DispRevision,descript,Req_Qty,Phantom,Part_class,Part_type  
     ,req_qty,Act_Qty,Shortqty,Qty,FillFrom,DeptOrder, @lcWoNo AS Wono  
   FROM @ZKMView  
  
   order by deptorder,DispPart_no,DispRevision  
  END  
  
  
  
  
end