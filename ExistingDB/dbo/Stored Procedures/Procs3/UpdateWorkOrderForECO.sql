-- Author:  Vijay G                                                                         
-- Create date: 09/01/2019                                                                     
-- DescriptiON: Used to update work order for newly created  assembly from ECO                                                               
-- Modified Vijay G: 26/11/2019 Added additional filter wono to update record               
-- Modified Vijay G: 26/11/2019 Update WONO column by value of new WO                  
-- Modified Vijay G: 27/11/2019 Insert uniq id UNIQUEREC column                    
-- Modified Vijay G: 27/11/2019 Delete records from tKamain          
-- Modified Vijay G: 24/12/2019 De-Kit the qty of component which removed from BOM                                                    
-- Modified Vijay G: 24/02/2020 Updated routing workcenter info of workorder qty base on new assembly    
-- Modified Sachin B: 27/03/2020 Added loop to increment last genrated number while it exists in system 
-- Modified Sachin B: 12/15/2020 Remove Condition AND ID_VALUE in (SELECT DEPTKEY FROM DEPT_QTY WHERE wono =@wono AND DEPT_ID<>'FGI')
-- Modified Sachin B: 12/15/2020 Update SerialStart Column in Dept_Qty Table      
--EXEC [UpdateWorkOrderForECO] '_14C0OQLVM','N4T2U1IS5C','RNZFJJTZUK','49f80792-e15e-4b62-b720-21b360e3108a'                                               
--==============================================================                                                      
CREATE PROCEDURE [dbo].[UpdateWorkOrderForECO]                                                                
(                                                                
 @oldUniqKey VARCHAR(10)  ,                                                           
 @newUniqKey VARCHAR(10)  ,                                                            
 @uniqEcNo VARCHAR(10)   ,                                  
 @userId uniqueidentifier                                                        
)                                                                
AS                                                                              
BEGIN                                                                   
                                                              
DECLARE @ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT               
DECLARE @Initials VARCHAR(8),@wono varchar(10) ,@fgiQTY NUMERIC(5) ,@serialYes BIT=0,@newWOQty NUMERIC(5),@uniquerout VARCHAR(10),            
        @delUniq_key VARCHAR(10),@delDept VARCHAR(10),@itemNo VARCHAR(10),@tKamain tKamain ,@serialCompYes bit,@sidCompYes bit,            
  @kaSeqNum VARCHAR(10)            
DECLARE @WONOs TABLE(wono VARCHAR(10))             
DECLARE @DeletedComponents TABLE(uniq_key VARCHAR(10),DeptId VARCHAR(10),itemNo VARCHAR(10))               
DECLARE @intoInvtRes TABLE (invtres_no CHAR(10),refinvtres CHAR(10),qtyAlloc NUMERIC(12,2),KaSeqnum VARCHAR(10))                                                                                     
SELECT @Initials = (SELECT Initials FROM aspnet_Profile WHERE UserId =@userid)               
                                                
SET NOCOUNT ON;                                                                  
BEGIN TRY                                                   
BEGIN TRANSACTION                                                                                                                                               
SELECT @serialYes =SERIALYES FROM INVENTOR WHERE UNIQ_KEY=@oldUniqKey                                                      
                                                      
INSERT INTO @WONOs                                                                  
SELECT w.WONO FROM ECWO e JOIN WOENTRY w ON e.WONO=w.WONO WHERE e.UNIQECNO=@uniqEcNo AND w.OPENCLOS NOT IN('Closed','Cancel')                                                      
                                                      
SELECT @uniquerout= uniquerout FROM routingProductSetup WHERE Uniq_key=@newUniqKey AND isDefault=1                                                      
                                                           
