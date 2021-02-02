-- =============================================                  
-- Author:  Satish B                  
-- Create date: 6/26/2018                  
-- DescriptiON: Save modIFied import details INTo PO tables                  
--Modified Satish B: 05/15/2019 add parameter @isUploaded BIT OUTPUT and take it as output                  
--Modified Satish B: 05/16/2019 change to update inventor detail                  
--Modified Satish B: 05/17/2019 select top 1 uniqwh and uniqlnno                   
--Modified Vijay G : 06/02/2019 return @ERRORMESSAGE as message to user             
--Modified Vijay G : 07/12/2019 Get settingvalue conditionally for both setting (Auto PO Nubering) and (Auto Approve)          
--Modified Vijay G : 07/12/2019 Updating wmsettingmanagement set lastPonumber if setting is auto po numbering         
--Modified Vijay G : 07/15/2019 Remove (@newAutoNum varchar(15)) and replaced @newAutoNum with @pNum where it was used         
--Modified Vijay G : 07/15/2019 Set @pNum by appending 'T' to @autonum            
--Modified Vijay G : 07/18/2019 if Clink and Rlink is empty take from shipbill for corresponding supplier          
--Modified Vijay G : 07/26/2019 Remove Unwanted conversion code       
--Modified Shiv P : 09/09/2019 Put the entry of UniqMfgrHd in Poitems when uploading PO and also put empty value for part_no and Description when POITYPE is Invt Part          
--Modified Shiv P : 10/09/2019 To append the zeros before itemno in PoItems      
--Modified Nitesh B : 09/10/2019 Added SP call for PO Receiving for service item on approval      
--Modified Shiv P : 10/18/2019 To update the inventor table's stdcost      
--Modified Nitesh B : 11/15/2019 Added Case for MRO and Services item to insert empty in UNIQ_KEY and UNIQMFGRHD       
--Modified Shiv P : 22/11/2019  To update the S_ORD_QTY       
--Modified Shiv P : 27/11/2019  To change the selection of @importId      
--Modified Shiv P : 04/12/2019 To creating problem for importing because field length       
--Modified Shiv p 12/16/2019 : Inserted Empty UNIQ_WH for MRO parts      
--Modified Shiv p 01/23/2020 : Fixed the issue of on the basis of supplier C_Link and R_Link not exists in system    
--Modified Rajendra k 08/20/2020 : Get the "defaultOverage" setting and insert into POITEMS.Overage column   
--Modified Rajendra k 11/25/2020 : Added condition if S_ORD_QTY is zero
--- =============================================          
      
CREATE PROCEDURE [dbo].[ImportPOFullComplete]                   
 -- Add the parameters for the stored procedure here                  
 --DECLARE                  
 @importId UNIQUEIDENTIFIER=null,                  
 @userId UNIQUEIDENTIFIER=null,                  
 @moduleId CHAR(10)=null,                  
 @isUpdateStdCost BIT,             
 @isUploaded BIT OUTPUT                  
