-- =============================================          
-- Author:  Shivshankar P          
-- Create date: 01/22/18          
-- Description: Take MRP New PO Action  
-- 02/05/2020 Shivshankar P : Decrease PO number by one        
-- 02/05/2020 Shivshankar P : Changed the block of code auto approval not working  
-- 02/10/2020 Shivshankar P : Remove Remit and Confirm address from ErrorMessage becouse it is not mendatory to create po     
-- 03/02/2020 : Rajendra K : Remove selection of the package field from inventor table and added outer join to take the part_pkg from MfgrMaster table 
-- 04/16/2020 Satyawan H. : Changed rt.UserPartMfgr to rt.UserMfgrPtNo because it is optional not rt.UserPartMfgr
-- 04/16/2020 Satyawan H. : Added conditon to Check where t.UNIQSUPNO is NOT NULL & NOT EMPTY 
-- 04/27/2020 Satyawan H. : Changed originalCommitDt from GETDATE() to t.DTTAKEACT 
-- 06/02/2020 Shivshankar P : Chnage the NoteType, RecordType, NoteCategory for the Change Order History Note and also insert ReplyNoteRelationshipId = null
-- 06/30/2020 Shivshankar P : If the setting requires the approval then the "Ready for Approval" checkbox should be auto-engaged
-- 08/20/2020 Rajendra k : Get the "defaultOverage" setting and insert into POITEMS.Overage column
-- Shivshankar P 09/15/20: Get max PriceEach to insert COSTEACH for the same part in the POITEMS 
-- 10/26/2020 : Shivshankar P : Added dbo.fn_ConverQtyUOM to get the s_ord_qty based on the u_of_meas, pur_uofm
-- EXEC TakeMRpActions @tMrpAct=@p1          
-- =============================================          
CREATE PROCEDURE  [dbo].[MRPNewPOActions]          
(          
	@tMrpAct tMrpAct READONLY,          
	--@isTakeAll bit=0,          
	@userId  UNIQUEIDENTIFIER,          
	--@tDeptQty tDeptQty READONLY          
	@isTakeAllAct BIT =0          
)          
AS          
BEGIN          
    
 SET NOCOUNT ON;          
 DECLARE @ErrorMessage NVARCHAR(4000);          
 DECLARE @ErrorSeverity INT;          
 DECLARE @ErrorState INT;          
          
 BEGIN TRANSACTION          
 BEGIN TRY          
  --SET @isTakeAllAct = 1          
  DECLARE @tMrpActTemp dbo.tMrpAct  
  	DECLARE @overageSettingValue NUMERIC(5,2);-- 08/20/2020 Rajendra k : Get the "defaultOverage" setting and insert into POITEMS.Overage column 
  	SELECT @overageSettingValue = CAST(CASE WHEN ISNULL(WM.SettingValue,'') = '' THEN MS.settingValue ELSE WM.SettingValue END AS NUMERIC(5,2)) 
	FROM MnxSettingsManagement MS LEFT JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId 
	WHERE SettingName = 'defaultOverage'        
          
  IF(@isTakeAllAct=1)          
  BEGIN          
   INSERT INTO @tMrpActTemp (UniqKey,DtToTak) EXEC [GetNewPOAction] @isTakeAllAct = 1,@startRecord=1          
  END          
  ELSE           
  BEGIN          
   INSERT INTO @tMrpActTemp  SELECT * FROM @TMRPACT          
  END           
         
		-- Update the details of supplier and qty for contract       
		UPDATE rt set     
		  rt.UserReqQty = CASE WHEN rt.UserReqQty > 0 THEN rt.UserReqQty  ELSE rt.REQQTY  END      
		 ,userprice = ISNULL(mfgr.Price,0)        
		 ,UniqSupNo = ISNULL(mfgr.UNIQSUPNO,'')      
		 ,UserPartMfgr= ISNULL(mfgr.PARTMFGR,'')      
		 ,UserMfgrPtNo = ISNULL(mfgr.MFGR_PT_NO,'')    
		FROM MRPACT rt     
		 JOIN inventor ir on rt.UNIQ_KEY = ir.UNIQ_KEY          
		 JOIN @tMrpActTemp t on  t.UniqKey = rt.uniq_key and CAST(t.DtToTak AS DATE) = CAST(rt.DTTakeAct AS dATE)          
		 OUTER APPLY (    
				 SELECT * FROM (        
						SELECT  SUPINFO.supname ,Quantity,CONTMFGR.PARTMFGR,CONTMFGR.MFGR_PT_NO        
						 ,CONTPRIC.Price , ISNULL(lag(QUANTITY) OVER (ORDER BY quantity),0)   AS StartNo        
						 ,Quantity AS Qty ,lead(QUANTITY) OVER (ORDER BY quantity) AS EndNo       
						 ,SUPINFO.UNIQSUPNO      
						 FROM CONTMFGR         
						 JOIN CONTPRIC ON CONTPRIC.MFGR_UNIQ = CONTMFGR.MFGR_UNIQ        
						 JOIN  CONTRACT ON CONTRACT.CONTR_UNIQ = CONTMFGR.CONTR_UNIQ        
						 JOIN contractHeader ON contractHeader.ContractH_unique =  CONTRACT.contractH_unique      
						 JOIN MfgrMaster on CONTMFGR.PARTMFGR = MfgrMaster.PartMfgr      
						      AND CONTMFGR.MFGR_PT_NO =  MfgrMaster.mfgr_pt_no         
						      AND MfgrMaster.is_deleted = 0        
						 JOIN InvtMPNLink on MfgrMaster.MfgrMasterId =  InvtMPNLink.MfgrMasterId       
						      AND InvtMPNLink.uniq_key = ir.UNIQ_KEY AND InvtMPNLink.is_deleted = 0        
						 JOIN INVTMFGR on InvtMPNLink.uniqmfgrhd = INVTMFGR.UNIQMFGRHD      
						      AND ir.UNIQ_KEY = INVTMFGR.UNIQ_KEY         
						      AND INVTMFGR.is_deleted = 0         
						 JOIN WAREHOUS on INVTMFGR.UNIQWH  = WAREHOUS.UNIQWH and WAREHOUS.IS_DELETED = 0        
						 JOIN SUPINFO ON ((ISNULL(rt.UniqSupNo,'') != '' AND rt.UniqSupNo = SUPINFO.UNIQSUPNO)    
						  OR (ISNULL(rt.UniqSupNo,'') =  '' AND contractHeader.uniqsupno =SUPINFO.uniqsupno)      
						  AND SUP_TYPE <> 'DISQUALIFIED' AND [Status] <> 'INACTIVE' AND [Status] <> 'DISQUALIFIED')        
						WHERE ((ISNULL(rt.UserPartMfgr,'') !=  ''  AND CONTMFGR.PARTMFGR  = rt.UserPartMfgr         
						            AND CONTMFGR.MFGR_PT_NO =  rt.UserMfgrPtNo)        
						 OR (ISNULL(rt.UserPartMfgr ,'') =''       
						  AND CONTMFGR.PARTMFGR = RTRIM( SUBSTRING(PREFAVL,0,CHARINDEX(' ',PREFAVL,0)))        
						  AND CONTMFGR.MFGR_PT_NO = LTRIM(RIGHT(SUBSTRING(PREFAVL,CHARINDEX(' ',PREFAVL),300),120))))        
					) t        
		     WHERE (( rt.UserReqQty > 0 AND  StartNo <=  rt.UserReqQty AND Qty >= rt.UserReqQty )        
		             OR (rt.UserReqQty < 1 AND  StartNo <=  rt.REQQTY AND Qty >= rt.REQQTY ))         
		 ) mfgr         
		WHERE rt.ACTION ='Release PO' AND (rt.actionstatus <>'Success' OR rt.actionstatus IS NULL)       
		AND (rt.UniqSupNo='' OR rt.UniqSupNo IS NULL)    
      -- / Update the details of supplier and qty for contract       
         
  DECLARE @wmNoteT TABLE (NoteId UNIQUEIDENTIFIER, Note VARCHAR(MAX))          
  DECLARE @Initials varchar(5)      
  SELECT @Initials = Initials FROM aspnet_profile WHERE userid= @userId          
          
  IF OBJECT_ID('tempdb..#poItem') IS NOT NULL DROP TABLE #poItem          
  
  DECLARE @poNum Char (15),@poItemUniq Varchar(10), @isAutoApprove BIT, @tempPO CHAR (15) = 'T00000000000000'        
  ,@approvedPO CHAR (15) = '000000000000000',@actualPO CHAR (15),@isAutoManualPO BIT          
 
 EXEC [GetNextPONumber] @pcNextNumber = @poNum OUTPUT                
 --02/05/2020 Shivshankar P : Decrease PO number by one       
  SET @poNum=(select RIGHT('000000000000000'+CAST((CAST(@poNum as int) - 1) AS VARCHAR(15)),15))             
  --SET @poNum =  right('000000000000000'+ rtrim(dbo.fn_GetMnxModuleSetting('LastPONumber',DEFAULT) + 1), 15)           
                
  SET @isAutoApprove = dbo.fn_GetMnxModuleSetting('ApprovePOWhenImporting',DEFAULT)                 
       
   ;with mrpPOs as (               
    SELECT           
     CASE WHEN UserReqQty > 0  THEN rt.UserReqQty ELSE rt.REQQTY  END AS ReqQtys,          
     --CASE WHEN UserPrice > 0 THEN UserPrice ELSE PRICE END PriceEach          
     UserPrice AS PriceEach        
     ,mfgr.UNIQSUPNO  as uniqSup,rt.UNIQ_KEY, rt.UserPartMfgr PARTMFGR,rt.UserMfgrPtNo  MFGR_PT_NO         
     ,ir.PART_NO,ir.REVISION, ir.DESCRIPT,ir.PUR_UOFM,ir.U_OF_MEAS          
     ,ir.INSP_REQ ,UNIQWH ,WH_GL_NBR ,UNIQMFGRHD ,R_LINK          
     --,CASE WHEN shipc.LINKADD IS NULL THEN '' ELSE  C_LINK END CLink          
     ,ISNULL(C_LINK,'') AS CLink, shipl.ILink, shipb.BLink, MfgrMasterId          
     ,cast(DTTAKEACT AS DATE) DTTAKEACT, Terms, Fob, SHIPCHARGE          
     ,SHIPVIA , ShipTime          
	 --,PACKAGE   -- 03/02/2020 : Rajendra K : Remove selection of the package field from inventor table and added outer join to take the part_pkg from MfgrMaster table    
     ,LDISALLOWBUY           
     ,rt.UNIQMRPACT          
     ,rt.ActionNotes           
    FROM MRPACT rt     
    JOIN inventor ir on rt.UNIQ_KEY = ir.UNIQ_KEY          
    JOIN @tMrpActTemp t on  t.UniqKey = rt.uniq_key and CAST(t.DtToTak AS DATE) = CAST(rt.DTTakeAct AS dATE)                 
    OUTER APPLY (    
     SELECT top 1 * FROM (          
			SELECT  SUPINFO.supname ,SUPINFO.UNIQSUPNO,INVTMFGR.UNIQWH,WAREHOUS.WH_GL_NBR       
			,INVTMFGR.UNIQMFGRHD,R_LINK ,C_LINK, MfgrMaster.MfgrMasterId,TERMS,LDISALLOWBUY,SUPID          
			FROM MfgrMaster       
			JOIN InvtMPNLink on MfgrMaster.MfgrMasterId = InvtMPNLink.MfgrMasterId       
			     AND InvtMPNLink.uniq_key = ir.UNIQ_KEY     
			     AND InvtMPNLink.is_deleted = 0       
			JOIN INVTMFGR on InvtMPNLink.uniqmfgrhd = INVTMFGR.UNIQMFGRHD        
			     AND ir.UNIQ_KEY = INVTMFGR.UNIQ_KEY     
			     and INVTMFGR.is_deleted = 0           
			JOIN WAREHOUS on INVTMFGR.UNIQWH  = WAREHOUS.UNIQWH and WAREHOUS.IS_DELETED = 0  AND WAREHOUS.Warehouse<>'WO-WIP'     
			     AND WAREHOUS.Warehouse<>'WIP'    
			     AND WAREHOUS.Warehouse<>'MRB'       
			JOIN SUPINFO ON (rt.UniqSupNo = SUPINFO.UNIQSUPNO     
			    AND SUP_TYPE <> 'DISQUALIFIED'          
			    AND Status <> 'INACTIVE' AND Status <> 'DISQUALIFIED')       
			WHERE  ((ISNULL(rt.UserPartMfgr,'') !=  '' AND MfgrMaster.PARTMFGR  = rt.UserPartMfgr           
			    AND MfgrMaster.MFGR_PT_NO =  rt.UserMfgrPtNo)          
				  -- 04/16/2020 Satyawan H. : Changed rt.UserPartMfgr to rt.UserMfgrPtNo because it is optional not rt.UserPartMfgr
			    OR (ISNULL(rt.UserMfgrPtNo ,'') =''         
			    AND MfgrMaster.PARTMFGR = RTRIM( SUBSTRING(PREFAVL,0,CHARINDEX(' ',PREFAVL,0)))          
			    AND MfgrMaster.MFGR_PT_NO = LTRIM(RIGHT(SUBSTRING(PREFAVL,CHARINDEX(' ',PREFAVL),300),120))))          
			 ) t WHERE ISNULL(t.UNIQSUPNO,'') !=  '' -- 04/16/2020 Satyawan H. : Added conditon to Check where t.UNIQSUPNO is NOT NULL & NOT EMPTY 
     ) mfgr         
	          
    OUTER APPLY (    
     select LINKADD ILink ,Fob,SHIPCHARGE,SHIPVIA ,SHIPTIME from SHIPBILL     
     where RECORDTYPE ='I' AND RECV_DEFA = 1 AND  ISNULL(CUSTNO,'') =''    
    ) shipl  --I_LINK          
    OUTER APPLY (select LINKADD BLink from SHIPBILL where RECORDTYPE ='P' and RECV_DEFA = 1 and  ISNULL(CUSTNO,'') ='') shipb --B_LINK          
    OUTER APPLY (    
     SELECT ShipBill.LINKADD FROM Shipbill     
     LEFT OUTER JOIN ccontact ON (Shipbill.custno+'S'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )     
     WHERE ShipBill.Custno = mfgr.SUPID AND Recordtype='C'    
    ) shipc           
    --OUTER APPLY ( SELECT ShipBill.*, RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) AS AttnName FROM Shipbill LEFT OUTER JOIN ccontact           
    --ON  (Shipbill.custno+'S'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid ) WHERE ShipBill.Custno = mfgr.UNIQSUPNO AND           
    --Recordtype='R' ) shipr --I_LINK          
    WHERE rt.ACTION ='Release PO' AND (rt.actionstatus <>'Success' OR rt.actionstatus IS NULL)         
    --AND DTTakeAct = '2018-10-18 00:00:00'            
   )          
          
   SELECT ReqQtys AS ReqQtys,PriceEach as PriceEach        
    ,uniqSup,UNIQ_KEY,MfgrMasterId ,PARTMFGR,MFGR_PT_NO          
    ,PART_NO,REVISION,DESCRIPT,PUR_UOFM,U_OF_MEAS,INSP_REQ,UNIQWH    
    ,WH_GL_NBR,UNIQMFGRHD,R_LINK,CLink,ILink,BLink          
    ,cast(DTTAKEACT AS DATE) DTTAKEACT          
    ,dbo.fn_GenerateUniqueNumber() AS POUnique             
    ,dbo.fn_GenerateUniqueNumber() AS UniqLnno          
    ,Terms           
    ,Fob          
    ,SHIPCHARGE          
    ,SHIPVIA          
    ,ShipTime                 
	--,PACKAGE  -- 03/02/2020 : Rajendra K : Remove selection of the package field from inventor table and added outer join to take the part_pkg from MfgrMaster table       
    ,'Invt Recv' POITTYPE,LDISALLOWBUY,UNIQMRPACT          
    ,CASE WHEN LDISALLOWBUY = 1 THEN 'Do not Buy against this Manufacturer ,' ELSE '' END +          
     CASE WHEN ISNULL(uniqSup,'')='' THEN  'Supplier Does not exists ,' ELSE '' END +          
     --CASE WHEN ISNULL(R_LINK,'')='' THEN  'Remit Address not exists ,'  ELSE '' END +      --02/10/2020 Shivshankar P : Remove Remit and Confirm address from ErrorMessage becouse it is not mendatory to create po    
     --CASE WHEN ISNULL(CLink,'')='' THEN  'Confirm Address not exists ,'  ELSE '' END +          
     CASE WHEN ISNULL(ILink,'')='' THEN  'Invoice Address not exists ,'  ELSE '' END +          
     CASE WHEN ISNULL(BLink,'')='' THEN  'Billing Address not exists ,'           
    ELSE '' END  AS ErrorMessage          
   INTO #poItem            
   FROM mrpPOs           
   GROUP BY uniqSup,UNIQ_KEY,MfgrMasterId ,PARTMFGR,MFGR_PT_NO,PART_NO,REVISION,DESCRIPT,PUR_UOFM    
     ,U_OF_MEAS,INSP_REQ,UNIQWH,WH_GL_NBR,UNIQMFGRHD,R_LINK,CLink,ILink,BLink,DTTAKEACT          
					,ReqQtys,PriceEach,Terms,Fob,SHIPCHARGE,SHIPVIA ,ShipTime,LDISALLOWBUY,UNIQMRPACT -- ,PACKAGE      
       
	SELECT * FROM #poItem

   --POItems-----          
   ;WITH poMainItem AS (          
    SELECT RIGHT('000'+CAST(ROW_NUMBER() OVER (PARTITION BY t.uniqSup ORDER BY t.uniqSup) AS VARCHAR(3)),3) AS aliascol1    
     ,STUFF(RIGHT(@tempPO + LTRIM(REPLACE(@poNum,'T','0') + Dense_rank() OVER (ORDER BY t.uniqSup)) ,15),1,1    
     ,CASE WHEN @isAutoApprove = 0 THEN 'T' ELSE  '0' END) AS PONo    
     ,Dense_rank() OVER (ORDER BY t.uniqSup,t.uniq_key ,t.MfgrMasterId) AS poItem,*     
    FROM #poItem t           
   )          
          
   SELECT ISNULL(LAG(poItem) over(order by poitem),1) st          
    ,poitem as itemSeq        
    ,LEAD(poitem) over(order by poitem) [end]        
    ,CASE WHEN ISNULL(LAG(poItem) over(order by poitem),0) = poitem THEN null ELSE dbo.fn_GenerateUniqueNumber() END as uniqItem        
    ,'0' IsUpdate,*          
   INTO #temp         
   FROM poMainItem          
          
   --- POMain Table----  
   -- 06/30/2020 Shivshankar P : If the setting requires the approval then the "Ready for Approval" checkbox should be auto-engaged
   INSERT INTO POMAIN (ponum,podate,POSTATUS,VERDATE,POTOTAL,TERMS,C_LINK,R_LINK,I_LINK,B_LINK,FOB, SHIPCHARGE,SHIPVIA,DELTIME ,POPRIORITY,VERINIT,UNIQSUPNO,    
						POCHANGES, POUNIQUE,POTOTALPR,IsApproveProcess,aspnetBuyer)           
   SELECT pono,GETDATE(),'NEW',GETDATE(), sum(ReqQtys), Terms,CLink,R_LINK,ILink,BLink,Fob, ShipCharge,Shipvia,ShipTime, 'Standard',@Initials ,uniqSup,          
        N'New PO created by User: ' + @Initials +', on ' +  CAST(GETDATE () AS VARCHAR) +', PO Total: $' + CAST(sum(ReqQtys)  AS VARCHAR) AS POCHANGES,    
        dbo.fn_GenerateUniqueNumber(),sum(ReqQtys),CASE WHEN @isAutoApprove = 0 THEN 1 ELSE 0 END,@userId          
   FROM #temp where uniqSup IS NOT NULL          
   GROUP BY uniqSup,R_LINK,CLink,ILink,BLink,Terms,Fob,ShipCharge,Shipvia,ShipTime,pono          
          
   --- POItem Table -----          
   -- 08/20/2020 Rajendra k : Get the "defaultOverage" setting and insert into POITEMS.Overage column 
   INSERT INTO POITEMS (ponum,uniqlnNo,uniq_key,itemno,costeach,ord_qty,poittype,partmfgr,mfgr_pt_no,package,u_of_meas,pur_uofm,s_ord_qty,uniqmfgrhd,OVERAGE)            
   SELECT PONo,uniqItem,uniq_key ,RIGHT('000'+CAST(ROW_NUMBER() OVER (PARTITION BY uniqSup ORDER BY uniqSup) AS VARCHAR(3)),3) AS ItemNo          
   -- 03/02/2020 : Rajendra K : Remove selection of the package field from inventor table and added outer join to take the part_pkg from MfgrMaster table  
   -- 10/26/2020 : Shivshankar P : Added dbo.fn_ConverQtyUOM to get the s_ord_qty based on the u_of_meas, pur_uofm
   ,poItemsQ.PriceEach,poItemsQ.Reqty,'Invt Part',PARTMFGR,MFGR_PT_NO,ISNULL(PartPkg.part_pkg,''),U_OF_MEAS,PUR_UOFM,ROUND(dbo.fn_ConverQtyUOM(pur_uofm, u_of_meas ,poItemsQ.Reqty),2),UNIQMFGRHD,@overageSettingValue            
   FROM #temp r   
   -- Shivshankar P 09/15/20: Get max PriceEach to insert COSTEACH for the same part in the POITEMS
   OUTER APPLY (    
				SELECT sum(z.ReqQtys) AS Reqty, max(z.PriceEach) AS PriceEach FROM #temp z     
				WHERE z.uniqSup =  r.uniqSup          
				 and z.MfgrMasterId = r.MfgrMasterId           
				 and z.UNIQ_KEY=r.UNIQ_KEY           
				 and z.PONo = r.PONo           
				GROUP BY z.uniqSup,z.MfgrMasterId,z.UNIQ_KEY ,z.PONo          
              ) poItemsQ          
   OUTER APPLY (-- 03/02/2020 : Rajendra K : Remove selection of the package field from inventor table and added outer join to take the part_pkg from MfgrMaster table 
				SELECT part_pkg FROM MfgrMaster WHERE r.MfgrMasterId = MfgrMasterId
			   ) PartPkg			    
   WHERE uniqItem IS NOT NULL AND  uniqSup  is not null          
   GROUP BY uniqSup,UNIQ_KEY,MfgrMasterId ,PARTMFGR,MFGR_PT_NO,PART_NO,REVISION,DESCRIPT,PUR_UOFM,U_OF_MEAS,INSP_REQ,UNIQWH,WH_GL_NBR,UNIQMFGRHD,
			R_LINK,CLink,ILink,BLink,poItem,PONo,uniqItem,poItemsQ.Reqty,poItemsQ.PriceEach,PartPkg.part_pkg    
			-- 03/02/2020 : Rajendra K : Remove selection of the package field from inventor table and added outer join to take the part_pkg from MfgrMaster table   
   ORDER BY poItem          
                               
   ----- POITSCHD Table -------           
   INSERT INTO POITSCHD (uniqlnno,uniqdetno,schd_date,req_date,schd_qty,recdqty,balance,gl_nbr,requesttp,uniqwh,ponum,origcommitdt)          
   SELECT COALESCE(uniqItem, MAX(uniqItem) over (partition by poitem)) as UniqLnno, dbo.fn_GenerateUniqueNumber(),
		 t.DTTAKEACT, GETDATE(), ReqQtys,0,ReqQtys,WH_GL_NBR ,POITTYPE,uniqwh ,PONo, t.DTTAKEACT 
		 -- 04/27/2020 Satyawan H. : Changed originalCommitDt from GETDATE() to t.DTTAKEACT          
   FROM (    
     SELECT t.*,MAX(CASE WHEN uniqItem IS NOT NULL then uniqItem end) over (order by poitem) as maxid          
     FROM #temp t     
     WHERE uniqSup IS NOT NULL          
    ) t;          
    
   UPDATE MRPACT      
    SET  actionNotes = mrp.ErrorMessage          
     ,UserReqQty = CASE WHEN mrp.ErrorMessage IS NULL OR mrp.ErrorMessage ='' THEN mrp.ReqQtys ELSE UserReqQty END          
     ,UserPrice= CASE WHEN  mrp.ErrorMessage IS NULL OR mrp.ErrorMessage ='' THEN mrp.PriceEach ELSE UserPrice END           
     ,UniqSupNo =  CASE WHEN  mrp.ErrorMessage IS NULL OR mrp.ErrorMessage ='' THEN mrp.uniqSup ELSE UniqSupNo END           
     ,UserPartMfgr = CASE WHEN  mrp.ErrorMessage IS NULL OR mrp.ErrorMessage ='' THEN mrp.PARTMFGR ELSE UserPartMfgr END           
     ,UserMfgrPtNo = CASE WHEN  mrp.ErrorMessage IS NULL OR mrp.ErrorMessage ='' THEN mrp.MFGR_PT_NO ELSE UserMfgrPtNo END           
     ,ActionStatus = CASE WHEN  mrp.ErrorMessage IS NULL  OR mrp.ErrorMessage ='' THEN 'Success' ELSE '' END           
   FROM #temp mrp           
   WHERE MRPACT.UniqMRPAct=mrp.UniqMRPAct --AND uniqSup IS NULL          
              
   DECLARE @tpoNum VARCHAR(15), @noSetup BIT,@cpoNum VARCHAR(15)          
    --02/05/2020 Shivshankar P : Changed the block of code auto approval not working              
   DECLARE @count int          
   SELECT @count = count(DISTINCT PONo) from #temp          
   WHILE(@count > 0)          
   BEGIN          
    SELECT TOP 1 @tpoNum = PONo from #temp where IsUpdate = 0          
    SET @count= @count - 1;          
    SET @cpoNum = @tpoNum          
    IF(@isAutoApprove = 0)            
    BEGIN            
		EXEC ProcessApprovePO @tpoNum, @userId, @noSetup OUT          
		IF (@noSetup = 1)          
		BEGIN          
			SET @cpoNum = LTRIM(REPLACE(@tpoNum,'T','0'))          
			UPDATE POMAIN SET IsApproveProcess = 1, POStatus = 'OPEN', PONUM = LTRIM(REPLACE(@tpoNum,'T','0')) WHERE PONUM = @tpoNum          
			UPDATE POITEMS SET PONUM = LTRIM(REPLACE(@tpoNum,'T','0')) WHERE PONUM = @tpoNum          
            UPDATE POITSCHD SET PONUM = LTRIM(REPLACE(@tpoNum,'T','0')) WHERE PONUM = @tpoNum          
		END          
    UPDATE #TEMP  SET ISUPDATE = 1 ,PONO= @CPONUM WHERE  PONO = @TPONUM                  
    END          
    ELSE  
    BEGIN  
      UPDATE POMAIN SET IsApproveProcess = 1, POStatus = 'OPEN', PONUM = LTRIM(REPLACE(@tpoNum,'T','0')) WHERE PONUM = @tpoNum            
      UPDATE POITEMS SET PONUM = LTRIM(REPLACE(@tpoNum,'T','0')) WHERE PONUM = @tpoNum            
      UPDATE POITSCHD SET PONUM = LTRIM(REPLACE(@tpoNum,'T','0')) WHERE PONUM = @tpoNum     
      UPDATE #TEMP  SET ISUPDATE = 1 ,PONO= LTRIM(REPLACE(@tpoNum,'T','0'))  WHERE  PONO = @TPONUM     
    END          
   END            
          
   ------MRPACTLog TABLE ------          
   INSERT INTO MRPACTLog(MRPActUniqKey,Uniq_key,[Action],Ref,WONO,Balance,ReqQty,DueDate,ReqDate,[Days],ActDate,ActUserId,DttAkeact,ActionStatus, EmailStatus ,MFGRS)           
   SELECT dbo.fn_GenerateUniqueNumber(),rt.UNIQ_KEY,[ACTION],  'PO ' + mrp.PONo,rt.WONO,rt.BALANCE,rt.REQQTY,DUE_DATE,rt.REQDATE,[DAYS], GETDATE(),@userId,          
     rt.DTTAKEACT, 'Success',0,mrp.PARTMFGR  + ' ' + mrp.MFGR_PT_NO           
   FROM #temp mrp JOIN MRPACT rt ON rt.UniqMRPAct=mrp.UniqMRPAct     
   WHERE uniqSup  IS NOT NULL          
    
   -- 06/02/2020 Shivshankar P : Chnage the NoteType, RecordType, NoteCategory for the Change Order History Note and also insert ReplyNoteRelationshipId = null
   ----- WMNOTES Table ------      
   INSERT INTO WMNOTES (NoteID, [Description], fkCreatedUserID, CreatedDate, IsDeleted, NoteType, RecordId, RecordType, NoteCategory,            
     CarNo, [Priority],IsFollowUpComplete, IssueType, IsCustomerSupport, Progress,IsNewTask)          
   OUTPUT INSERTED.NoteID,INSERTED.[Description]          
   INTO @wmNoteT          
   SELECT NEWID(), N'New PO created using MRP actions by User: ' + @Initials +', ON: ' + CAST(GETDATE () AS VARCHAR) +', PO Total: $' + CAST(sum(ReqQtys) AS VARCHAR),           
    @userId, GETDATE(), 0, 'Note', PONO, 'pomain_co', 2,0,0,0,'',0,0,0 
   FROM #temp WHERE uniqSup is not null          
   GROUP BY uniqSup ,R_LINK,CLink,ILink,BLink,Terms,Fob,ShipCharge,Shipvia,ShipTime,PONO           
   
   ---- wmNoteRelationship Table --------      
   INSERT INTO wmNoteRelationship (NoteRelationshipId,FkNoteId,CreatedUserId,Note,CreatedDate,ReplyNoteRelationshipId)          
   SELECT NEWID(),NoteId,@userId,Note,GETDATE(),NULL FROM @wmNoteT                
              
   SET @tpoNum = (select REPLACE(MAX(PONo),'T','0') FROM #TEMP)                
   UPDATE w SET w.settingValue= @tpoNum 
   FROM wmsettingsmanagement w            
   JOIN MnxSettingsManagement m ON w.settingId = m.settingId             
   WHERE m.settingName='LastPONumber'           
 END TRY           
 BEGIN CATCH          
  IF @@TRANCOUNT <> 0          
  ROLLBACK TRAN ;          
  SELECT @ErrorMessage = ERROR_MESSAGE(),          
   @ErrorSeverity = ERROR_SEVERITY(),          
   @ErrorState = ERROR_STATE();          
  RAISERROR (@ErrorMessage, -- Message text.          
       @ErrorSeverity, -- Severity.          
       @ErrorState -- State.          
  );          
  RETURN;          
 RETURN          
 END CATCH           
          
 IF @@TRANCOUNT>0          
   COMMIT TRANSACTION
END