WHILE (SELECT COUNT(*) FROM @WONOs) > 0                                          
BEGIN                                                      
	 SELECT TOP 1 @wono=  wono FROM @WONOs                         
	 SELECT @fgiQTY = CURR_QTY FROM DEPT_QTY WHERE WONO =@wono AND DEPT_ID='FGI'              
	 IF(@fgiQTY=0)                                                      
	 BEGIN          
		  -- Modified Vijay G: 24/12/2019 De-Kit the qty of component which removed from BOM            
		 INSERT INTO @DeletedComponents(uniq_key,DeptId ,itemNo )            
		 SELECT uniq_key,DEPT_ID ,ITEM_NO from ECDETL            
		 WHERE UNIQECNO=@uniqEcNo AND DETSTATUS='Delete'            
            
		 IF(EXISTS(SELECT 1 FROM INVT_RES WHERE WONO=@wono))                                     
		 BEGIN                                
			  WHILE (SELECT COUNT(*) FROM @DeletedComponents) > 0                
			  BEGIN            
				   SELECT TOP 1 @delUniq_key=uniq_key,@delDept=DeptId,@itemNo=itemNo from @DeletedComponents            
   
				   SELECT @kaSeqNum=kaSeqNum 
				   FROM KAMAIN WHERE WONO=@wono AND uniq_key=@delUniq_key AND DEPT_ID=@delDept AND BOMPARENT=@oldUniqKey             
   
				   EXEC CloseRemovedComponant  @wono, @kaSeqNum,@userId,1                    
				   DELETE FROM @DeletedComponents where  uniq_key=@delUniq_key            
			  END                               
		 END              
			-- Modified Vijay G: 24/02/2020 Updated routing workcenter info of workorder qty base on new assembly       
			DECLARE @delQty NUMERIC=0          
		
			SELECT @delQty= SUM(t.CURR_QTY) FROM DEPT_QTY t  
			WHERE  wono =@wono AND DEPTKEY NOT IN (SELECT UNIQNUMBER FROM ECQUOTDEPT WHERE uniqueRout=@uniquerout)           
             
			DELETE t FROM DEPT_QTY t
			WHERE  wono =@wono AND DEPTKEY NOT IN (SELECT UNIQNUMBER FROM ECQUOTDEPT WHERE uniqueRout=@uniquerout)           
                                                    
			UPDATE t SET t.DEPTKEY=NEW_UNIQNUMBER 
			FROM DEPT_QTY t 
			JOIN ECQUOTDEPT e ON UNIQNUMBER=DEPTKEY AND t.NUMBER=e.NUMBER           
			WHERE uniqueRout=@uniquerout AND wono =@wono          
            
			-- Modified Sachin B: 12/15/2020 Update SerialStart Column in Dept_Qty Table
			INSERT INTO DEPT_QTY(DEPT_ID ,WONO,CURR_QTY,XFER_QTY,XFER_MIN,XFER_SETUP,NUMBER,CAPCTYNEED,SCHED_STAT,DUEOUTDT,DEPT_PRI,DEPTKEY,WO_WC_NOTE,UNIQUEREC,SERIALSTRT)          
			SELECT q.DEPT_ID,@wono,0,0,0,0,q.NUMBER,0,'',GETDATE(),0,q.UNIQNUMBER,'',dbo.fn_GenerateUniqueNumber(),SERIALSTRT 
			FROM QUOTDEPT q  WHERE q.uniqueRout=@uniquerout          
			AND q.UNIQNUMBER NOT IN(SELECT DEPTKEY FROM DEPT_QTY WHERE WONO=@wono)          
            
			UPDATE t SET t.CURR_QTY=isnull(t.CURR_QTY+isnull(@delQty,0),0) FROM DEPT_QTY t WHERE t.DEPT_ID='STAG' AND wono =@wono          
             
			UPDATE WOENTRY SET UNIQ_KEY=@newUniqKey,uniquerout=@uniquerout WHERE WONO=@wono                                 
			UPDATE KAMAIN SET BOMPARENT=@newUniqKey WHERE WONO=@wono                                   
	   IF(@serialYes=1)                                                      
	   BEGIN                       
		  -- Modified Vijay G: 27/11/2019 Added additional filter wono to update record 
		  -- Modified Sachin B: 12/15/2020 Remove Condition AND ID_VALUE in (SELECT DEPTKEY FROM DEPT_QTY WHERE wono =@wono AND DEPT_ID<>'FGI')                                                     
		  UPDATE INVTSER 
		  SET UNIQ_KEY=@newUniqKey ,               
		  ID_VALUE=(SELECT DEPTKEY FROM DEPT_QTY WHERE wono =@wono AND DEPT_ID ='STAG')               
		  WHERE ID_KEY ='DEPTKEY' --AND ID_VALUE in (SELECT DEPTKEY FROM DEPT_QTY WHERE wono =@wono AND DEPT_ID<>'FGI')               
		  AND wono =@wono                                                     
	   END                                         
	 END                                                                   
   ELSE                              
	  BEGIN                                                      
			/*Used to get last work order no */                                                      
			DECLARE @lastWONO VARCHAR(10)                                                        
			SELECT @lastWONO = CASE WHEN w.settingId IS NOT NULL THEN w.settingValue ELSE m.settingValue END                                                      
			FROM MnxSettingsManagement m                                                       
			JOIN wmSettingsManagement w ON w.settingId = m.settingId                                    
			WHERE settingName = 'LastWONO'                                                      
                                               
			 DECLARE @newWono varchar(20)=RIGHT('0000000000'+ CONVERT(VARCHAR,@lastWONO + 1),10),@deptId varchar(20)   
			 -- Modified Sachin B: 27/03/2020 Added loop to increment last genrated number while it exists in system  
			 WHILE EXISTS(SELECT 1 FROM WOENTRY WHERE WONO=@newWono)   
			 BEGIN   
				SET  @newWono =RIGHT('0000000000'+ CONVERT(VARCHAR,@newWono + 1),10)  
			 END                                            
			SELECT @newWOQty=(w.BLDQTY-d.CURR_QTY) FROM WOENTRY w JOIN DEPT_QTY d ON w.WONO=d.WONO WHERE w.WONO=@wono AND DEPT_ID='FGI'                                               
                                                        
			/*Used to update work order*/                                      
			UPDATE DEPT_QTY SET CURR_QTY=0 WHERE WONO=@wono AND DEPT_ID<>'FGI'                                                                                    
    
			UPDATE WOENTRY                                                       
			SET BLDQTY= (SELECT CURR_QTY FROM DEPT_QTY  WHERE WONO=@wono AND DEPT_ID='FGI'),                                                      
			OPENCLOS='Closed',                                                      
			BALANCE = 0                                                      
			WHERE WONO=@wono                                                      
                                                   
			/*Used to add new work order for new assembly*/                                                      
			INSERT INTO WOENTRY(WONO,UNIQ_KEY,OPENCLOS,ORDERDATE,DUE_DATE,BLDQTY,BALANCE,KITSTATUS,[START_DATE],CUSTNO,KIT,RELEDATE,                                
			SERIALYES,KITSTARTINIT,LFCSTITEM,LIS_RWK,JobType,uniquerout)                                                      
			SELECT @newWono,@newUniqKey,'Open',GETDATE(),GETDATE(),@newWOQty,@newWOQty,KITSTATUS,[START_DATE],CUSTNO,KIT,RELEDATE,SERIALYES,                                
			KITSTARTINIT,LFCSTITEM,LIS_RWK,JobType,ISNULL(@uniquerout,'')                                                     
			FROM WOENTRY WHERE WONO=@wono                                                                       
			/*Used to update last genrated work order number*/                                             
			UPDATE w SET w.settingValue=@newWono                                                       
			FROM wmSettingsManagement w JOIN MnxSettingsManagement m ON w.settingId = m.settingId                                                       
			WHERE settingName = 'LastWONO'                                         
                                               
			/*Used to delete serial numbers for Wo*/                                                      
		  IF(@serialYes=1)                                                      
		  BEGIN                                                                            
		  -- Modified Vijay G: 27/11/2019 Update WONO column by value of new WO   
		  -- Modified Sachin B: 12/15/2020 Remove Condition AND ID_VALUE in (SELECT DEPTKEY FROM DEPT_QTY WHERE wono =@wono AND DEPT_ID<>'FGI')                                                                              
		   UPDATE INVTSER               
		   SET UNIQ_KEY=@newUniqKey ,               
		   WONO = @newWono,              
		   ID_VALUE=(SELECT DEPTKEY FROM DEPT_QTY WHERE wono =@newWono AND DEPT_ID ='STAG')               
		   WHERE ID_KEY ='DEPTKEY' --AND ID_VALUE IN (SELECT DEPTKEY FROM DEPT_QTY WHERE wono =@wono AND DEPT_ID<>'FGI') 
		   AND wono =@wono                                                     
		  END                                       
                                  
		  IF(EXISTS(SELECT 1 FROM KAMAIN WHERE WONO=@wono))                                 
		  BEGIN                                                                     
			INSERT INTO @tKamain EXEC [KitBomInfoView] @gWono=@newWono                    
			--Used to insert records in KAMAIN                                                                        
			INSERT INTO KAMAIN(WONO,DEPT_ID,UNIQ_KEY,ACT_QTY,KITCLOSED,ENTRYDATE,KASEQNUM,BOMPARENT,SHORTQTY,QTY,REF_DES,IGNOREKIT,sourceDev,allocatedQty,userid,INITIALS)                                              
			SELECT @newWono,Dept_id,Uniq_key,0,0,GETDATE(),UniqueId,BomParent,ShortQty,Qty,'',0,'W',0 ,@userId,@Initials                                            
			FROM @tKamain                                 
                                                                       
			UPDATE WOENTRY SET KITSTATUS='KIT PROCSS' WHERE WONO=@newWono                                              
    
			-- Modified Vijay G: 27/11/2019 Insert uniq id UNIQUEREC column                                      
			INSERT INTO KADETAIL(KASEQNUM, AUDITBY ,AUDITDATE, SHORTBAL, SHQUALIFY, SHORTQTY, SHREASON, UNIQUEREC, Wono, editUserId)                                              
			SELECT UniqueId,'',GETDATE(),ShortQty,'ADD',ShortQty,'KIT MODULE',dbo.fn_GenerateUniqueNumber(), @newWono,@userId                                         
			FROM @tKamain                  
    
			-- Modified Vijay G: 27/11/2019 Delete records from tKamain              
			DELETE FROM @tKamain                                  
		  END                                     
                                  
		  IF(EXISTS(SELECT 1 FROM INVT_RES WHERE WONO=@wono))                                     
		  BEGIN                                
			EXEC [CloseAllComponantsOfOldNdReservtion4New] @wono,@newUniqKey,@newWono,@userId                                
		  END                                                                                                     
	 END                                                  
	 DELETE FROM @WONOs where wono=@wono                                                 
 END                                                
COMMIT TRANSACTION                               
END TRY                                                               
BEGIN CATCH                                                                                          
 IF @@TRANCOUNT > 0                         
 ROLLBACK                                                              
     SELECT @ErrorMessage = ERROR_MESSAGE(),                                                                
        @ErrorSeverity = ERROR_SEVERITY(),                                                                
        @ErrorState = ERROR_STATE();                                                                
  RAISERROR (@ErrorMessage,                                                                
              @ErrorSeverity,                                                               
               @ErrorState                                                               
               );                                      
END CATCH                                                                
END 