AS                  
BEGIN                  
 -- SET NOCOUNT ON added to prevent extra result SETs FROM                  
 -- INTerfering with SELECT statements.                  
 SET NOCOUNT ON;                  
 BEGIN TRANSACTION                  
 --BEGIN TRANSACTION                  
                   
    /* Get user initials for the header */           
 --Modified Vijay G : 07/15/2019 Remove (@newAutoNum varchar(15)) and replaced @newAutoNum with @pNum where it was used                
    DECLARE @userInit VARCHAR(5),@autoNum varchar(15),@itemNote varchar(MAX),@count int                      
    SELECT @userInit = COALESCE(Initials,'') FROM aspnet_Profile WHERE userId = @userId                  
                      
 DECLARE @ERRORNUMBER INT= 0                  
   ,@ERRORSEVERITY INT=0                  
   ,@ERRORPROCEDURE VARCHAR(MAX)=''                  
   ,@ERRORLINE INT =0                  
   ,@ERRORMESSAGE VARCHAR(MAX)=''                  
   ,@NewPONum varchar(15),@pNum varchar(15)                   
                  
 DECLARE  @pONum VARCHAR(15)                  
   ,@poStatus CHAR(10)                   
   ,@poSupplier CHAR(35)                  
   ,@poBuyer CHAR(256)                  
   ,@poPriprity CHAR(45)                  
   ,@poDate VARCHAR(MAX)                  
   ,@poCONfTo CHAR(8)                  
   ,@poTerms CHAR(15)                  
   ,@lfreightInclude BIT                  
   ,@pONote VARCHAR(MAX)                  
   ,@shipChgAMT numeric(20)                
   ,@is_ScTAx BIT                
   ,@sc_TaxPct numeric(20)                  
   ,@shipCharge VARCHAR(20)                  
   ,@shipVia VARCHAR(20)                    
   ,@fob VARCHAR(20)                    
   ,@cLink VARCHAR(10)                  
   ,@rLink VARCHAR(10)                  
   ,@iLink VARCHAR(10)                  
   ,@bLink VARCHAR(10)                  
                           
 SELECT @pONum= rtrim(p.PONumber),                   
     @poStatus=rtrim(p.Status),                  
     @poSupplier =rtrim(p.Supplier),                  
     @poBuyer =rtrim(p.Buyer) ,                  
     @poPriprity=rtrim(p.Priority)  ,                  
     @poDate =rtrim(p.PODate) ,                  
     @poCONfTo =rtrim(p.CONfTo),                  
     @lfreightInclude =rtrim(p.LfreightInclude),                  
     @pONote =rtrim(p.PONote),                  
     @shipChgAMT =rtrim(p.ShipChgAMT),                  
     @is_ScTAx =rtrim(p.Is_ScTAx),                  
     @sc_TaxPct=rtrim(p.Sc_TaxPct),                  
     @shipCharge =rtrim(p.ShipCharge),                  
     @shipVia =rtrim(p.ShipVia),                  
     @fob =rtrim(p.Fob),                  
     @cLink =rtrim(p.CLINK),                  
     @rLink =rtrim(p.RLINK),                  
     @iLink =rtrim(p.ILINK),                  
     @bLink =rtrim(p.BLINK),                  
     @poTerms=p.Terms                  
 FROM ImportPOMain p WHERE POImportId=@importId                  
          
      
 DECLARE @poDetails tPODetails                  
 DECLARE @poSchedule tPOSchedule                    
 DECLARE @poTax tPOTax                   
                     
 INSERT INTO @poDetails                  
 EXEC [dbo].[GetImportPOItems] @importId,@moduleId,null        
       
 INSERT INTO @poSchedule                  
 EXEC [dbo].[GetImportPOSchedule] @importId,@moduleId,null       
           
 INSERT INTO @poTax                  
 EXEC [dbo].[GetImportPOTax] @importId,@moduleId,null       
                  
 -- Vijay G :07/26/2019 Remove Unwanted conversion code       
 --SELECT @pNum = 'T' + CASE WHEN (PATINDEX('%[a-z]%' ,@pONum) > 0)                    
 --        OR (PATINDEX('%[-,~,@,#,$,%,&,*,(,),!,?,.,,,+,\,/,?,`,=,;,:,{,},^,_,|]%',@pONum) > 0)         
 --       THEN  RIGHT('000000000000000' + CONVERT(VARCHAR(15), RTRIM(@pONum)), 14) ELSE  REPLACE(STR(CAST(@pONum AS INT),14), SPACE(1), '0') END        
 SELECT @pNum = 'T' +RIGHT('000000000000000' + CONVERT(VARCHAR(15), RTRIM(@pONum)), 14)        
              
 SET @NewPONum=(SELECT REPLACE(LEFT(Rtrim(@pNum),1),'T','0'))+ RIGHT(RTRIM(@pNum),Len(Rtrim(@pNum))-1)                  
           
 DECLARE @isAutoApproveSetting BIT,@isAutoPONumbering BIT,@noWFSetup BIT                  
 --Modified Vijay G : 07/12/2019 Get settingvalue conditionally for both setting (Auto PO Nubering) and (Auto Approve)              
 SELECT @isAutoApproveSetting =       
 CASE WHEN  w.settingId IS NULL THEN m.settingValue ELSE w.settingValue END FROM mnxSETtingsmanagement m                   
 LEFT JOIN wmSETtingsmanagement w ON m.SETtingid=w.SETtingid                   
 WHERE SETtingName LIKE'ApprovePOWhenImporting%'            
            
 SELECT @isAutoPONumbering = CASE WHEN  w.settingId IS NULL THEN m.settingValue ELSE w.settingValue END FROM mnxSETtingsmanagement m                   
  LEFT JOIN wmSETtingsmanagement w ON m.SETtingid=w.SETtingid                   
 WHERE  SETtingName ='AutoManualPO'                  
 EXEC [GetNextPONumber] @pcNextNumber = @autoNum OUTPUT            
      
 --Modified Vijay G : 07/12/2019 Updating wmsettingmanagement set lastPonumber if setting is auto po numbering            
 IF(@isAutoPONumbering=1)              
 BEGIN           
  --Modified Vijay G : 07/15/2019 Set @pNum by appending 'T' to @autonum            
  SET @pNum = (SELECT REPLACE(LEFT(@autoNum,1),'0','T')+RIGHT(@autoNum,Len(@autoNum)-1))          
  --SET @pNum = @autoNum               
  UPDATE w SET w.settingValue= @autoNum FROM wmsettingsmanagement w  join MnxSettingsManagement m                 
  ON w.settingId = m.settingId   WHERE m.settingName='LastPONumber'                
 END              
    --SET @pNum=CASE WHEN @isAutoPONumbering=1 THEN @autoNum ELSE @pNum END      
       
 IF NOT EXISTS(SELECT PONUM FROM POMAIN WHERE PONUM = @pNum)                  
 BEGIN                  
  BEGIN TRY                  
   INSERT INTO [dbo].[POMAIN] (      
    [PONUM]                  
   ,[PODATE]                  
   ,[VERDATE]                  
   ,[POSTATUS]                  
   ,[CONUM]                  
   ,[BUYER]                  
   ,[POTAX]              
   ,[POTOTAL]                  
   ,[TERMS]                  
   ,[PONOTE]          
   ,[IS_PRINTED]                  
   ,[C_LINK]                  
   ,[R_LINK]                  
   ,[I_LINK]                  
   ,[B_LINK]                  
   ,[SHIPCHG]                  
   ,[IS_SCTAX]                  
   ,[SCTAXPCT]                  
   ,[CONFNAME]                  
  ,[CONFIRMBY]                  
   ,[SHIPCHARGE]                
   ,[FOB]                  
   ,[SHIPVIA]                  
   ,[POPRIORITY]          
   ,[UNIQSUPNO]                  
   ,[LFREIGHTINCLUDE]                  
   ,[POUNIQUE]                  
   ,[aspnetBuyer]                  
   ,[FcUsed_uniq]                  
   ,[Fchist_key]                  
   ,[POTAXFC]                  
   ,[pototalFC]                  
   ,[SHIPCHGFC]                  
   ,[isNew]                  
   ,[prFcUsed_uniq]                  
   ,[funcFcUsed_uniq]                  
   ,[PoTaxPR]                  
   ,[POTOTALPR]                  
   ,[SHIPCHGPR]                  
   )                  
        
  VALUES (@pNum,CONVERT(VARCHAR,@poDate, 23),CONVERT(VARCHAR,@poDate, 23),@poStatus,0,''                  
   ,((@shipChgAMT * @sc_TaxPct) / 100)                  
   ,(@shipChgAMT + (Select Sum(ORD_QTY * COSTEACH ) from @poDetails WHERE ImportId =@importId)) --Modified Shiv P : 27/11/2019  To change the selection of @importId       
   ,@poTerms,@pONote,0                  
    --SET default address and address details                  
  --Modified Vijay G : 07/18/2019 if Clink and Rlink is empty take from shipbill for corresponding supplier       
  --Modified Shiv p 01/23/2020 : Fixed the issue of on the basis of supplier C_Link and R_Link not ex    
    ,CASE WHEN @cLink IS NULL THEN COALESCE((SELECT TOP 1 ISNULL(LinkAdd,'') FROM SHIPBILL WHERE RECORDTYPE='C'         
       AND CUSTNO=(SELECT TOP 1 SUPID FROM SUPINFO WHERE SUPNAME=@poSupplier)),'') ELSE @cLink END                  
   ,CASE WHEN @rLink IS NULL THEN COALESCE((SELECT TOP 1 ISNULL(LinkAdd,'') FROM SHIPBILL WHERE RECORDTYPE='R'        
   AND CUSTNO=(SELECT TOP 1 SUPID FROM SUPINFO WHERE SUPNAME=@poSupplier)),'') ELSE @rLink END                   
   ,CASE WHEN @iLink IS NULL THEN (SELECT TOP 1 LinkAdd FROM SHIPBILL WHERE RECORDTYPE='I' AND CUSTNO='') ELSE @iLink END                    
   ,CASE WHEN @bLink IS NULL THEN (SELECT TOP 1 LinkAdd FROM SHIPBILL WHERE RECORDTYPE='P' AND CUSTNO='') ELSE @bLink END                    
   ,@shipChgAMT,@is_ScTAx ,@sc_TaxPct,@poCONfTo,''                  
   ,CASE WHEN @shipCharge IS NULL THEN (SELECT TOP 1 SHIPCHARGE FROM SHIPBILL WHERE RECORDTYPE='R') ELSE @shipCharge END                  
  ,CASE WHEN @fob IS NULL THEN (SELECT TOP 1 FOB FROM SHIPBILL WHERE RECORDTYPE='R') ELSE @fob END                  
   ,CASE WHEN @shipVia IS NULL THEN (SELECT TOP 1 SHIPVIA FROM SHIPBILL WHERE RECORDTYPE='R') ELSE @shipVia END                  
   ,@poPriprity                  
   ,ISNULL((SELECT TOP 1 UNIQSUPNO FROM SUPINFO WHERE SUPNAME =(SELECT TOP 1 SUPNAME FROM SUPINFO WHERE SUPNAME=@poSupplier)),'')                  
   ,@lfreightInclude,dbo.fn_GenerateUniqueNumber()                  
   ,(select UserId from aspnet_users where Username=@poBuyer),'','',0,0,0,0,'','',0,0,0)               
  END TRY                  
  BEGIN CATCH                   
   SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                  
   ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                  
   ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                  
   ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                  
   ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                  
         
   ROLLBACK TRANSACTION                 
   --VijayG: 06/02/2019 return @ERRORMESSAGE as message to user                
   --RETURN -1                   
   RETURN @ERRORMESSAGE                  
  END CATCH           
        
  --Insert INTo POITEMS                  
  DECLARE @itemNoteID UNIQUEIDENTIFIER=null,@itemCount INT=0,@uniqlnno varchar(10),@rowID UNIQUEIDENTIFIER=null                  
       
  BEGIN TRY               
 DECLARE @overageSettingValue NUMERIC(5,2);--Modified Rajendra k 08/20/2020 : Get the "defaultOverage" setting and insert into POITEMS.Overage column   
   SELECT @overageSettingValue = CAST(CASE WHEN ISNULL(WM.SettingValue,'') = '' THEN MS.settingValue ELSE WM.SettingValue END AS NUMERIC(5,2))   
 FROM MnxSettingsManagement MS LEFT JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId   
 WHERE SettingName = 'defaultOverage'  
   INSERT INTO [dbo].[POITEMS]                  
   ([PONUM]                  
   ,[UNIQLNNO]                  
   ,[UNIQ_KEY]                  
   ,[ITEMNO]                  
   ,[COSTEACH]                  
   ,[ORD_QTY]                  
   ,[NOTE1]                  
   ,[POITTYPE]                  
   ,[PART_NO]                  
   ,[REVISION]                  
   ,[DESCRIPT]                  
   ,[PARTMFGR]                  
   ,[MFGR_PT_NO]                  
   ,[PART_CLASS]                  
   ,[PART_TYPE]             
   ,[U_OF_MEAS]                  
   ,[PUR_UOFM]                  
   ,[S_ORD_QTY]                  
   ,[ISFIRM]                  
   ,[UNIQMFGRHD]                  
   ,[FIRSTARTICLE]                  
   ,[INSPEXCEPT]                  
   ,[INSPEXCEPTION]                  
   ,[costEachFC]                  
   ,[costEachPR]  
   ,[OVERAGE])   --Modified Rajendra k 08/20/2020 : Get the "defaultOverage" setting and insert into POITEMS.Overage column   
           
  SELECT @pNum,      
    dbo.fn_GenerateUniqueNumber(),      
    --Modified Nitesh B : 11/15/2019 Added Case for MRO and Services item to insert empty in UNIQ_KEY and UNIQMFGRHD      
    CASE WHEN  t.PoItType ='Invt Part' THEN (SELECT UNIQ_KEY FROM INVENTOR WHERE PART_NO=t.PartNo AND REVISION=CONVERT(VARCHAR(4),      
    t.RevisiON) AND Status='Active' AND Part_Sourc IN('Buy','MAKE')) ELSE '' END,       
    RIGHT('000'+ CONVERT(VARCHAR,RTRIM(LTRIM( t.ITEMNO))),3),      
    t.COSTEACH,      
    t.ORD_QTY,      
    ISNULL(t.ITEMNOTE,''),      
    t.PoItType,                   
    --Modified Shiv P : 09/09/2019 Put the entry of UniqMfgrHd in Poitems when uploading PO and also put empty value for part_no and Description when POITYPE is Invt Part        
    CASE WHEN  t.PoItType ='Invt Part' THEN '' ELSE t.PartNo END,       
    CONVERT(VARCHAR(4),      
    t.RevisiON),      
    CASE WHEN  t.PoItType ='Invt Part' THEN '' ELSE ISNULL(t.Descript,'') END,      
    t.PARTMFGR,      
    t.MFGR_PT_NO,      
    '',      
    '',      
   --t.PUR_UOFM      
   CASE WHEN  t.PoItType ='Invt Part' THEN (SELECT TOP 1 U_OF_MEAS FROM INVENTOR WHERE PART_NO=t.PartNo AND       
      REVISION=CONVERT(VARCHAR(4), t.RevisiON) AND Status='Active' AND Part_Sourc IN('Buy','MAKE')) ELSE t.PUR_UOFM END,      
      
      CASE WHEN  t.PoItType ='Invt Part' THEN (SELECT TOP 1 PUR_UOFM FROM INVENTOR WHERE PART_NO=t.PartNo AND       
      REVISION=CONVERT(VARCHAR(4), t.RevisiON) AND Status='Active' AND Part_Sourc IN('Buy','MAKE')) ELSE t.PUR_UOFM END      
      
   ,      --Modified Rajendra k 11/25/2020 : Added condition if S_ORD_QTY is zero
   CASE WHEN t.S_ORD_QTY = 0 THEN t.ORD_QTY ELSE t.S_ORD_QTY END, --Modified Shiv P : 22/11/2019  To update the S_ORD_QTY       
   t.IsFirm      
   --Modified Nitesh B : 11/15/2019 Added Case for MRO and Services item to insert empty in UNIQ_KEY and UNIQMFGRHD      
   , CASE WHEN  t.PoItType ='Invt Part' THEN  (select i.uniqmfgrhd from MfgrMaster m join InvtMPNLink i on m.mfgrmasterid=i.mfgrmasterid       
      where m.partmfgr=t.PARTMFGR and m.mfgr_pt_no=t.MFGR_PT_NO and       
      uniq_key=(SELECT TOP 1 UNIQ_KEY FROM INVENTOR WHERE PART_NO=t.PartNo AND       
      REVISION=CONVERT(VARCHAR(4), t.RevisiON) AND Status='Active' AND Part_Sourc IN('Buy','MAKE'))) ELSE '' END      
   ,t.FirstArticle      
   ,t.InspExcept                    
   ,ISNULL(t.INSPEXCEPTION,'')      
   ,t.CostEachFc,0                  
   ,@overageSettingValue  --Modified Rajendra k 08/20/2020 : Get the "defaultOverage" setting and insert into POITEMS.Overage column   
   FROM @poDetails t         
    SET @itemCount=@@ROWCOUNT       
  END TRY                  
  BEGIN CATCH                   
   SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                  
   ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                  
   ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                  
   ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                  
   ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                  
         
   ROLLBACK TRANSACTION                  
   --VijayG: 06/02/2019 return @ERRORMESSAGE messages                
   --RETURN -1                    
   RETURN @ERRORMESSAGE                  
  END CATCH                  
              
  BEGIN TRY                  
   --Modified Shiv P : 10/18/2019 To update the inventor table's stdcost      
   DECLARE @poUnreconciledTbl TABLE(Receiverno VARCHAR(10),Uniqlnno VARCHAR(10),Ponum VARCHAR(10),Loc_uniq VARCHAR(10))      
   DECLARE @PoNotTransfTbl TABLE(Sinv_uniq VARCHAR(10))      
   DECLARE @allUniqKeys TABLE(Uniq_Key VARCHAR(10),Matl_Cost numeric(13,5))      
   DECLARE @tempUniqKey VARCHAR(10),@Matl_Cost NUMERIC(13,5)      
         
   IF @isUpdateStdCost = 1      
   BEGIN       
    INSERT INTO @allUniqKeys(Uniq_Key,Matl_Cost)      
    SELECT i.UNIQ_KEY,t.COSTEACH FROM INVENTOR i       
    JOIN @poDetails t on  i.PART_NO=t.PartNo       
    JOIN INVTMFGR im on im.UNIQ_KEY= i.UNIQ_KEY       
    WHERE i.REVISION=CONVERT(VARCHAR(4), t.RevisiON)  AND  i.Part_Sourc <>'CONSG' AND i.MATL_COST=0 AND im.QTY_OH = 0      
         
    DECLARE @rowCount INT      
    SELECT @rowCount = COUNT(Uniq_Key) FROM @allUniqKeys      
    WHILE(@rowCount > 0)      
    BEGIN      
     SELECT TOP 1 @tempUniqKey= Uniq_Key,@Matl_Cost=Matl_Cost FROM @allUniqKeys      
      
     INSERT INTO @poUnreconciledTbl      
     EXEC [dbo].[PoUnreconciled4Uniq_keyView] @tempUniqKey      
          
     INSERT INTO @PoNotTransfTbl      
     EXEC [dbo].[PoNotTransf2AP4PartView] @tempUniqKey       
      
     IF NOT EXISTS((select 1 from @poUnreconciledTbl)) and (NOT EXISTS(select 1 from @PoNotTransfTbl))      
     BEGIN      
      UPDATE INVENTOR SET STDCOST =@Matl_Cost where UNIQ_KEY=@tempUniqKey      
      DELETE FROM @allUniqKeys WHERE Uniq_Key=@tempUniqKey      
      set @rowCount =@rowCount - 1      
     END      
    END      
   END       
            
   UPDATE i                  
     --Satish B: 05/16/2019 change to update inventor detail                  
   SET i.MINORD=ISNULL(t.MINORD,0),                  
      ORDMULT=ISNULL(t.ORDMULT,0),                  
      PUR_LTIME=ISNULL(t.PUR_LTIME,0),                  
      PUR_LUNIT=ISNULL(t.PUR_LUNIT,'')                  
   FROM INVENTOR i JOIN @poDetails t ON       
   i.UNIQ_KEY= (SELECT UNIQ_KEY FROM INVENTOR WHERE PART_NO=t.PartNo AND REVISION=CONVERT(VARCHAR(4), t.RevisiON) AND Part_Sourc <>'CONSG')        
  END TRY                  
  BEGIN CATCH                   
   SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                  
   ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                  
   ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                  
   ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                  
   ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')               
                  
   ROLLBACK TRANSACTION                  
   --VijayG: 06/02/2019 return @ERRORMESSAGE as message to user                 
   --RETURN -1                   
   RETURN @ERRORMESSAGE                  
  END CATCH                  
                   
  BEGIN TRY                  
   INSERT INTO [dbo].[POITSCHD]                  
    ([UNIQLNNO]                  
    ,[UNIQDETNO]                  
    ,[SCHD_DATE]                  
    ,[SCHD_QTY]                  
    ,[BALANCE]            
    ,[REQUESTTP]                  
    ,[REQUESTOR]                  
    ,[UNIQWH]                  
    ,[LOCATION]                  
    ,[WOPRJNUMBER]                  
    ,[PONUM]                  
    ,[GL_NBR]                  
    ,[ORIGCOMMITDT])                  
   -- Satish B: 05/17/2019 select top 1 uniqwh and uniqlnno            
   --Modified Shiv P : 10/09/2019 To append the zeros before itemno in PoItems             
   SELECT (SELECT TOP 1 UNIQLNNO FROM POITEMS WHERE PONUM=@pNum AND       
    ITEMNO =  RIGHT('000'+ CONVERT(VARCHAR,RTRIM(LTRIM( p.ITEMNO))),3)) ,      
    dbo.fn_GenerateUniqueNumber(),s.SCHDDATE,CONVERT(VARCHAR,s.SCHDQTY, 23) ,      
    CONVERT(VARCHAR,s.SCHDQTY, 23),s.REQUESTTP,s.REQUESTOR,                  
    --Modified Shiv p 12/16/2019 : Inserted Empty UNIQ_WH for MRO parts      
    ISNULL((SELECT TOP 1 w.UNIQWH FROM WAREHOUS w WHERE w.WAREHOUSE=s.WAREHOUSE),''),s.LOCATION,s.                  
    WOPRJNUMBER,@pNum,ISNULL(SUBSTRING(s.GLNBR,1,13),'')--Modified Shiv P : 04/12/2019 To creating problem for importing because field length       
    ,s.ORIGCOMMITDT                  
   FROM @poSchedule s                  
   INNER JOIN @poDetails p ON s.fkRowId=p.RowId                  
         
   SELECT UNIQLNNO INTO #Temp FROM POITEMS where PONUM=@pNum                  
         
   WHILE (Select Count(*) From #Temp) > 0                  
   BEGIN                   
    SET @itemNoteID=NEWID()                  
    SET @rowID= (SELECT TOP 1 RowId FROM @poDetails)                  
    SET @uniqlnno = (SELECT TOP 1 UNIQLNNO FROM #Temp)                  
    SET @itemNote = (SELECT ITEMNOTE FROM @poDetails where RowId = @rowID)                  
          
    IF(@itemNote != '' OR @itemNote != NULL)                  
    BEGIN                  
     INSERT INTO wmNotes(NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)                  
     VALUES (@itemNoteID,2,@uniqlnno,'POItemNote','Note',@userId)                  
          
     INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                  
     VALUES(@itemNoteID,(SELECT ITEMNOTE FROM @poDetails where RowId = @rowID),@userId)              
    END                  
         
    DELETE FROM #Temp WHERE UNIQLNNO = @uniqlnno                  
    DELETE FROM @poDetails where RowId = @rowID                  
   END                   
  END TRY                  
  BEGIN CATCH                   
   SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                
     ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                  
     ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                  
     ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                  
     ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                  
                     
   ROLLBACK TRANSACTION                   
   --VijayG: 06/02/2019 return @ERRORMESSAGE as message to user                
   --RETURN -1                   
   RETURN @ERRORMESSAGE                  
  END CATCH                  
      
  --Insert INTo POITEMSTAX                  
  BEGIN TRY                  
   INSERT INTO [dbo].[POITEMSTAX]                  
   ([UNIQPOITEMSTAX]            
   ,[PONUM]                  
   ,[UNIQLNNO]                  
   ,[TAX_ID]                  
   ,[TAX_RATE])                  
   SELECT dbo.fn_GenerateUniqueNumber(),@pNum,      
    (SELECT UNIQLNNO FROM POITEMS WHERE PONUM=@pNum AND ITEMNO =  RIGHT('000'+ CONVERT(VARCHAR,RTRIM(LTRIM( p.ITEMNO))),3)),      
    tx.TAXID ,tx.TaxRate                  
FROM @poTax tx                  
   INNER JOIN @poDetails p ON p.RowId=tx.fkRowId                  
  END TRY                  
  BEGIN CATCH                   
   SELECT  @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)                  
     ,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)                  
     ,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')                  
     ,@ERRORLINE = ISNULL(ERROR_LINE(),0)                  
     ,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')                  
                      
   ROLLBACK TRANSACTION                  
   --VijayG: 06/02/2019 return @ERRORMESSAGE as message to user                
   --RETURN -1                  
   RETURN @ERRORMESSAGE                   
  END CATCH                  
         
  -- auto ponumbering then genrate                   
  DECLARE @poNoteID uniqueidentifier = NEWID()                  
  IF(@isAutoPONumbering = 1)                  
  BEGIN                  
   IF(@isAutoApproveSetting = 1)                  
   BEGIN                  
    UPDATE POMAIN SET PONUM= @autoNum, POSTATUS = 'OPEN',IsApproveProcess = 1 WHERE PONUM=@pNum        
       
    --Modified Nitesh B : 09/10/2019 Added SP call for PO Receiving for service item on approval        
    SELECT @count = COUNT(1) FROM POITEMS WHERE PONUM = @autoNum  AND POITTYPE ='Services'        
    if(@count>0)         
    BEGIN                   
     EXEC [dbo].[POServiceItemReceive] @autoNum, @userId;        
    END      
                 
    IF(RTRIM(@pONote) !='' OR @pONote != NULL)                  
    BEGIN                  
     INSERT INTO wmNotes(NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)                   
     VALUES(@poNoteID,2,@autoNum,'PONote','Note',@userId)          
           
     INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                  
     VALUES (@poNoteID,@pONote,@userId)                  
    END                  
   END                  
   ELSE                  
   BEGIN                  
    --SET @newAutoNum=(SELECT REPLACE(LEFT(@autoNum,1),'0','T')+RIGHT(@autoNum,Len(@autoNum)-1))                  
    UPDATE POMAIN SET  IsApproveProcess=1 WHERE PONUM=@pNum                  
    --EXEC [dbo].[ProcessApprovePO] @newAutoNum,@userId,@noSetup= @noWFSetup OUTPUT              
    EXEC [dbo].[ProcessApprovePO] @pNum,@userId,@noSetup= @noWFSetup OUTPUT                 
    IF(@noWFSetup=1)                  
    BEGIN                   
       UPDATE POMAIN SET POSTATUS = 'OPEN',PONUM = @autoNum ,IsApproveProcess = 1 WHERE PONUM = @pNum;                    
             
       --Modified Nitesh B : 09/10/2019 Added SP call for PO Receiving for service item on approval        
       SELECT @count = Count(1) FROM POITEMS WHERE PONUM = @autoNum  AND POITTYPE ='Services'        
       if(@count>0)         
       BEGIN                   
        EXEC [dbo].[POServiceItemReceive] @autoNum, @userId;        
       END      
           
     IF(rtrim(@pONote)!='' OR @pONote != NULL)                  
     BEGIN                  
      insert into wmNotes(NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)                   
      values(@poNoteID,2,@autoNum,'PONote','Note',@userId)                  
          
      INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                  
      VALUES (@poNoteID,@pONote,@userId)                  
     END                  
    END                   
    ELSE                  
    BEGIN                  
      IF(rtrim(@pONote)!= '' OR @pONote != NULL)                  
      BEGIN                           
      INSERT INTO wmNotes(NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)                   
      VALUES(@poNoteID,2,@pNum,'PONote','Note',@userId)                  
            
      INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                  
      VALUES (@poNoteID,@pONote,@userId)                  
      END                  
    END        
   END                  
  END               
              
  IF(@isAutoApproveSetting=1 AND @isAutoPONumbering=0)                  
  BEGIN                
   UPDATE POMAIN SET POSTATUS = 'OPEN',PONUM = @NewPONum ,IsApproveProcess = 1 WHERE PONUM = @pNum                  
              
   --Modified Nitesh B : 09/10/2019 Added SP call for PO Receiving for service item on approval      
   SELECT @count = Count(1) FROM POITEMS WHERE PONUM = @NewPONum  AND POITTYPE ='Services'        
   if(@count>0)         
   BEGIN                
    EXEC [dbo].[POServiceItemReceive] @NewPONum, @userId;        
   END      
             
   if(rtrim(@pONote)!='' OR @pONote != NULL)                  
   BEGIN                  
    SELECT @pONote                  
    INSERT INTO wmNotes(NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)                   
    VALUES(@poNoteID,2,@NewPONum,'PONote','Note',@userId)                  
          
    INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                  
    VALUES (@poNoteID,@pONote,@userId)                  
   END                  
  END                  
  ELSE IF(@isAutoApproveSetting=0 AND @isAutoPONumbering=0)                  
  BEGIN                  
   UPDATE POMAIN SET IsApproveProcess = 1 WHERE PONUM = @pNum                  
   EXEC [dbo].[ProcessApprovePO] @pNum,@userId,@noSetup= @noWFSetup OUTPUT                  
         
   IF(@noWFSetup=1)                  
   BEGIN           
    UPDATE POMAIN SET POSTATUS = 'OPEN',PONUM = @NewPONum ,IsApproveProcess = 1 WHERE PONUM = @pNum                  
          
    --Modified Nitesh B : 09/10/2019 Added SP call for PO Receiving for service item on approval      
    SELECT @count = Count(1) FROM POITEMS WHERE PONUM = @NewPONum  AND POITTYPE ='Services'        
    if(@count>0)         
    BEGIN           
      EXEC [dbo].[POServiceItemReceive] @NewPONum, @userId;        
    END      
          
    if(rtrim(@pONote)!='' OR @pONote!=NULL)                  
    BEGIN                  
     SELECT @pONote                  
     INSERT INTO wmNotes(NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)                   
     VALUES(@poNoteID,2,@NewPONum,'PONote','Note',@userId)                  
     INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                  
     VALUES (@poNoteID,@pONote,@userId)                  
    END                  
   END                   
   ELSE                  
   BEGIN           
    IF(rtrim(@pONote)!='' OR @pONote != NULL)                  
    BEGIN                  
     SELECT @pONote                  
     INSERT INTO wmNotes(NoteID,NoteCategory,RecordId,RecordType,NoteType,fkCreatedUserID)               
     VALUES(@poNoteID,2,@pNum,'PONote','Note',@userId)                  
           
     INSERT INTO WMNOTERELATIONSHIP(FkNoteId,Note,CreatedUserId)                  
     VALUES (@poNoteID,@pONote,@userId)                  
    END                  
   END                   
  END                   
                
  DELETE FROM ImportPODetails WHERE fkPOImportId=@importId              
  DELETE FROM ImportPoSchedule WHERE fkPOImportId=@importId                
  DELETE FROM ImportPOTax WHERE fkPOImportId=@importId                
  DELETE FROM ImportPOMain WHERE POImportId=@importId                  
                  
  --Rollback TRANSACTION                 
  SET @isUploaded=1                  
  IF @@TRANCOUNT>0                  
   COMMIT TRANSACTION       
 END                  
 ELSE                
 BEGIN                  
     SET @isUploaded=0           
  Rollback TRANSACTION             
 END                  
END                  
      