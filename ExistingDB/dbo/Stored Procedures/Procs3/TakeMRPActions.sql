-- =============================================      
-- Author:  Shivshankar P      
-- Create date: 08/03/17      
-- Description: Take MRP Action      
 --declare @p1 dbo.tMrpAct      
 --02/04/2020 Shivshankar P : Added the #tempWoEntry table and generate the error if the Wo is kitted and user want to cancel it      
 --02/05/2020 Shivshankar P : When change PO qty action is taken the stock UOM (S_ORD_QTY) quantities need to update      
 --02/05/2020 Shivshankar P : Changed the Curr_Qty selection and removed the condition in outer apply and where clause       
 --02/06/2020 Shivshankar P : change the condition generate the error if the Wo is kitted and user want to cancel it      
 --02/06/2020 Shivshankar P : Changed the block of code auto approval not working      
 --02/11/2020 Shivshankar P : Get customer name for only 'WO' and 'Dem WO'      
 --02/17/2020 Vijay G: Change the block of code where code is not working if autonumbering is on    
 --02/17/2020 Vijay G: Condition replaced t1.IsCancel with LCancel    
 --06/01/2020 Shivshankar P : Updating While loop @count in Else block also     
 --06/02/2020 Shivshankar P : Added OUTER APPLY to check if any receiving receipt is available for PO and Add case for 'CANCEL PO' Action to change the order and schedule quantities to match the receipt    
 --06/03/2020 Shivshankar P : Added the block of code to Insert/Update the purchase order history Notes for PO     
 --06/09/2020 Shivshankar P : Update ORD_QTY and S_ORD_QTY in POITEMS Table based on PO Item Schedules    
 --06/09/2020 Shivshnakar P : Added the detail information purchase order history Notes for PO for different MRP action     
 --06/10/2020 Shivshankar P : Added ActDate as current date when we take WO MRP Actions by using GETDATE()    
 --06/10/2020 Shivshankar P : Remove Top 1 selection because when we take multiple WO MRP Action need to update CURR_QTY in DEPT_QTY table    
 --06/11/2020 Shivshankar P : Added the condition and generate the error if the MRP Balance and WO Balance does not match     
 --06/12/2020 Shivshankar P : Added the OUTER APPLY and condition and generate the error if the Customer is not available in system      
 --06/12/2020 Shivshankar P : Changed @CompleteDT= COMPLETEDT to @CompleteDT= REQDATE for WO MRP Take action and if REQDATE is NULL then Todays date    
 --06/11/2020 Sachin B Update START_DATE,ORDERDATE,COMPLETEDT   
 --06/19/2020 Sachin B Fix the Issue Wrong Qty is Updaed in the WC  
 --06/26/2020 Shivshankar P : Get POITSCHD.RECDQTY for cancel PO and added POITEMS.UNIQLNNO=qt.UNIQLNNO when we update poitem  
 --07/15/2020 Shivshnakar P : Added the More detail information in purchase order history Notes for PO for different MRP action     
 --07/22/2020 Shivshankar P Update Work Order Date (Woentry.OrderDate).can not be changed by any actions accept new actions And Work Order Complete Date (Woentry.CompleteDt) is updated only when balance becomes zero   
 --07/24/2020 Shivshankar P Modify and Move the SP NewSchPlanningAdjustWOStart Call after updating DEPT_QTY table  
 --09/04/2020 Shivshankar P : Added CASE and Outer Apply to update POSTATUS = 'CLOSED' if poitem balance becomes zero  
 --09/09/2020 Shivshnakar P : Change PODATE to GETDATE() and Added the More detail information in purchase order history Notes for PO for Cancel MRP action  
 --09/16/2020 Shivshankar P : Changed @CompleteDT NUMERIC to @CompleteDT SMALLDATETIME becouse SP NewSchPlanningAdjustWOStart parameter having SMALLDATETIME type  
 --- 10/29/20 YS added code to find a parent if the Action is to release a new work order and the reference is PWO (purposed work order). We will need to find a customer number    
 --- 11/02/20 YS all outer apply have to have MRPACT removed from internal SQL and linked to the main MRPACT    
 --12/15/2020 Shivshankar P : Added condition for the Ready for Approval checkbox is not working properly on Auto Approval  
 --12/15/2020 Shivshankar P : Remove the $ sign from po quantity  
 --12/16/2020 Shivshankar P : Added separate purchase order history Notes for every action  
 --- 01/15/2021 Rajendra K : Removed time from oldsch_date and newsch_ date while putting into note
 --- 01/18/2021 Rajendra K : Changed condition for cancel po item
 --INSERT INTO @p1 values(N'_4DS0MHJN4',N'PO 000000000001517',NULL,N'9/20/2005 12:00:00 AM',NULL,N'5',N'0',N'Cancel PO',N'6/23/2015 6:30:00 PM',NULL,N'0',N'Success',NULL,N'9/22/2017 3:41:43 PM',N'49f80792-e15e-4b62-b720-21b360e3108a')      
 --INSERT INTO @p1 values(N'_4DS0MHJN5',N'PO 000000000001506',NULL,N'8/25/2008 12:00:00 AM',NULL,N'15',N'0',N'Cancel PO',N'6/23/2015 6:30:00 PM',NULL,N'0',N'Success',NULL,N'9/22/2017 3:41:43 PM',N'49f80792-e15e-4b62-b720-21b360e3108a')      
 --EXEC TakeMRpActions @tMrpAct=@p1        
-- ================================================      
CREATE PROCEDURE  [dbo].[TakeMRPActions]      
(      
 @tMrpAct tMrpAct READONLY,      
 --@isTakeAll bit=0,      
 @tInvtser tInvtser READONLY,      
 @tDeptQty tDeptQty READONLY      
)      
AS      
BEGIN      
 SET NOCOUNT ON;      
  DECLARE @ErrorMessage NVARCHAR(4000);      
  DECLARE @ErrorSeverity INT;      
  DECLARE @ErrorState INT;      
  DECLARE @isAutoApprove BIT,@userId UNIQUEIDENTIFIER,@lastWONO CHAR(10),@autoWO BIT,@isAutRelease BIT;      
  DECLARE @tempDeptQty DBO.tDeptQty      
      
  BEGIN TRANSACTION      
  BEGIN TRY      
               
     SELECT TOP 1 @UserID = ACTUSERID FROM @tMrpAct      
      
  IF EXISTS(SELECt 1 FROM @tMrpAct WHERE (ACTION = '- Qty RESCH PO ' OR ACTION = '+ Qty RESCH PO ' OR ACTION = '- PO Qty' OR ACTION = '+ PO Qty'      
               OR ACTION LIKE  'RESCH PO%'  OR ACTION LIKE '%CANCEL PO%'))      
        BEGIN      
   --02/06/2020 Shivshankar P : Added OUTER APPLY to check if any receiving receipt is available for PO and Add case for 'CANCEL PO' Action to change the order and schedule quantities to match the receipt    
   SELECT @isAutoApprove = ISNULL(ws.settingValue ,s.settingValue) from MnxSettingsManagement s      
      left join wmSettingsManagement ws on ws.settingId =s.settingId      
                           WHERE settingName ='ApprovePOWhenImporting'            
   --06/03/2020 Shivshankar P : Changed the block of code auto approval not working    
   --06/26/2020 Shivshankar P : Get POITSCHD.RECDQTY for cancel PO and added POITEMS.UNIQLNNO=qt.UNIQLNNO when we update poitem  
   SELECT ORD_QTY = CASE  WHEN t1.ACTION ='+ Qty RESCH PO ' OR  t1.ACTION ='+ PO Qty'  OR t1.ACTION ='- Qty RESCH PO ' OR  t1.ACTION ='- PO Qty'      
                           THEN  (t1.REQQTY + RECV_QTY) ELSE CASE WHEN (t1.ACTION ='CANCEL PO' AND RecReceipt.Receipt = 1) THEN POITSCHD.RECDQTY ELSE 0 END END ,     
                          -- WHEN  t1.ACTION ='- Qty RESCH PO ' OR  t1.ACTION ='- PO Qty' THEN (PoItem.ORD_QTY - t1.REQQTY)       
          SCHD_QTY = CASE WHEN t1.ACTION ='+ Qty RESCH PO '  OR  t1.ACTION ='+ PO Qty'  OR t1.ACTION ='- Qty RESCH PO ' OR  t1.ACTION ='- PO Qty'       
                           THEN (t1.REQQTY + POITSCHD.RECDQTY) ELSE CASE WHEN (t1.ACTION ='CANCEL PO' AND RecReceipt.Receipt = 1) THEN POITSCHD.RECDQTY ELSE 0 END END ,     
                          -- WHEN t1.ACTION ='- Qty RESCH PO ' OR  t1.ACTION ='- PO Qty' THEN (t1.REQQTY + POITSCHD.RECDQTY)      
     BALANCE = SCHD_QTY-RECDQTY, PoItem.UNIQLNNO, POITSCHD.UNIQDETNO, t1.ActionFailureMsg,      
     t1.ActUserId,t1.ActionStatus,t1.UniqMRPAct,t1.REQQTY,PoItem.PONUM,      
     IsQtyResc = CASE WHEN  t1.ACTION ='+ Qty RESCH PO ' OR  t1.ACTION ='- Qty RESCH PO ' OR (t1.ACTION ='CANCEL PO' AND RecReceipt.Receipt = 1) THEN 1 ELSE 0 END ,      
     IsQty = CASE WHEN  t1.ACTION ='+ PO Qty' OR  t1.ACTION ='- PO Qty' THEN 1 ELSE 0 END ,      
     IsResc = CASE WHEN  t1.ACTION ='RESCH PO' OR t1.ACTION ='+ Qty RESCH PO ' OR  t1.ACTION ='- Qty RESCH PO ' THEN 1 ELSE 0 END,    
     MRPACT.REQDATE,      
     IsCancel = CASE WHEN (t1.ACTION ='CANCEL PO' AND RecReceipt.Receipt = 1) THEN 0 ELSE CASE WHEN t1.ACTION ='CANCEL PO' THEN 1 ELSE 0 END END,      
     '0' AS IsUpdate,      
     PoItem.PONUM AS tPoNum, PoItem.U_OF_MEAS, PoItem.PUR_UOFM,      
     '0' AS IsApprove,    
     '0' AS IsNoteUpdate,     
     t1.ACTION AS ActionTaken,   
  PoItem.ORD_QTY AS oldORDQTY,  
  POITSCHD.SCHD_DATE AS oldSCHD_DATE  
     INTO #qtyReschPOTemp      
     FROM  @tMrpAct t1     
     JOIN MRPACT on t1.UniqMRPAct=MRPACT.UNIQMRPACT      
     JOIN POITEMS PoItem on PoItem.PONUM =  RTRIM(LTRIM(REPLACE(t1.REF,'PO','')))       
     JOIN POITSCHD on POITSCHD.UNIQLNNO = PoItem.UNIQLNNO and MRPACT.DUE_DATE=POITSCHD.SCHD_DATE AND PoItem.UNIQ_KEY =  t1.UniqKey      
     OUTER APPLY (SELECT 1 AS Receipt FROM receiverHeader rh    
                           JOIN receiverDetail rd on rh.receiverHdrId = rd.receiverHdrId and rd.uniqlnno = PoItem.UNIQLNNO     
                           where ponum = PoItem.PONUM) RecReceipt     
     WHERE (t1.action = '- Qty RESCH PO' OR t1.ACTION = '+ Qty RESCH PO' OR t1.ACTION = '- PO Qty'      
            OR t1.ACTION = '+ PO Qty' OR t1.ACTION LIKE 'RESCH PO%' OR t1.ACTION ='CANCEL PO')      
      
   DECLARE @tpoNum VARCHAR(15), @noSetup BIT, @cpoNum VARCHAR(15), @isApproveReq INT      
   --02/06/2020 Shivshankar P : Changed the block of code auto approval not working      
   DECLARE @count int      
   SELECT @count = count(DISTINCT tPoNum) from #qtyReschPOTemp      
   while(@count > 0)      
   BEGIN      
    --02/17/2020 Vijay G: Change the block of code where code is not working if autonumbering is on      
    --06/01/2020 Shivshankar P : Updating While loop @count in Else block also         
    IF(@isAutoApprove =0)            
    BEGIN             
    SELECT TOP 1 @tpoNum = tPoNum from #qtyReschPOTemp where IsUpdate = 0      
    SET @count= @count - 1;      
    SET @cpoNum = @tpoNum      
    SET @isApproveReq = 0      
    EXEC ProcessApprovePO @tpoNum, @userId, @noSetup OUT      
    IF (@noSetup = 1)      
    BEGIN      
     SET @cpoNum = LTRIM(REPLACE(@tpoNum,'T','0'))      
     SET @isApproveReq =1      
    END      
       UPDATE #qtyReschPOTemp  SET IsUpdate = 1 ,PONUM= @CPONUM , IsApprove=@isApproveReq WHERE  PONUM = @tpoNum      
    END      
    ELSE          
    BEGIN     
     SELECT TOP 1 @tpoNum = tPoNum from #qtyReschPOTemp where IsUpdate = 0            
     SET @count= @count - 1;           
     UPDATE #qtyReschPOTemp  SET IsUpdate = 1 ,PONUM= LTRIM(REPLACE(@tpoNum,'T','0')) , IsApprove=1 WHERE  PONUM = @tpoNum            
    END      
   END        
  
   --02/05/2020 Shivshankar P : When change PO qty action is taken the stock UOM (S_ORD_QTY) quantities need to update      
   --06/09/2020 Shivshankar P : Update ORD_QTY and S_ORD_QTY in POITEMS Table based on PO Item Schedules    
   UPDATE POITEMS SET LCANCEL =  IsCancel, PONUM = #qtyReschPOTemp.PONUM     
   FROM #qtyReschPOTemp where POITEMS.UNIQLNNO=#qtyReschPOTemp.UNIQLNNO      
      
   UPDATE POITSCHD SET SCHD_QTY = CASE WHEN IsQtyResc = 1 OR IsQty=1  THEN temp.SCHD_QTY ELSE POITSCHD.SCHD_QTY END,       
                       BALANCE = CASE WHEN IsQtyResc = 1 OR IsQty=1  THEN temp.SCHD_QTY - RECDQTY  ELSE POITSCHD.BALANCE END,      
                       SCHD_DATE = CASE WHEN IsResc =1 THEN  temp.REQDATE ELSE  POITSCHD.SCHD_DATE END,      
                       PONUM = temp.PONUM      
          FROM #qtyReschPOTemp temp where POITSCHD.UNIQDETNO=temp.UNIQDETNO      
       
   --06/09/2020 Shivshankar P : Update ORD_QTY and S_ORD_QTY in POITEMS Table based on PO Item Schedules   
   --06/26/2020 Shivshankar P : Get POITSCHD.RECDQTY for cancel PO and added POITEMS.UNIQLNNO=qt.UNIQLNNO when we update poitem  
      UPDATE POITEMS SET ORD_QTY = CASE WHEN IsQtyResc = 1 OR IsQty = 1 THEN     
         (SELECT SUM(ps.SCHD_QTY) FROM POITSCHD ps WHERE ps.PONUM = qt.PONUM AND ps.UNIQLNNO = qt.UNIQLNNO)    
         ELSE POITEMS.ORD_QTY END,    
  S_ORD_QTY = CASE WHEN IsQtyResc = 1 OR IsQty=1 THEN                   
        CASE WHEN qt.U_OF_MEAS = qt.PUR_UOFM THEN (SELECT SUM(ps.SCHD_QTY) FROM POITSCHD ps WHERE ps.PONUM = qt.PONUM AND ps.UNIQLNNO = qt.UNIQLNNO)                  
        ELSE       
        CASE WHEN EXISTS(SELECT 1 FROM UNIT WHERE ([FROM]= qt.PUR_UOFM AND [TO]= qt.U_OF_MEAS))      
        THEN     
  ((SELECT SUM(ps.SCHD_QTY) FROM POITSCHD ps WHERE ps.PONUM = qt.PONUM AND ps.UNIQLNNO = qt.UNIQLNNO) * (SELECT FORMULA FROM UNIT WHERE ([FROM] = qt.PUR_UOFM AND [TO] = qt.U_OF_MEAS)))      
        ELSE      
  ((SELECT SUM(ps.SCHD_QTY) FROM POITSCHD ps WHERE ps.PONUM = qt.PONUM AND ps.UNIQLNNO = qt.UNIQLNNO) / (SELECT FORMULA FROM UNIT WHERE ([TO] = qt.PUR_UOFM AND [FROM] = qt.U_OF_MEAS)))      
        END         
        END                                                      
        ELSE POITEMS.S_ORD_QTY END     
   FROM #qtyReschPOTemp qt    
   WHERE POITEMS.PONUM = qt.PONUM AND POITEMS.UNIQLNNO=qt.UNIQLNNO    
    
   --09/04/2020 Shivshankar P : Added CASE and Outer Apply to update POSTATUS = 'CLOSED' if poitem balance becomes zero  
   UPDATE POMAIN SET PONUM = t1.PONUM,--CASE WHEN @isAutoApprove = 1 THEN LTRIM(REPLACE(PM.PONUM,'T','0')) ELSE PM.PONUM END,      
                     POTOTAL = (SELECT SUM(POITEMS.ORD_QTY * POITEMS.COSTEACH) FROM POITEMS WHERE PONUM = t1.PONUM),    
                     -- 02/17/2020 Vijay G: Condition replaced t1.IsCancel with LCancel       
                     POSTATUS = CASE WHEN t1.IsApprove = 1 THEN CASE WHEN NOT EXISTS (SELECT 1 FROM POITEMS WHERE PONUM = t1.PONUM AND LCANCEL=0)        
                     THEN 'CANCEL' ELSE CASE WHEN ItemBal.Bal = 0 THEN 'CLOSED' ELSE 'OPEN' END END ELSE 'EDITING' END,  --02/06/2020 Shivshankar P : Changed the block of code auto approval not working          
                     --12/15/2020 Shivshankar P : Added condition for the Ready for Approval checkbox is not working properly on Auto Approval  
      IsApproveProcess = CASE WHEN t1.IsApprove = 1 THEN CASE WHEN NOT EXISTS (SELECT 1 FROM POITEMS WHERE PONUM = t1.PONUM AND LCANCEL=0)        
                     THEN 1 ELSE CASE WHEN ItemBal.Bal = 0 THEN 1 ELSE 1 END END ELSE 0 END      
    FROM  #qtyReschPOTemp t1     
    JOIN MRPACT ON t1.UniqMRPAct=MRPACT.UNIQMRPACT      
    JOIN POMAIN PM on PM.PONUM =  t1.tPoNum       
    OUTER APPLY ( SELECT SUM(POITEMS.ORD_QTY - POITEMS.ACPT_QTY) AS Bal FROM POITEMS WHERE POITEMS.PONUM = PM.PONUM AND LCANCEL = 0) ItemBal      
      
   UPDATE MRPACT SET ActionStatus = mrp.ActionStatus --,ActionFailureMsg=mrp.ActionFailureMsg,ActDate=GETDATE(),ActUserId=mrp.ActUserId      
   FROM #qtyReschPOTemp mrp where MRPACT.UniqMRPAct=mrp.UniqMRPAct       
      
   INSERT INTO MRPACTLog(MRPActUniqKey,Uniq_key,Action,Ref,WONO,Balance,ReqQty,DueDate,ReqDate,Days,ActDate,ActUserId,DttAkeact,ActionStatus,EmailStatus,MFGRS)       
   SELECT dbo.fn_GenerateUniqueNumber(),UNIQ_KEY,ACTION,'PO ' + mrp.PONUM,WONO,MRPACT.BALANCE,MRPACT.REQQTY,DUE_DATE ,MRPACT.REQDATE,DAYS,GETDATE(),mrp.ActUserId,    
          DTTAKEACT,mrp.ActionStatus,0,MRPACT.MFGRS     
   FROM #qtyReschPOTemp mrp     
   JOIN MRPACT ON MRPACT.UniqMRPAct=mrp.UniqMRPAct       
    
    --06/03/2020 Shivshankar P : Added the block of code to Insert/Update the purchase order history Notes for PO     
    --06/09/2020 Shivshnakar P : Added the detail information purchase order history Notes for PO for different MRP action   
    --07/15/2020 Shivshnakar P : Added the More detail information in purchase order history Notes for PO for different MRP action     
 --09/09/2020 Shivshnakar P : Change PODATE to GETDATE() and Added the More detail information in purchase order history Notes for PO for Cancel MRP action  
      DECLARE @wmNoteT TABLE (NoteId UNIQUEIDENTIFIER, Note VARCHAR(MAX))              
      DECLARE @Initials varchar(5), @RecordId VARCHAR(15), @ActionTaken VARCHAR(30)         
      SELECT top 1 @Initials = Initials FROM aspnet_profile WHERE userid= @userId      
    
   SELECT @count = count(DISTINCT PONUM) from #qtyReschPOTemp      
   while(@count > 0)      
   BEGIN                 
    SELECT TOP 1 @RecordId = PONUM, @ActionTaken = TRIM(ActionTaken) from #qtyReschPOTemp where IsNoteUpdate = 0      
    SET @count = @count - 1;      
        ----- WMNOTES Table ------     
  --12/15/2020 Shivshankar P : Remove the $ sign from po quantity  
   --12/16/2020 Shivshankar P : Added separate purchase order history Notes for every action  
       IF NOT EXISTS(SELECT 1 FROM WMNOTES WHERE RecordId = @RecordId AND RecordType='pomain_co' AND NoteType = 'Note')      
       BEGIN       
        IF (@ActionTaken = '- PO Qty')    
   BEGIN    
   INSERT INTO WMNOTES (NoteID, [Description], fkCreatedUserID, CreatedDate, IsDeleted, NoteType, RecordId, RecordType, NoteCategory,                
     CarNo, [Priority],IsFollowUpComplete, IssueType, IsCustomerSupport, Progress,IsNewTask)              
   OUTPUT INSERTED.NoteID,INSERTED.[Description]              
   INTO @wmNoteT              
   SELECT NEWID(), N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)  
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)    
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR),               
    @userId, GETDATE(), 0, 'Note', t1.PONUM , 'pomain_co', 2,0,0,0,'',0,0,0     
   FROM #qtyReschPOTemp t1     
   JOIN POMAIN PM ON PM.PONUM =  t1.PONUM    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE t1.PONUM = @RecordId GROUP BY PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO,t1.oldORDQTY, PoIt.ORD_QTY, PoIt.COSTEACH, i.PART_NO, i.REVISION     
   END   
   IF (@ActionTaken = '+ PO Qty')    
   BEGIN    
   INSERT INTO WMNOTES (NoteID, [Description], fkCreatedUserID, CreatedDate, IsDeleted, NoteType, RecordId, RecordType, NoteCategory,                
     CarNo, [Priority],IsFollowUpComplete, IssueType, IsCustomerSupport, Progress,IsNewTask)              
   OUTPUT INSERTED.NoteID,INSERTED.[Description]              
   INTO @wmNoteT              
   SELECT NEWID(), N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)  
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)    
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR),               
    @userId, GETDATE(), 0, 'Note', t1.PONUM , 'pomain_co', 2,0,0,0,'',0,0,0     
   FROM #qtyReschPOTemp t1     
   JOIN POMAIN PM ON PM.PONUM =  t1.PONUM    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE t1.PONUM = @RecordId GROUP BY PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO,t1.oldORDQTY, PoIt.ORD_QTY, PoIt.COSTEACH, i.PART_NO, i.REVISION     
   END   
        IF (@ActionTaken = '- Qty RESCH PO')    
   BEGIN    
   INSERT INTO WMNOTES (NoteID, [Description], fkCreatedUserID, CreatedDate, IsDeleted, NoteType, RecordId, RecordType, NoteCategory,                
     CarNo, [Priority],IsFollowUpComplete, IssueType, IsCustomerSupport, Progress,IsNewTask)              
   OUTPUT INSERTED.NoteID,INSERTED.[Description]              
   INTO @wmNoteT              
   SELECT NEWID(), N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)   
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)   
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR)   
    + ', The Schedule changed for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)   --- 01/15/2021 Rajendra K : Removed time from oldsch_date and newsch_ date while putting into note
    + ' were modified From: ' + CAST(t1.oldSCHD_DATE AS VARCHAR(11)) + ' To: ' + CAST(POITSCHD.SCHD_DATE AS VARCHAR(11)),               
    @userId, GETDATE(), 0, 'Note', t1.PONUM , 'pomain_co', 2,0,0,0,'',0,0,0     
   FROM #qtyReschPOTemp t1     
   JOIN POMAIN PM ON PM.PONUM =  t1.PONUM    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN POITSCHD ON POITSCHD.UNIQDETNO = t1.UNIQDETNO   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE t1.PONUM = @RecordId   
   GROUP BY PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, t1.oldORDQTY, PoIt.ORD_QTY, PoIt.COSTEACH, i.PART_NO, i.REVISION, POITSCHD.SCHD_DATE,t1.oldSCHD_DATE      
   END   
   IF (@ActionTaken = '+ Qty RESCH PO')    
   BEGIN    
   INSERT INTO WMNOTES (NoteID, [Description], fkCreatedUserID, CreatedDate, IsDeleted, NoteType, RecordId, RecordType, NoteCategory,                
     CarNo, [Priority],IsFollowUpComplete, IssueType, IsCustomerSupport, Progress,IsNewTask)              
   OUTPUT INSERTED.NoteID,INSERTED.[Description]              
   INTO @wmNoteT              
   SELECT NEWID(), N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)   
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)   
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR)   
    + ', The Schedule changed for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)   --- 01/15/2021 Rajendra K : Removed time from oldsch_date and newsch_ date while putting into note
    + ' were modified From: ' + CAST(t1.oldSCHD_DATE AS VARCHAR(11)) + ' To: ' + CAST(POITSCHD.SCHD_DATE AS VARCHAR(11)),               
    @userId, GETDATE(), 0, 'Note', t1.PONUM , 'pomain_co', 2,0,0,0,'',0,0,0     
   FROM #qtyReschPOTemp t1     
   JOIN POMAIN PM ON PM.PONUM =  t1.PONUM    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN POITSCHD ON POITSCHD.UNIQDETNO = t1.UNIQDETNO   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE t1.PONUM = @RecordId   
   GROUP BY PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, t1.oldORDQTY, PoIt.ORD_QTY, PoIt.COSTEACH, i.PART_NO, i.REVISION, POITSCHD.SCHD_DATE,t1.oldSCHD_DATE      
   END      
   IF (@ActionTaken LIKE 'RESCH PO%')    
   BEGIN    
   INSERT INTO WMNOTES (NoteID, [Description], fkCreatedUserID, CreatedDate, IsDeleted, NoteType, RecordId, RecordType, NoteCategory,                
     CarNo, [Priority],IsFollowUpComplete, IssueType, IsCustomerSupport, Progress,IsNewTask)              
   OUTPUT INSERTED.NoteID,INSERTED.[Description]              
   INTO @wmNoteT              
   SELECT NEWID(), N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: The Schedule changed for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)  
    + ' were modified From: ' + CAST(t1.oldSCHD_DATE AS VARCHAR(11)) + ' To: ' + CAST(POITSCHD.SCHD_DATE AS VARCHAR(11)),--- 01/15/2021 Rajendra K : Removed time from oldsch_date and newsch_ date while putting into note               
    @userId, GETDATE(), 0, 'Note', t1.PONUM , 'pomain_co', 2,0,0,0,'',0,0,0     
   FROM #qtyReschPOTemp t1     
   JOIN POMAIN PM ON PM.PONUM =  t1.PONUM    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM    
   JOIN POITSCHD ON POITSCHD.UNIQDETNO = t1.UNIQDETNO   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE t1.PONUM = @RecordId GROUP BY PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, POITSCHD.SCHD_DATE , i.PART_NO, i.REVISION, t1.oldSCHD_DATE  
   END           
   IF (@ActionTaken = 'CANCEL PO')    
   BEGIN    
   INSERT INTO WMNOTES (NoteID, [Description], fkCreatedUserID, CreatedDate, IsDeleted, NoteType, RecordId, RecordType, NoteCategory,                
     CarNo, [Priority],IsFollowUpComplete, IssueType, IsCustomerSupport, Progress,IsNewTask)              
   OUTPUT INSERTED.NoteID,INSERTED.[Description]              
   INTO @wmNoteT              
   SELECT NEWID(), N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + (CASE WHEN PoIt.LCANCEL = 0 THEN ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)   
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)   
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR) ELSE '' END)  
    + ', Cancel Status changed for item number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)   
    + ', were modified From ' + CAST(CASE WHEN t1.IsCancel = 1 THEN 'FALSE' ELSE 'TRUE'  END AS VARCHAR) + ' To ' + CAST(CASE WHEN PoIt.LCANCEL = 1 THEN 'TRUE' ELSE 'FALSE' END AS VARCHAR),    
      @userId, GETDATE(), 0, 'Note', t1.PONUM , 'pomain_co', 2,0,0,0,'',0,0,0  --- 01/18/2021 Rajendra K : Changed condition for cancel po item   
   FROM #qtyReschPOTemp t1     
   JOIN POMAIN PM ON PM.PONUM =  t1.PONUM    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE t1.PONUM = @RecordId GROUP BY PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, t1.oldORDQTY, PoIt.ORD_QTY, PoIt.COSTEACH , PoIt.LCANCEL , i.PART_NO, i.REVISION,t1.IsCancel  
   END        
       END      
       ELSE    
       BEGIN    
        IF (@ActionTaken = '- PO Qty')    
   BEGIN    
   INSERT INTO @wmNoteT    
   SELECT NoteID, N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)  
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)   
       + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR)    
   FROM WMNOTES     
   JOIN #qtyReschPOTemp t1 ON t1.PONUM = wmNotes.RecordId    
   JOIN POMAIN PM on PM.PONUM =  t1.tPoNum    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE RecordId = @RecordId AND RecordType='pomain_co' AND NoteType = 'Note'    
   GROUP BY NoteID, PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, PoIt.ORD_QTY, PoIt.COSTEACH , i.PART_NO, i.REVISION, t1.oldORDQTY   
   END   
   IF (@ActionTaken = '+ PO Qty')    
   BEGIN    
   INSERT INTO @wmNoteT    
   SELECT NoteID, N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)  
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)   
       + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR)    
   FROM WMNOTES     
   JOIN #qtyReschPOTemp t1 ON t1.PONUM = wmNotes.RecordId    
   JOIN POMAIN PM on PM.PONUM =  t1.tPoNum    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE RecordId = @RecordId AND RecordType='pomain_co' AND NoteType = 'Note'    
   GROUP BY NoteID, PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, PoIt.ORD_QTY, PoIt.COSTEACH , i.PART_NO, i.REVISION, t1.oldORDQTY   
   END    
        IF (@ActionTaken = '- Qty RESCH PO')    
   BEGIN    
   INSERT INTO @wmNoteT    
   SELECT NoteID, N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)   
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)    
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR)   
    + ', The Schedule changed for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  --- 01/15/2021 Rajendra K : Removed time from oldsch_date and newsch_ date while putting into note
    + ' were modified From: ' + CAST(t1.oldSCHD_DATE AS VARCHAR(11)) + ' To: ' + CAST(POITSCHD.SCHD_DATE AS VARCHAR(11))   
   FROM WMNOTES     
   JOIN #qtyReschPOTemp t1 ON t1.PONUM = wmNotes.RecordId    
   JOIN POMAIN PM on PM.PONUM =  t1.tPoNum    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN POITSCHD ON POITSCHD.UNIQDETNO = t1.UNIQDETNO   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE RecordId = @RecordId AND RecordType='pomain_co' AND NoteType = 'Note'    
   GROUP BY NoteID, PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, PoIt.ORD_QTY, PoIt.COSTEACH , i.PART_NO, i.REVISION, POITSCHD.SCHD_DATE, t1.oldORDQTY, t1.oldSCHD_DATE    
   END   
   IF (@ActionTaken = '+ Qty RESCH PO')    
   BEGIN    
   INSERT INTO @wmNoteT    
   SELECT NoteID, N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)   
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)    
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR)   
    + ', The Schedule changed for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  --- 01/15/2021 Rajendra K : Removed time from oldsch_date and newsch_ date while putting into note
    + ' were modified From: ' + CAST(t1.oldSCHD_DATE AS VARCHAR(11)) + ' To: ' + CAST(POITSCHD.SCHD_DATE AS VARCHAR(11))   
   FROM WMNOTES     
   JOIN #qtyReschPOTemp t1 ON t1.PONUM = wmNotes.RecordId    
   JOIN POMAIN PM on PM.PONUM =  t1.tPoNum    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM   
   JOIN POITSCHD ON POITSCHD.UNIQDETNO = t1.UNIQDETNO   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE RecordId = @RecordId AND RecordType='pomain_co' AND NoteType = 'Note'    
   GROUP BY NoteID, PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, PoIt.ORD_QTY, PoIt.COSTEACH , i.PART_NO, i.REVISION, POITSCHD.SCHD_DATE, t1.oldORDQTY, t1.oldSCHD_DATE    
   END   
        IF (@ActionTaken LIKE 'RESCH PO%')    
   BEGIN    
   INSERT INTO @wmNoteT    
   SELECT NoteID, N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + ', List of Changes: The Schedule changed for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)  
    + ' were modified From: ' + CAST(t1.oldSCHD_DATE AS VARCHAR(11)) + ' To: ' + CAST(POITSCHD.SCHD_DATE AS VARCHAR(11)) --- 01/15/2021 Rajendra K : Removed time from oldsch_date and newsch_ date while putting into note   
   FROM WMNOTES     
   JOIN #qtyReschPOTemp t1 ON t1.PONUM = wmNotes.RecordId    
   JOIN POMAIN PM on PM.PONUM =  t1.tPoNum    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM    
   JOIN POITSCHD ON POITSCHD.UNIQDETNO = t1.UNIQDETNO   
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE RecordId = @RecordId AND RecordType='pomain_co' AND NoteType = 'Note'    
   GROUP BY NoteID, PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, POITSCHD.SCHD_DATE , i.PART_NO, i.REVISION, t1.oldSCHD_DATE  
   END    
        IF (@ActionTaken = 'CANCEL PO')    
   BEGIN    
   INSERT INTO @wmNoteT    
   SELECT NoteID, N'Change was done using MRP actions. CO #: ' + CAST(PM.CONUM AS VARCHAR) + ', Date / Time: ' + CAST(GETDATE() AS VARCHAR)  + ', By User: ' + @Initials +    
    ', PO Total: $' + CAST(PM.POTOTAL AS VARCHAR) + (CASE WHEN PoIt.LCANCEL = 0 THEN ', List of Changes: Order Quantities for Item Number ' + CAST(PoIt.ITEMNO AS VARCHAR)  + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)   
    + ' were modified From: ' + CAST(t1.oldORDQTY AS VARCHAR) + ' To: ' + CAST(PoIt.ORD_QTY AS VARCHAR)   
    + ', New extended Price: $' + CAST((PoIt.ORD_QTY * PoIt.COSTEACH) AS VARCHAR) ELSE '' END)  
    + ', Cancel Status changed for item number ' + CAST(PoIt.ITEMNO AS VARCHAR) + ' Part: #' + CAST(TRIM(i.PART_NO) + '/' + TRIM(i.REVISION) AS VARCHAR)  
    + ', were modified From ' + CAST(CASE WHEN t1.IsCancel = 1 THEN 'FALSE' ELSE 'TRUE' END AS VARCHAR) + ' To ' + CAST(CASE WHEN PoIt.LCANCEL = 1 THEN 'TRUE' ELSE 'FALSE' END AS VARCHAR)    
   FROM WMNOTES     --- 01/18/2021 Rajendra K : Changed condition for cancel po item
   JOIN #qtyReschPOTemp t1 ON t1.PONUM = wmNotes.RecordId    
   JOIN POMAIN PM on PM.PONUM =  t1.tPoNum    
   JOIN POITEMS PoIt ON t1.UNIQLNNO = PoIt.UNIQLNNO AND PoIt.PONUM = t1.PONUM  
   JOIN INVENTOR i on PoIt.UNIQ_KEY = i.UNIQ_KEY  
   WHERE RecordId = @RecordId AND RecordType='pomain_co' AND NoteType = 'Note'    
   GROUP BY NoteID, PM.CONUM, PM.PODATE, PM.POTOTAL, t1.PONUM, PoIt.ITEMNO, PoIt.LCANCEL, t1.oldORDQTY, PoIt.ORD_QTY, PoIt.COSTEACH, i.PART_NO, i.REVISION,t1.IsCancel    
   END    
       END          
  UPDATE #qtyReschPOTemp  SET IsNoteUpdate = 1  WHERE  PONUM = @RecordId       
      END    
       
            ---- wmNoteRelationship Table --------          
   INSERT INTO wmNoteRelationship (NoteRelationshipId,FkNoteId,CreatedUserId,Note,CreatedDate,ReplyNoteRelationshipId)              
         SELECT NEWID(),NoteId,@userId,Note,GETDATE(),NULL FROM @wmNoteT     
    
    END      
      
  IF EXISTS(SELECT 1 FROM @tMrpAct WHERE ([ACTION] ='+ WO Qty' OR [ACTION] = '- WO Qty'  OR [ACTION] ='RESCH WO'      
      OR [ACTION] ='CANCEL WO'  OR [Action] ='+ Qty RESCH WO' OR [Action] = '- Qty RESCH WO' OR [Action] = 'Release WO'))      
        BEGIN      
        SET @isAutRelease = (SELECT dbo.fn_GetMnxModuleSetting ('WOAutoReleaseSetting',null))      
         -- New WO                
        SET @autoWO= (SELECT dbo.fn_GetMnxModuleSetting ('AutoWONumber',null));      
  IF(@autoWO=1)      
  BEGIN      
   SET @lastWONO = (SELECT dbo.fn_GetMnxModuleSetting ('LastWONO',null))      
  END      
            
        ;WITH tempWo AS(      
           SELECT CASE WHEN @autoWO = 1 THEN RIGHT('0000000000'+ CONVERT(VARCHAR,@lastWONO + ROW_NUMBER() OVER (ORDER BY MRPACT.WONO)),10)       
                   ELSE RIGHT('0000000000'+ CONVERT(VARCHAR,TRIM(MRPACT.WONO)),10) END AS WONUMBER,      
             UNIQ_KEY,'OPEN' AS STATUS,'STANDARD' AS STANDARD, GETDATE() AS ORDERDATE,DTTAKEACT,REQDATE,STARTDATE,      
             0 AS COMPLETE,MRPACT.REQQTY AS BLDQTY,MRPACT.REQQTY AS BALANCE,      
             --SO.CUSTNO --ref      
             CASE WHEN MRPACT.REF LIKE '%Dem SO%' THEN SO.CUSTNO      
                  WHEN MRPACT.REF LIKE '%Kit Shortag%' THEN WOCustom.CUSTNO      
                  WHEN MRPACT.REF LIKE '%Dem WO%' THEN WOCust.CUSTNO -- 02/11/2020 Shivshankar P : Get customer name for only 'WO' and 'Dem WO'      
             WHEN MRPACT.REF LIKE '%Safety Stock%' THEN '000000000~'      
                  ELSE CASE WHEN WONOCust.CUSTNO IS NOT NULL THEN WONOCust.CUSTNO ELSE '' END      
               END AS CUSTNO      
             ,SO.SONO,SO.UNIQUELN,0 AS KIT,NULL AS RELEDATE,PRJUNIQUE ,0 AS LFCSTITEM --RELEASEDBY,CREATEDBYUSERID,KITUNIQWH      
             ,MRPACT.UniqMRPAct      
             --'' AS ErrorMesg      
           FROM  @tMrpAct t1     
           JOIN MRPACT on t1.UniqMRPAct=MRPACT.UNIQMRPACT      
           OUTER APPLY (SELECT TOP 1 SOMAIN.SONO,SODETAIL.UNIQUELN,SOMAIN.CUSTNO FROM SOMAIN      
                               LEFT JOIN SODETAIL ON SOMAIN.SONO=SODETAIL.SONO AND SODETAIL.UNIQ_KEY= MRPACT.UNIQ_KEY      
                               WHERE SOMAIN.SONO = RTRIM(LTRIM(replace(MRPACT.REF,'Dem SO','')))    
           ) SO      
            --- 11/02/20 YS all outer apply have to have MRPACT removed from internal SQL and linked to the main MRPACT    
           OUTER APPLY (    
     --SELECT TOP 1 CUSTNO FROM MRPACT         
     --                          JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(replace(MRPACT.REF,'WO',''),' Kit Shortag','')))      
   SELECT CUSTNO FROM WOENTRY         
                               WHERE WOENTRY.WONO = RTRIM(LTRIM(replace(replace(MRPACT.REF,'WO',''),' Kit Shortag','')))     
                       ) WOCustom      
           -- 02/11/2020 Shivshankar P : Get customer name for only 'WO' and 'Dem WO'      
           --- 11/02/20 YS all outer apply have to have MRPACT removed from internal SQL and linked to the main MRPACT     
     OUTER APPLY (    
     --SELECT top 1 CUSTNO FROM MRPACT         
     --                          JOIN WOENTRY ON WOENTRY.WONO = RTRIM(LTRIM(replace(MRPACT.REF,'Dem WO','')))        
   SELECT CUSTNO FROM WOENTRY where WOENTRY.WONO = RTRIM(LTRIM(replace(MRPACT.REF,'Dem WO','')))        
                       ) WOCust       
   --- 11/02/20 YS all outer apply have to have MRPACT removed from internal SQL and linked to the main MRPACT         
           OUTER APPLY (SELECT CUSTNO FROM WOENTRY WHERE WOENTRY.WONO = RTRIM(LTRIM(replace(MRPACT.REF,'WO','')))        
                       ) WONOCust      
         WHERE MRPACT.ACTION LIKE '%RELEASE WO%')      
         ,tempWoEnt AS (SELECT TT.WONO AS WOWN, * FROM tempWo WN      
                         OUTER APPLY (SELECT WONO FROM WOENTRY WHERE WN.WONUMBER = WOENTRY.WONO) TT )      
      
   ,tempTotalWoEnt AS (      
     SELECT CASE WHEN @autoWO = 1 THEN WONUMBER ELSE WONUMBER END AS TEWONO,* FROM tempWoEnt       
     OUTER APPLY (SELECT MAX(WONUMBER) AS WON FROM tempWoEnt WHERE 1=0) TT      
     WHERE ISNULL(WOWN,'') = ''      
     UNION ALL      
     SELECT CASE WHEN @autoWO = 1 THEN RIGHT('0000000000'+ CONVERT(VARCHAR,TT.WON + ROW_NUMBER() OVER (ORDER BY TT.WON )),10) ELSE WONUMBER END AS TEWONO, * FROM tempWoEnt      
     OUTER APPLY (SELECT MAX(WONUMBER) AS WON FROM tempWoEnt) TT      
    WHERE ISNULL(WOWN,'') <> '')      
      
    --INSERT INTO WOENTRY (WONO,UNIQ_KEY,OPENCLOS,JobType,ORDERDATE,DUE_DATE,START_DATE,COMPLETE,BLDQTY,BALANCE,CUSTNO,      
    --      SONO,UNIQUELN,KIT,RELEDATE,PRJUNIQUE,[LFCSTITEM],ReleasedBy,CreatedByUserId,KitUniqWh)      
          --06/12/2020 Shivshankar P : Added the OUTER APPLY and condition and generate the error if the Customer is not available in system     
    SELECT 0 AS ISUPDATE,TEWONO,WOWN,WONUMBER,UNIQ_KEY,STATUS,STANDARD,ORDERDATE,DTTAKEACT,REQDATE,STARTDATE,COMPLETE,BLDQTY,BALANCE,     
      ISNULL(TEMPTOTALWOENT.CUSTNO,'000000000~') AS CUSTNO,      
      ISNULL(SONO,'') AS SONO, ISNULL(UNIQUELN,'') AS UNIQUELN,CASE WHEN @isAutRelease = 1 THEN 1 ELSE 0 END AS KIT,      
      CASE WHEN @isAutRelease = 1 THEN GETDATE() ELSE RELEDATE END AS RELEDATE,      
      CASE WHEN @isAutRelease = 1  THEN @userId ELSE NULL END AS ReleasedBy,    
      PRJUNIQUE,LFCSTITEM,UniqMRPAct ,      
      CASE WHEN (WOWN IS NOT NULL OR WOWN <>'') AND @autoWO=0 THEN 'WO number already exists' ELSE     
      CASE WHEN (C.CUSTNO IS NULL OR C.CUSTNO = '' OR TEMPTOTALWOENT.CUSTNO <> C.CUSTNO) THEN N'Customer ' + TEMPTOTALWOENT.CUSTNO + ' is not available in system for SO ' + SONO ELSE '' END END AS ErrorMesg      
    INTO #TEMPWO      
    FROM TEMPTOTALWOENT     
    OUTER APPLY (SELECT TOP 1 CUSTNO FROM CUSTOMER WHERE TEMPTOTALWOENT.CUSTNO = CUSTOMER.CUSTNO) C    
    ORDER BY TEWONO      
     --- 10/29/20 YS added code to find a parent if the Action is to release a new work order and the reference is PWO (purposed work order). We will need to find a customer number    
 --select * from #TEMPWO    
     
 --- based on the source for the PWO in the reference    
     
 ;with    
 PWO    
 as    
 (    
 select t.uniq_key,t.uniqmrpact,m.[action],m.ref,t.wonumber,m.wono, m.uniqmrpact as OriginalUniqMrpAct,    
 cast(0 as integer) as [Level]        
 from #TEMPWO t    
 inner join MRPACT m on t.uniqmrpact=m.UNIQMRPACT     
 where [action]='Release WO     '   and left(ref,7)='Dem PWO'       
 UNION ALL    
 SELECT  b2.uniq_key,b2.uniqmrpact,b2.[action],b2.ref,p.wonumber,b2.wono,P.OriginalUniqMrpAct,    
 P.[Level]+1 as [Level]    
 FROM PWO as P INNER JOIN mrpact B2 ON SUBSTRING(P.ref,5,10) = B2.WONO     
 )    
 select pwo.*,    
 isnull(w.custno,isnull(so.custno,'')) as custno     
 INTO #PWOwithCustomer    
 from PWO     
 left outer join woentry W on left(pwo.ref,7)<>'Dem PWO'     
  and (W.WONO = RTRIM(LTRIM(replace(pwo.REF,'Dem WO','')))     
   or W.WOno=RTRIM(LTRIM(replace(replace(pwo.REF,'WO',''),' Kit Shortag','')))     
   OR W.WONO = RTRIM(LTRIM(replace(pwo.REF,'Dem WO',''))) )          
  left outer join somain so on left(pwo.ref,6)='Dem SO' and so.sono=TRIM(replace(pwo.ref,'Dem SO',''))    
      
 ---select * from #PWOwithCustomer    
 update #TEMPWO set custno = isnull(t.custno,'000000000~') from #PWOwithCustomer t where t.OriginalUniqMrpAct=[#TEMPWO].UNIQMRPACT  and t.custno<>'' and [#TEMPWO].custno=''     
 update #TEMPWO set ErrorMesg=CASE WHEN CUSTNO='' then 'Cannot Identify Customer' ELSE ISNULL(ErrorMesg,'') END    
 --- END of modifications 10/29/20 YS     
   IF EXISTS(SELECT 1 FROM #TEMPWO)      
   BEGIN      
     INSERT INTO WOENTRY (WONO,UNIQ_KEY,OPENCLOS,JobType,ORDERDATE,DUE_DATE,START_DATE,COMPLETE,BLDQTY,BALANCE,CUSTNO,SONO,UNIQUELN,KIT,RELEDATE,PRJUNIQUE,[LFCSTITEM],ReleasedBy,CreatedByUserId,KitUniqWh)      
     SELECT TEWONO, UNIQ_KEY,[STATUS],[STANDARD],ORDERDATE,REQDATE,STARTDATE,COMPLETE,BLDQTY,BALANCE,CUSTNO,SONO,UNIQUELN,KIT,RELEDATE,PRJUNIQUE,LFCSTITEM,ReleasedBy,@userId ,''      
        FROM #TEMPWO WHERE ErrorMesg =''      
      
 --09/16/2020 Shivshankar P : Changed @CompleteDT NUMERIC to @CompleteDT SMALLDATETIME becouse SP NewSchPlanningAdjustWOStart parameter having SMALLDATETIME type  
     DECLARE @totalWOCount INT,@TWONumber CHAR(10),@StartDate SMALLDATETIME,@CompleteDT SMALLDATETIME      
     SET @totalWOCount =  (select COUNT(DISTINCT TEWONO) from #TEMPWO WHERE ErrorMesg ='')        
     --print @totalWOCount      
     WHILE (@totalWOCount > 0)      
    BEGIN       
     --06/12/2020 Shivshankar P : Changed @CompleteDT= COMPLETEDT to @CompleteDT= REQDATE for WO MRP Take action and if REQDATE is NULL then Todays date    
     SELECT  TOP 1  @TWONumber = TEWONO,@StartDate=STARTDATE, @CompleteDT= ISNULL(REQDATE,GETDATE()) FROM #TEMPWO WHERE  ISUPDATE =0 AND ErrorMesg =''      
     SET @totalWOCount = @totalWOCount -1;      
     EXEC NewSchPlanningAdjustWOStart @TWONumber,@StartDate,@CompleteDT,@userId,1      
     UPDATE #TEMPWO SET  ISUPDATE = 1 WHERE TEWONO =  @TWONumber AND ErrorMesg =''      
    END         
      
     INSERT INTO MRPACTLog(MRPActUniqKey,Uniq_key,Action,Ref,WONO,Balance,ReqQty,DueDate,ReqDate,Days,ActDate,ActUserId,DttAkeact,ActionStatus, EmailStatus ,MFGRS)       
     SELECT dbo.fn_GenerateUniqueNumber(),mrp.UNIQ_KEY,ACTION,REF,MRPACT.WONO,MRPACT.BALANCE,MRPACT.REQQTY,DUE_DATE,MRPACT.REQDATE,DAYS,GETDATE(),@userId,    
      MRPACT.DTTAKEACT,'Success',0,MRPACT.MFGRS      
     FROM #TEMPWO mrp     
     JOIN MRPACT ON MRPACT.UniqMRPAct=mrp.UniqMRPAct       
     WHERE ErrorMesg =''      
      
     UPDATE MRPACT set ActionStatus = CASE WHEN ErrorMesg ='' THEN 'Success' ELSE '' END, actionNotes = ErrorMesg      
     FROM #TEMPWO mrp where MRPACT.UniqMRPAct=mrp.UniqMRPAct       
          
     IF(@autoWO=1)      
      UPDATE wmSettingsManagement SET settingValue = (SELECT MAX(TEWONO) FROM #TEMPWO)       
       WHERE settingId IN (SELECT settingId FROM MnxSettingsManagement WHERE settingName = 'LastWONO')      
   END      
      -- Change      
      SELECT BldQty = CASE WHEN t1.[ACTION] ='+ Qty RESCH WO ' OR  t1.[ACTION] ='+ WO' THEN (MRPACT.REQQTY)        
       WHEN  t1.[ACTION] ='- Qty RESCH WO ' OR  t1.[ACTION] ='- WO' THEN (MRPACT.REQQTY)        
       ELSE 0 END ,      
             CurrQty = CASE WHEN t1.[ACTION] ='+ Qty RESCH WO '  OR  t1.[ACTION] ='+ WO'THEN (BLDQTY + MRPACT.REQQTY)      
       WHEN t1.[ACTION] ='- Qty RESCH WO ' OR  t1.[ACTION] ='- WO' THEN (BLDQTY - t1.BALANCE)      
       ELSE 0 END,      
        -- BALANCE = SCHD_QTY-RECDQTY,      
        woEnr.WONO,--DEPT_QTY.UNIQUEREC ,      
        t1.ActionFailureMsg,--,MRPACT.ActDate,      
        t1.ActUserId,t1.ActionStatus,t1.UniqMRPAct,t1.REQQTY,      
        IsQtyResc = CASE WHEN  t1.ACTION ='+ Qty RESCH WO' OR  t1.ACTION ='- Qty RESCH WO' THEN 1 ELSE 0 END ,      
        IsQty = CASE WHEN  t1.ACTION ='+ WO Qty' OR  t1.[ACTION] ='- WO Qty' THEN 1 ELSE 0 END ,      
        IsResc = CASE WHEN  t1.ACTION ='RESCH WO' OR t1.[ACTION] ='+ Qty RESCH WO' OR t1.[ACTION] ='- Qty RESCH WO' THEN 1 ELSE 0 END,      
        MRPACT.REQDATE,MRPACT.STARTDATE,      
        WOStatus = CASE WHEN  t1.ACTION ='CANCEL WO' THEN 'Cancel' ELSE woEnr.OPENCLOS END      
        ,'0' AS ISUPDATE      
   --wentry.ResQty > 0) --02/06/2020 Shivshankar P : change the condition generate the error if the Wo is kitted and user want to cancel it     
   --06/11/2020 Shivshankar P : Added the condition and generate the error if the MRP Balance and WO Balance does not match      
        ,(CASE WHEN (MRPACT.ACTION = 'Cancel WO' AND KITSTATUS = 'KIT PROCSS') THEN 'Work Order has been Kitted. Please de-kit work order before cancelling.' ELSE     
  CASE WHEN (MRPACT.BALANCE <> woEnr.BALANCE) AND (t1.ACTION ='+ Qty RESCH WO' OR  t1.ACTION ='- Qty RESCH WO' OR t1.ACTION ='+ WO Qty' OR  t1.[ACTION] ='- WO Qty')    
   THEN 'MRP Balance and WO Balance does not match' ELSE '' END END) AS ErrorMesg        
        INTO #tempWoEntry --02/04/2020 Shivshankar P : Added the #tempWoEntry table and generate the error if the Wo is kitted and user want to cancel it      
        FROM  @tMrpAct t1     
        JOIN MRPACT on t1.UniqMRPAct=MRPACT.UNIQMRPACT       
        JOIN WOENTRY woEnr on woEnr.wono = MRPACT.WONO      
        --OUTER APPLY      
        --(      
        -- SELECT SUM(k.allocatedQty) as ResQty,w.KITSTATUS       
        -- FROM WOENTRY w JOIN KAMAIN k ON w.WONO = k.WONO       
        -- WHERE w.WONO = MRPACT.WONO AND w.KITSTATUS = 'KIT PROCSS'      
        -- GROUP BY k.WONO,w.KITSTATUS      
        --)AS wentry      
        WHERE (t1.[action] = '+ WO Qty' OR t1.[ACTION] ='- WO Qty' OR  t1.[ACTION] = 'Cancel WO' OR t1.[ACTION] =  'RESCH WO'      
        OR t1.[ACTION] ='+ Qty RESCH WO' OR  t1.[ACTION] ='- Qty RESCH WO')      
                    
      SELECT * INTO #qtyReschWOTemp FROM #tempWoEntry  WHERE ErrorMesg = '' or ErrorMesg IS NULL      
        
  UPDATE WOENTRY SET   
  BLDQTY = CASE WHEN IsQtyResc = 1 OR IsQty=1 THEN #qtyReschWOTemp.ReqQty + WOENTRY.COMPLETE ELSE WOENTRY.BLDQTY END ,        
  BALANCE = CASE WHEN IsQtyResc = 1 OR IsQty=1 THEN #qtyReschWOTemp.ReqQty ELSE WOENTRY.BALANCE END,        
  DUE_DATE = CASE WHEN IsQtyResc = 1 OR IsResc =1 THEN  #qtyReschWOTemp.REQDATE ELSE WOENTRY.DUE_DATE END,   
  -- 06/11/2020 Sachin B Update START_DATE,ORDERDATE,COMPLETEDT  
  -- 07/22/2020 Shivshankar P Update Work Order Date (Woentry.OrderDate).can not be changed by any actions accept new actions And Work Order Complete Date (Woentry.CompleteDt) is updated only when balance becomes zero   
  --[START_DATE] = CASE WHEN IsQtyResc = 1 OR IsResc =1 THEN  #qtyReschWOTemp.REQDATE ELSE WOENTRY.[START_DATE] END,   
  ORDERDATE = WOENTRY.ORDERDATE,   
  COMPLETEDT = CASE WHEN BALANCE = 0 THEN  #qtyReschWOTemp.REQDATE ELSE WOENTRY.COMPLETEDT END,                       
        OPENCLOS= WOStatus      
  FROM #qtyReschWOTemp WHERE WOENTRY.WONO=#qtyReschWOTemp.WONO      
      
      --UPDATE DEPT_QTY SET CURR_QTY = CASE WHEN IsQtyResc = 1 OR IsQty=1  THEN WOENTRY.BALANCE ELSE DEPT_QTY.CURR_QTY END       
      --     FROM #qtyReschWOTemp temp JOIN WOENTRY on  temp.WONO = WOENTRY.WONO      
      --      where temp.WONO=DEPT_QTY.WONO AND NUMBER =1      
            
      UPDATE MRPACT SET ActionStatus =mrp.ActionStatus FROM #qtyReschWOTemp mrp where MRPACT.UniqMRPAct=mrp.UniqMRPAct       
      
      --02/04/2020 Shivshankar P : Added the #tempWoEntry table and generate the error if the Wo is kitted and user want to cancel it      
      UPDATE MRPACT SET ActionNotes = mrp.ErrorMesg FROM #tempWoEntry mrp WHERE MRPACT.UniqMRPAct=mrp.UniqMRPAct and ISNULL(ErrorMesg,'') <>''     
       
   --06/10/2020 Shivshankar P : Added ActDate as current date when we take WO MRP Actions by using GETDATE()    
      INSERT INTO MRPACTLog(MRPActUniqKey,Uniq_key,Action,Ref,WONO,Balance,ReqQty,DueDate,ReqDate,Days,ActDate,ActUserId,DttAkeact,ActionStatus, EmailStatus ,MFGRS)       
      SELECT dbo.fn_GenerateUniqueNumber(),UNIQ_KEY,ACTION,REF,MRPACT.WONO,MRPACT.BALANCE,MRPACT.REQQTY,DUE_DATE,MRPACT.REQDATE,DAYS,GETDATE(),mrp.ActUserId,DTTAKEACT,mrp.ActionStatus,0,MRPACT.MFGRS                   
      FROM #qtyReschWOTemp mrp     
   JOIN MRPACT ON MRPACT.UniqMRPAct=mrp.UniqMRPAct       
               
      -- 06/19/2020 Sachin B Fix the Issue Wrong Qty is Updaed in the WC  
   IF EXISTS (SELECT 1 FROM @tDeptQty)      
   BEGIN     
         UPDATE DEPT_QTY SET CURR_QTY = temp.CURR_QTY   
   FROM @tDeptQty temp WHERE temp.UNIQUEREC = DEPT_QTY.UNIQUEREC    
   END  
  
        -- 02/05/2020 Shivshankar P : Changed the Curr_Qty selection and removed the condition in outer apply and where clause       
        -- 06/10/2020 Shivshankar P : Remove Top 1 selection because when we take multiple WO MRP Action need to update CURR_QTY in DEPT_QTY table      
        INSERT INTO @tempDeptQty (UNIQUEREC,CURR_QTY)  (      
        SELECT woDpt.UNIQUEREC AS UNIQUEREC,      
                     CASE WHEN IsQtyResc = 1 OR IsQty=1   
      THEN CASE WHEN q1.ReqQty > ISNULL(woDpt1.sqty ,0) THEN q1.ReqQty - ISNULL(woDpt1.sqty ,0) ELSE q1.ReqQty END    
      ELSE woDpt.CURR_QTY END CURR_QTY      
        --CASE WHEN woDpt.WONO IS NOT NULL THEN CURR_QTY       
        --       WHEN woDpt.WONO IS  NULL and BALANCE > sqty THEN sqty + BALANCE       
        --       WHEN woDpt.WONO IS  NULL and BALANCE < sqty THEN sqty - BALANCE       
        --       ELSE 0       
        --      END  CURR_QTY      
          --,woDpt.WONO,woDpt1.sqty      
          --,woDpt1.WONO,DEPT_ID       
          FROM DEPT_QTY       
          JOIN #qtyReschWOTemp  q1 ON DEPT_QTY.WONO = q1.WONO       
          JOIN WOENTRY on q1.WONO = WOENTRY.WONO      
          OUTER APPLY       
          (      
     SELECT WONO,UNIQUEREC,CURR_QTY FROM DEPT_QTY       
     WHERE WONO =q1.WONO and DEPT_ID IN ('STAG') --1      
            --GROUP BY WONO -- having count(WONO) < 2      
          ) woDpt      
          OUTER APPLY      
          (       
             SELECT WONO,Sum(CURR_QTY) as sqty        
             FROM DEPT_QTY       
             WHERE CURR_QTY > 0 AND WONO =q1.WONO and DEPT_ID NOT IN ('FGI','SCRP','STAG')  --1      
             GROUP BY WONO  --having count(WONO) > 1      
          ) woDpt1      
         WHERE DEPT_ID NOT IN ('FGI','SCRP') AND (IsQtyResc = 1 OR IsQty=1)       
         --02/05/2020 Shivshankar P : Changed the Curr_Qty selection and removed the condition in outer apply and where clause       
         --AND (q1.WONO =  woDpt.WONO OR q1.WONO =  woDpt1.WONO)      
         --   and DEPT_QTY.WONO =  woDpt.WONO and  UNIQUEREC NOT IN (SELECT UNIQUEREC  FROM @tDeptQty)       
         --   and ((woDpt.WONO IS NOT NULL AND NUMBER =1) OR (woDpt.WONO  IS NULL AND CURR_QTY > 0))     
            
         --UNION       
         --SELECT UNIQUEREC,CURR_QTY  FROM @tDeptQty       
         )      
      
        --select * from @tempDeptQty      
      
      IF EXISTS (SELECT 1 FROM @tempDeptQty)      
   BEGIN     
         UPDATE DEPT_QTY SET CURR_QTY = temp.CURR_QTY   
   FROM @tempDeptQty temp WHERE temp.UNIQUEREC = DEPT_QTY.UNIQUEREC    
   END     
  
   -- 06/19/2020 Sachin B Fix the Issue Wrong Qty is Updaed in the WC  
   IF NOT EXISTS(SELECT 1 FROM @tDeptQty)  
   BEGIN  
  UPDATE  t1  
  SET  t1.CURR_QTY = CASE WHEN t2.ReqQty > ISNULL(woDpt1.sqty ,0) THEN t1.CURR_QTY ELSE 0 END     
  FROM DEPT_QTY t1  
  INNER JOIN #qtyReschWOTemp t2 ON t1.WONO =t2.WONO AND (IsQtyResc = 1 OR IsQty=1)  
  INNER JOIN WOENTRY on t2.WONO = WOENTRY.WONO      
  OUTER APPLY      
        (       
             SELECT WONO,Sum(CURR_QTY) as sqty        
             FROM DEPT_QTY       
             WHERE CURR_QTY > 0 AND WONO =t2.WONO and DEPT_ID NOT IN ('FGI','SCRP','STAG')  --1      
             GROUP BY WONO  --having count(WONO) > 1      
        ) woDpt1   
  WHERE  t1.DEPT_ID NOT IN ('FGI','SCRP','STAG')      
   END   
         
  -- 07/24/2020 Shivshankar P Modify and Move the SP NewSchPlanningAdjustWOStart Call after updating DEPT_QTY table  
  DECLARE @wono CHAR(10), @REQDATE DATETIME, @StartDt DATETIME  
  DECLARE WorkOrder_cursor CURSOR  
  FOR SELECT wono,REQDATE,STARTDATE FROM #qtyReschWOTemp WHERE IsQtyResc = 1 OR IsResc =1  
  
  OPEN WorkOrder_cursor;  
  FETCH NEXT FROM WorkOrder_cursor  
  INTO @wono,@REQDATE,@StartDt;  
  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
      EXEC NewSchPlanningAdjustWOStart @wono,@StartDt,@REQDATE,@userId,1;  
   FETCH NEXT FROM WorkOrder_cursor  
   INTO @wono,@REQDATE,@StartDt;  
  END;  
  
  CLOSE WorkOrder_cursor;  
  DEALLOCATE WorkOrder_cursor;  
   
   DECLARE @totWOCount INT,@tempWONumber CHAR(10),@strtDate SMALLDATETIME,@comltDT NUMERIC      
      SET @totWOCount =  (select COUNT(DISTINCT WONO) from #qtyReschWOTemp WHERE IsQtyResc <> 1 OR IsResc <>1)        
      --print @totalWOCount      
      WHILE (@totalWOCount > 0)      
        BEGIN       
         SELECT  TOP 1  @tempWONumber = WONO,@strtDate=STARTDATE ,@comltDT= REQDATE FROM #qtyReschWOTemp WHERE  ISUPDATE =0 and IsQtyResc <> 1 OR IsResc <>1      
         SET @totWOCount = @totWOCount -1;      
         EXEC NewSchPlanningAdjustWOStart @tempWONumber,@strtDate,@comltDT,@userId,1      
         UPDATE #qtyReschWOTemp SET  ISUPDATE = 1 WHERE WONO =  @tempWONumber       
      END   
  
      IF EXISTS (SELECT 1 FROM @tInvtser)      
      DELETE FROM INVTSER WHERE SerialUniq IN (SELECT invt.SerialUniq FROM  @tInvtser invt JOIN INVTSER ON INVTSER.SerialUniq= invt.SerialUniq)      
      
    END      
  END TRY       
  BEGIN CATCH      
    IF @@TRANCOUNT <>0      
      ROLLBACK TRAN ;      
      SELECT @ErrorMessage = ERROR_MESSAGE(),      
          @ErrorSeverity = ERROR_SEVERITY(),      
          @ErrorState = ERROR_STATE();      
      RAISERROR (@ErrorMessage, -- Message text.      
          @ErrorSeverity, -- Severity.      
           @ErrorState -- State.      
           );      
  END CATCH       
      
 IF @@TRANCOUNT>0     
   COMMIT TRANSACTION;       
END 