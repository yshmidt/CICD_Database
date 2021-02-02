-- ============================================================================================================      
-- Date   : 10/01/2019      
-- Author  : Mahesh B      
-- Description : Used for get Sales Order import error data for excel      
-- InsertAllRecords '3046F0C8-113E-43EF-8D2B-6DEADE385D0C' , '49F80792-E15E-4B62-B720-21B360E3108A'
-- ============================================================================================================      
      
CREATE PROC InsertAllRecords  
 @ImportId UNIQUEIDENTIFIER,
 @UserId   UNIQUEIDENTIFIER
AS      
BEGIN      
       
SET NOCOUNT ON       
       
DECLARE @ModuleId INT,@partClassFieldDefid UNIQUEIDENTIFIER,@partTypeFieldDefid UNIQUEIDENTIFIER,@SOMainFieldName  NVARCHAR(MAX), @SOdetailFieldName NVARCHAR(MAX), @SOPriceFieldName NVARCHAR(MAX),  
		@SODuedtFieldName NVARCHAR(MAX), @SQL NVARCHAR(MAX),@autoSONO BIT,@lastSONO CHAR(10),@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT,@ErrorState INT 
  
SELECT @ModuleId = ModuleId from mnxmodule where ModuleName='Sales' AND FilePath = 'salesPrice' AND Abbreviation='PL'  
  
DECLARE @SODetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,SOMainRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),  
        Attention_Name VARCHAR(200), FirstName VARCHAR(100), LastName VARCHAR(100),Line_No VARCHAR(100),Location VARCHAR(100)  
        , MFGR_Part_No VARCHAR(100),Part_MFGR VARCHAR(100), Part_No VARCHAR(100), Revision VARCHAR(100), Sodet_Desc VARCHAR(100),  Warehouse VARCHAR(100))  
  
DECLARE @SOMain TABLE  (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),Buyer VARCHAR(200),CustNo VARCHAR(100),OrderDate VARCHAR(100),PONO VARCHAR(100),SONO  VARCHAR(100),SONOTE VARCHAR(100))     
  
DECLARE @SOPrice TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),Price VARCHAR(100),Qty VARCHAR(100),SaleTypeId VARCHAR(100),Taxable VARCHAR(10))  
  
DECLARE @SODueDts TABLE(importId UNIQUEIDENTIFIER,FKSODetailRowId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),Commit_Dts VARCHAR(200),Due_Dts VARCHAR(100),Ship_Dts VARCHAR(100))  
    
DECLARE @SOPricesInsert TABLE (PLPRICELNK VARCHAR(100),SONO VARCHAR(100),PRICE DECIMAL(14,5),QUANTITY DECIMAL(13,2),TAXABLE BIT,COG_GL_NBR VARCHAR(100),PL_GL_NBR VARCHAR(100),RECORDTYPE CHAR(1),EXTENDED NUMERIC(14,2)
						,UNIQUELN VARCHAR(100),FLAT BIT, SaleTypeId VARCHAR(100),[Description] VARCHAR(100),RowId UNIQUEIDENTIFIER)  
  
DECLARE @SOMainvaliddata TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CustNo VARCHAR(100),BUYER VARCHAR(100),SONO VARCHAR(100), OrderDate VARCHAR(100))   
  
DECLARE @SODetailvaliddata TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,SOMainRowId UNIQUEIDENTIFIER,SONO VARCHAR(100),Attention_Name VARCHAR(100),Part_No VARCHAR(100),Revision VARCHAR(100),Line_No VARCHAR(100),  
       Sodet_Desc VARCHAR(100),Part_MFGR VARCHAR(100), MFGR_Part_No VARCHAR(100),Warehouse  VARCHAR(100),Note VARCHAR(100), LOCATION VARCHAR(100)  
       , FirstName VARCHAR(100),LastName VARCHAR(100),UNIQ_KEY VARCHAR(100),U_OF_MEAS VARCHAR(100),W_KEY VARCHAR(100)  
       ,UNIQWH VARCHAR(100),[Description] VARCHAR(100), CID VARCHAR(50))   
  
DECLARE @SOPricevaliddata TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,SONO VARCHAR(100),Price DECIMAL(14,5),Qty DECIMAL(13,2), SaleTypeId VARCHAR(100), Taxable VARCHAR(100))  
DECLARE @SODueDtsvaliddata TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,SONO VARCHAR(100), COMMIT_DTS DATE, SHIP_DTS DATE, DUE_DTS DATE,Qty NUMERIC(14,2))  
  
DECLARE @SODetailInsert TABLE (SONO VARCHAR(100),UNIQUELN VARCHAR(100),Line_No VARCHAR(100),UNIQ_KEY VARCHAR(100),Sodet_Desc VARCHAR(100),NOTE VARCHAR(100),ORIGINUQLN VARCHAR(100)  
   ,[STATUS] VARCHAR(100),UOFMEAS VARCHAR(100),W_KEY VARCHAR(100),Ord_Qty NUMERIC(9,2),EACHQTY NUMERIC(9,2),Attention VARCHAR(100),BALANCE NUMERIC(9,2),EXTENDED NUMERIC(9,2),CNFGQTYPER NUMERIC(9,2)
   ,SlinkAdd VARCHAR(100),[Description] VARCHAR(100),Category VARCHAR(100),RowId UNIQUEIDENTIFIER)  
  
DECLARE @SODueDtsInsert TABLE (DUEDT_UNIQ VARCHAR(100),SONO VARCHAR(100), DUE_DTS DATE, SHIP_DTS DATE, COMMIT_DTS DATE,UNIQUELN VARCHAR(100),Qty NUMERIC(14,2),RowId UNIQUEIDENTIFIER)  
  
  
SELECT @SOMainFieldName = STUFF(      
      (      
   SELECT  ',[' +  F.FIELDNAME + ']' FROM     
   ImportFieldDefinitions F        
   WHERE ModuleId = @ModuleId  AND FieldName IN ('CustNo','Buyer','SONO','OrderDate','SONOTE','PONO')    
   ORDER BY F.FIELDNAME     
   FOR XML PATH('')      
      ),1,1,'')  
  
SELECT @SOdetailFieldName = STUFF(      
      (      
       SELECT  ',[' +  F.FIELDNAME + ']' FROM     
       ImportFieldDefinitions F        
       WHERE ModuleId = @ModuleId AND FieldName IN ('Attention_Name','Part_No','Revision','Line_No','Sodet_Desc','Part_MFGR','MFGR_Part_No','Warehouse','Location','FirstName','LastName')    
       ORDER BY F.FIELDNAME     
       FOR XML PATH('')      
      ),      
      1,1,'')       
  
SELECT @SOPriceFieldName = STUFF(      
      (      
   SELECT  ',[' +  F.FIELDNAME + ']' FROM     
   ImportFieldDefinitions F        
   WHERE ModuleId = @ModuleId AND FieldName IN ('Price','Qty','SaleTypeId','Taxable')  
   ORDER BY F.FIELDNAME     
   FOR XML PATH('')      
      ),      
      1,1,'')  
  
SELECT @SODuedtFieldName = STUFF(      
      (      
  SELECT  ',[' +  F.FIELDNAME + ']' FROM     
     ImportFieldDefinitions F        
     WHERE ModuleId = @ModuleId AND FieldName IN ('Commit_Dts','Ship_Dts','Due_Dts')  
     ORDER BY F.FIELDNAME     
     FOR XML PATH('') ),1,1,''  
  )  
  
  
---------------------------------SOMain Information ---------------------------------  
 SELECT @SQL = N'      
  SELECT PVT.*    
  FROM      
  (    
     SELECT so.fkImportId AS importId,so.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,so.adjusted   
  FROM ImportFieldDefinitions fd        
     INNER JOIN ImportSOMainFields so ON so.FKFieldDefId=fd.FieldDefId  
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId     
  INNER JOIN     
    (     
  SELECT fd.FkImportId,fd.RowId,MAX(fd.Status) as Class ,MIN(fd.Message) AS Validation    
  FROM ImportSOMainFields fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId   
   INNER JOIN ImportSOUploadHeader h ON h.ImportId=fd.FkImportId  
  WHERE  fd.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@SOMainFieldName,'[',''''),']','''')+')    
   GROUP BY fd.fkImportId,fd.RowId    
    ) Sub      
   ON so.fkImportid=Sub.FkImportId AND so.RowId=Sub.RowId     
    WHERE so.fkImportId = '''+ CAST(@importId AS CHAR(36))+'''       
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SOMainFieldName +')     
  ) AS PVT '    
  
--PRINT @SQL
 INSERT INTO @SOMain EXEC SP_EXECUTESQL @SQL  
 DELETE FROM @SOMain WHERE RowId IN (SELECT RowId FROM @SOMain WHERE CssClass ='i05red')  
  --select * from @SOMain
---------------------------------------SODetails Information ---------------------------------  
  
 SELECT @SQL = N'      
  SELECT PVT.*    
  FROM      
  (  SELECT so.fkImportId AS importId,ibf.RowId,ibf.SOMainRowId,sub.class AS CssClass,sub.Validation,fd.fieldName,ibf.Adjusted  
  FROM ImportFieldDefinitions fd        
     INNER JOIN ImportSODetailFields ibf ON fd.FieldDefId = ibf.FKFieldDefId   
  INNER JOIN ImportSOMainFields so ON so.RowId=ibf.SOMainRowId  
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId     
  INNER JOIN     
    (     
  SELECT so.fkImportId,so.RowId,MAX(fd.status) as Class ,MIN(fd.Message) AS Validation    
  FROM ImportSODetailFields fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId    
   INNER JOIN ImportSOMainFields so ON so.RowId=fd.SOMainRowId  
  WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@SOdetailFieldName,'[',''''),']','''')+')    
  GROUP BY so.fkImportId,so.RowId    
    ) Sub      
     ON so.fkImportid=Sub.FkImportId AND ibf.SOMainRowId=sub.RowId  
   WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''       
  ) st      
  PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SOdetailFieldName +')) AS PVT '    

   
 INSERT INTO @SODetail EXEC SP_EXECUTESQL @SQL    
 --Remove the rows from SOMain & SODetail from @SODetail which has errors  
 DELETE FROM @SOMain WHERE RowId IN (SELECT SOMainRowId FROM @SODetail WHERE CssClass ='i05red')  
 DELETE FROM @SODetail WHERE SOMainRowId NOT IN (SELECT RowId FROM @SOMain)  
  --select * from @SODetail
   
---------------------------------------SOPrice Information ---------------------------------  
  
 SELECT @SQL = N'      
  SELECT PVT.*    
   FROM      
  ( SELECT isom.fkImportId AS importId,idts.FKSODetailRowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,idts.adjusted   
 FROM ImportFieldDefinitions fd        
    INNER JOIN ImportSOPriceFields idts ON fd.FieldDefId = idts.FKFieldDefId   
 INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId  
 INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId  
 INNER JOIN     
    (     
  SELECT iso.fkImportId,fd.FKSODetailRowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation    
  FROM ImportSOPriceFields fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId   
   INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId  
   INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId    
  WHERE iso.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@SOPriceFieldName,'[',''''),']','''')+')    
   GROUP BY iso.fkImportId,fd.FKSODetailRowId  
    ) Sub      
   ON isom.fkImportid=Sub.FkImportId AND idts.FKSODetailRowId=Sub.FKSODetailRowId     
    WHERE isom.fkImportId = '''+ CAST(@importId AS CHAR(36))+'''       
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SOPriceFieldName +')     
  ) AS PVT '  
  
  --print @SQL
 INSERT INTO @SOPrice EXEC SP_EXECUTESQL @SQL       
 --Remove the rows from SOMain & SODetail from @SOPrice which has errors   
 DELETE FROM @SOMain WHERE RowId IN (SELECT SOMainRowId FROM @SODetail WHERE CssClass ='i05red')  
 DELETE FROM @SODetail WHERE RowId IN (SELECT RowId FROM @SOPrice WHERE CssClass ='i05red')  
 DELETE FROM @SOPrice  WHERE RowId NOT IN (SELECT RowId FROM @SODetail)   
  --select * from @SOPrice
    
---------------------------------------SODueDts Information ---------------------------------  
  
 SELECT @SQL = N'      
  SELECT PVT.*    
  FROM      
  ( SELECT isom.fkImportId AS importId,idts.FKSODetailRowId,idts.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,idts.adjusted   
 FROM ImportFieldDefinitions fd        
    INNER JOIN ImportSODueDtsFields idts ON fd.FieldDefId = idts.FKFieldDefId   
 INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId  
 INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId  
 INNER JOIN     
    (     
  SELECT iso.fkImportId,fd.FKSODetailRowId,fd.RowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation    
  FROM ImportSODueDtsFields fd    
   INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId   
   INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId  
   INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId  
  WHERE iso.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
   AND FieldName IN ('+REPLACE(REPLACE(@SODuedtFieldName,'[',''''),']','''')+')    
   GROUP BY iso.fkImportId,fd.FKSODetailRowId,fd.RowId  
    ) Sub      
  ON isom.fkImportid=Sub.FkImportId AND idtl.RowId=Sub.FKSODetailRowId
    WHERE isom.fkImportId = '''+ CAST(@importId AS CHAR(36))+'''       
  ) st      
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SODuedtFieldName +')     
  ) AS PVT '    
     --print @SQL
 INSERT INTO @SODueDts EXEC SP_EXECUTESQL @SQL   
  --select * from @SODueDts
  
--Remove the rows from SOMain & SODetail from @SODueDts which has errors   
DELETE FROM @SOMain WHERE RowId IN (SELECT SOMainRowId FROM @SODetail WHERE RowId IN (SELECT RowId FROM @SODueDts WHERE CssClass ='i05red'))  
DELETE FROM @SODetail WHERE RowId IN (SELECT RowId FROM @SODueDts WHERE CssClass ='i05red')  
  
  
INSERT INTO @SODetailvaliddata EXEC GetValidatedSODetailData  @ImportId  
INSERT INTO @SOPricevaliddata  EXEC GetValidatedSOPriceData   @ImportId  
INSERT INTO @SODueDtsvaliddata EXEC GetValidatedSODueDtsData  @ImportId  


--Getting Valid all data from temprory tables and remove the errors Sales Order records from valid data  
DELETE FROM @SODetailvaliddata WHERE ROWId NOT IN(SELECT sdv.RowId FROM @SODetailvaliddata sdv INNER JOIN @SODetail sd ON sdv.RowId=sd.RowId)  
DELETE FROM @SOPricevaliddata WHERE ROWId NOT IN(SELECT spv.RowId FROM @SOPricevaliddata spv INNER JOIN @SODetail sd ON spv.RowId=sd.RowId)  
DELETE FROM @SODueDtsvaliddata WHERE ROWId NOT IN(SELECT spv.RowId FROM @SODueDtsvaliddata spv INNER JOIN @SODetail sd ON spv.RowId=sd.RowId)  
   
----Inserting records into the SOMain Table   
 IF EXISTS (SELECT 1 FROM @SOMain)  
   BEGIN  
	 BEGIN TRY  
		BEGIN TRANSACTION  
			   SELECT @autoSONO = CASE WHEN w.settingId IS NOT NULL THEN  w.settingValue ELSE m.settingValue END   
			   FROM MnxSettingsManagement m  
			   LEFT JOIN wmSettingsManagement w on m.settingId = w.settingId  WHERE settingName = 'AutoSONumber' AND settingDescription='AutoSONumber'

        DECLARE @pcNextNumber char(10) 	
        IF (@autoSONO=1)
		BEGIN
			DECLARE @SoMainRowId UNIQUEIDENTIFIER

			DECLARE SO_cursor CURSOR LOCAL FAST_FORWARD FOR
			SELECT rowId FROM @SOMain

			OPEN SO_cursor;
			FETCH NEXT FROM SO_cursor
			INTO @SoMainRowId ;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXEC [GetNextSONO] @pcNextNumber  OUTPUT

				UPDATE @SOMain SET SONO =@pcNextNumber WHERE RowId =@SoMainRowId AND importId =@ImportId

				FETCH NEXT FROM SO_cursor
				INTO @SoMainRowId;
			END;	
			CLOSE SO_cursor;
			DEALLOCATE SO_cursor;
		END
		ELSE
		BEGIN
		   UPDATE @SOMain SET SONO =TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,SONO),10))
		END

			 UPDATE @SOMain SET Buyer=CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER) WHERE Buyer='' -- For empty buyer there will be 00 will put so buyer should empty
			
			 --Insert data into SOMAIN Table  
			 INSERT  INTO SOMAIN (SONO,CustNo,BLINKADD,OrderDate,DATECHG,ORD_TYPE,SAVEDT,SOFOOT,SOAPPROVAL,SAVEINT,TERMS,SONOTE,PONO,BUYER)
			 SELECT
			  TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.SONO),10))))  AS SONO
			 ,TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.CustNo),10))))  AS CustNo
			 ,CASE WHEN ISNULL(defAdd.LINKADD,'') = '' THEN ''  ELSE linkAdd.LINKADD END AS BLINKADD
			 ,CASE WHEN ISNULL(sm.OrderDate,'') = '' THEN CAST(CAST(GETDATE() AS DATE) AS SMALLDATETIME) ELSE CAST(TRIM(sm.OrderDate) AS DATE) END AS OrderDate
			 ,GETDATE() AS DATECHG,'Open' AS ORD_TYPE,GETDATE() AS ORD_TYPE,'Standard' AS SOFOOT
			 ,(SELECT wm.settingValue FROM MnxSettingsManagement ms JOIN wmSettingsManagement wm ON ms.settingId=wm.settingId WHERE ms.settingName='SOAppReq') AS SOAPPROVAL
			 ,userInit.Initials AS SAVEINT
			 ,CASE WHEN ISNULL(cust.TERMS,'') = '' THEN ''  ELSE cust.TERMS END  AS TERMS
			 , sm.SONOTE AS SONOTE, sm.PONO AS PONO
			 ,CASE WHEN ISNULL(c.Buyer,'') = '' THEN ''  ELSE c.Buyer END  AS Buyer
			 FROM  @SOMain sm 
			 OUTER APPLY
			 (
				SELECT TOP 1 COALESCE(ISNULL(c.CID ,' '),'') AS Buyer FROM @SOMain SM
				 JOIN CCONTACT c ON c.FkUserId = CONVERT(UNIQUEIDENTIFIER, sm.Buyer) AND  c.[TYPE]='C' AND TRIM(c.CUSTNO) = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.CustNo),10))))
			 ) AS c

			 OUTER APPLY 
			 (
				SELECT TOP 1 LINKADD FROM SHIPBILL WHERE RECORDTYPE='B' AND CUSTNO = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.CustNo),10)))) AND IsDefaultAddress=1
			 ) AS defAdd

			 OUTER APPLY(
					SELECT TOP 1 LINKADD FROM SHIPBILL WHERE RECORDTYPE='B' AND CUSTNO = TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.CustNo),10)))) AND IsDefaultAddress=1
			 ) AS linkAdd
			 OUTER APPLY(
				SELECT TOP 1 TERMS FROM CUSTOMER WHERE CUSTNO= TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.CustNo),10)))) 
			 ) AS cust
			 OUTER APPLY (
				SELECT Initials FROM aspnet_Profile WHERE UserId = @UserId
			 )userInit

			  IF(@autoSONO = 1 )
			  BEGIN
					UPDATE a SET a.SONO=s.SONO
					FROM @SODetailvaliddata a JOIN @SOMain s ON s.RowId = a.SOMainRowId

					UPDATE p SET p.SONO=s.SONO
					FROM @SOPricevaliddata p JOIN @SODetailvaliddata s ON p.RowId = s.RowId

					UPDATE p SET p.SONO=s.SONO
					FROM @SODueDtsvaliddata p JOIN @SODetailvaliddata s ON p.RowId = s.RowId

					UPDATE wmSettingsManagement set settingValue=(SELECT MAX(SONO) FROM @SOMain)   
					WHERE settingId IN (SELECT settingId FROM MnxSettingsManagement WHERE settingName = 'LastSONumber')  
			  END
		 COMMIT TRANSACTION  
	END TRY  
	BEGIN CATCH  
	 ROLLBACK TRANSACTION;  
	 SELECT        
	   ERROR_NUMBER() AS ErrorNumber        
	   ,ERROR_SEVERITY() AS ErrorSeverity        
	   ,ERROR_PROCEDURE() AS ErrorProcedure        
	   ,ERROR_LINE() AS ErrorLine        
	   ,ERROR_MESSAGE() AS ErrorMessage;    
	END CATCH  
   END  
   --Inserting records into the SODetail Table   
   -- Fetching default value of Transaction days from  mnxsetting table
	DECLARE @TRANS_DAYS INT;
	SET @TRANS_DAYS =  CAST(TRIM((SELECT w.settingValue FROM wmSettingsManagement w JOIN MnxSettingsManagement m ON m.settingId = w.settingId WHERE 
					   m.settingName ='DeliveryScheduleSetupTransitDays' AND m.settingDescription='DeliveryScheduleSetupTransitDays')) AS INT)

   IF EXISTS ( SELECT 1 FROM @SODetail)  
   BEGIN  
	BEGIN TRY  
		BEGIN TRANSACTION  
		 INSERT  INTO @SODetailInsert (SONO,UNIQUELN,Line_No,UNIQ_KEY,Sodet_Desc,NOTE,ORIGINUQLN,[STATUS],UOFMEAS,W_KEY,Ord_Qty,EACHQTY  
		      ,Attention,BALANCE,EXTENDED,CNFGQTYPER,SlinkAdd,[Description],Category,RowId) 
			  SELECT  so.SONO,dbo.fn_GenerateUniqueNumber() AS UNIQUELN,so.Line_No, so.Uniq_key, so.Sodet_Desc, so.Note, '' AS ORIGINUQLN, 'Standard' AS STATUS
		      ,so.U_OF_MEAS, so.W_KEY,sp.Qty AS Ord_Qty,sp.Qty AS EACHQTY, so.CID AS Attention, sp.Qty AS BALANCE,(sp.Qty * sp.Price) AS EXTENDED,0 AS CNFGQTYPER
		      ,CASE WHEN ISNULL(slinkAdd.ShipConfirmToAddress,'') = '' THEN ''  ELSE slinkAdd.ShipConfirmToAddress END AS SlinkAdd 
		      ,so.[Description], TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.CustNo),10)))) AS Category, sp.RowId  
		     FROM @SODetailvaliddata  so  
		     INNER JOIN @SOPricevaliddata sp ON sp.SONO = so.SONO AND sp.RowId=so.RowId 
		     INNER JOIN @SOMain sm ON so.SONO=sm.SONO
		     OUTER APPLY 
		     (
		   		  SELECT a.ShipConfirmToAddress from shipbill s JOIN  AddressLinkTable a ON s.LINKADD=a.BillRemitAddess
		   		  WHERE s.RECORDTYPE='B' AND s.IsDefaultAddress=1 AND a.IsDefaultAddress=1 AND s.CUSTNO= TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.CustNo),10))))
		   	 ) AS slinkAdd

		 INSERT INTO SODETAIL (SONO,UNIQUELN,Line_No,UNIQ_KEY,Sodet_Desc,NOTE,ORIGINUQLN,[STATUS],UOFMEAS,W_KEY,ORD_QTY,EACHQTY,Attention,BALANCE,EXTENDED,CNFGQTYPER,SLinkAdd,TRANS_DAYS,CATEGORY)  
				  SELECT SONO,UNIQUELN,Line_No,UNIQ_KEY,Sodet_Desc,NOTE,ORIGINUQLN,[STATUS],UOFMEAS,W_KEY,Ord_Qty,EACHQTY,Attention,BALANCE,EXTENDED,CNFGQTYPER,SlinkAdd,@TRANS_DAYS,Category
				  FROM @SODetailInsert  
		COMMIT TRANSACTION  
	END TRY  
	BEGIN CATCH  
		ROLLBACK TRANSACTION;  
		SELECT        
		  ERROR_NUMBER() AS ErrorNumber        
		  ,ERROR_SEVERITY() AS ErrorSeverity        
		  ,ERROR_PROCEDURE() AS ErrorProcedure        
		  ,ERROR_LINE() AS ErrorLine        
		  ,ERROR_MESSAGE() AS ErrorMessage;    
	END CATCH  
   END  
  
   --Inserting records into the SOPrice Table   
   IF EXISTS (SELECT 1 FROM @SOPricevaliddata)  
	BEGIN  
		BEGIN TRY  
			BEGIN TRANSACTION  
				INSERT INTO @SOPricesInsert (PLPRICELNK,SONO,QUANTITY,PRICE,TAXABLE,COG_GL_NBR,PL_GL_NBR,RECORDTYPE,EXTENDED,UNIQUELN,FLAT,SaleTypeId,[Description],RowId)   
					SELECT dbo.fn_GenerateUniqueNumber() AS PLPRICELNK,sp.SONO,sp.Qty AS QUANTITY,sp.Price AS PRICE,sp.TAXABLE
					,(SELECT COG_GL_NBR FROM SALETYPE WHERE SALETYPEID=sp.SaleTypeId) AS COG_GL_NBR  
					,(SELECT GL_NBR FROM SALETYPE WHERE SALETYPEID=sp.SaleTypeId) AS PL_GL_NBR,'P' AS RECORDTYPE
					,(sp.Price*sp.Qty) AS EXTENDED,sd.UNIQUELN,0 AS FLAT,SaleTypeId,sd.[Description],sp.RowId  
					FROM @SOPricevaliddata  sp   
					INNER JOIN @SODetailInsert sd ON  sp.RowId = sd.RowId AND sp.SONO = sd.SONO  
					  
					INSERT INTO SOPRICES(PLPRICELNK,SONO,QUANTITY,PRICE,TAXABLE,COG_GL_NBR,PL_GL_NBR,RECORDTYPE,EXTENDED,UNIQUELN,FLAT,SaleTypeId,DESCRIPTIO)   
					 SELECT PLPRICELNK,SONO,QUANTITY,PRICE,TAXABLE,COG_GL_NBR,PL_GL_NBR,RECORDTYPE,EXTENDED,UNIQUELN,FLAT,SaleTypeId,[Description]
					 FROM @SOPricesInsert  
			COMMIT TRANSACTION  
		END TRY  
		BEGIN CATCH  
			ROLLBACK TRANSACTION;  
			SELECT        
			  ERROR_NUMBER() AS ErrorNumber        
			  ,ERROR_SEVERITY() AS ErrorSeverity        
			  ,ERROR_PROCEDURE() AS ErrorProcedure        
			  ,ERROR_LINE() AS ErrorLine        
			  ,ERROR_MESSAGE() AS ErrorMessage;    
		END CATCH  
    END  
  
   --Inserting records into the SODudts Table   
   IF EXISTS (SELECT 1 FROM @SODueDts)  
   BEGIN  
		BEGIN TRY  
			BEGIN TRANSACTION  
				IF EXISTS (SELECT 1 FROM @SODueDts)  
				BEGIN  
				 INSERT INTO @SODueDtsInsert (DUEDT_UNIQ,SONO,COMMIT_DTS,SHIP_DTS,DUE_DTS,UNIQUELN,Qty,RowId)   
				 SELECT dbo.fn_GenerateUniqueNumber() AS DUEDT_UNIQ,sp.SONO,sp.COMMIT_DTS,sp.SHIP_DTS,sp.DUE_DTS,sd.UNIQUELN,sp.Qty,sp.RowId  
				 FROM @SODueDtsvaliddata sp   
				 INNER JOIN @SODetailInsert sd ON  sp.RowId = sd.RowId AND sp.SONO = sd.SONO  

				 INSERT INTO DUE_DTS (DUEDT_UNIQ,SONO,COMMIT_DTS,SHIP_DTS,DUE_DTS,UNIQUELN,Qty)   
				 SELECT DUEDT_UNIQ,SONO,COMMIT_DTS,SHIP_DTS,DUE_DTS,UNIQUELN,Qty FROM @SODueDtsInsert  WHERE NOT (ISNULL(DUE_DTS,'') = '') AND  NOT (ISNULL(COMMIT_DTS,'') = '') AND  NOT (ISNULL(SHIP_DTS,'') = '')

                 ;WITH temp AS(
                   SELECT SUM(dt.qty) AS ORD_QTY,dt.UNIQUELN,so.SONO
                   FROM @SODueDtsInsert dt
                   JOIN @SODetailInsert so ON dt.SONO=so.SONO AND dt.UNIQUELN=so.UNIQUELN 
                   GROUP BY dt.UNIQUELN,so.SONO
                 )
                 --Update the ORD_QTY of SODETAIL table for same line number
                 UPDATE s SET s.EACHQTY = t.ORD_QTY, s.ORD_QTY = t.ORD_QTY, s.BALANCE = t.ORD_QTY, s.EXTENDED = (t.ORD_QTY * sp.PRICE) FROM SODETAIL s 
                 JOIN temp t ON s.UNIQUELN=t.UNIQUELN
                 JOIN SOPRICES sp on t.UNIQUELN = sp.UNIQUELN
				 
                 --Update the SOPRICES of SODETAIL table for same line number
                 UPDATE p SET p.QUANTITY = s.ORD_QTY,p.EXTENDED=(s.ORD_QTY * p.price) FROM @SODetailInsert s JOIN SOPRICES p ON s.UNIQUELN=p.UNIQUELN
				 
                 --select p.UNIQUELN,s.UNIQUELN,sp.UNIQUELN,s.Ord_Qty,p.ORD_QTY,sp.PRICE FROM @SODetailInsert s 
                 UPDATE sp SET sp.QUANTITY = p.ORD_QTY, sp.EXTENDED = (p.ORD_QTY * sp.PRICE) FROM @SODetailInsert s 
                 JOIN SODETAIL p ON s.UNIQUELN=p.UNIQUELN
                 JOIN SOPRICES sp on s.UNIQUELN = sp.UNIQUELN
				 
                  --Update the SOPRICES of taxable column from table INVENTOR for same line number
                 UPDATE p SET p.TAXABLE = i.Taxable FROM @SODetailInsert s  
                 JOIN SOPRICES p ON s.UNIQUELN=p.UNIQUELN
                 JOIN INVENTOR i ON s.UNIQ_KEY = i.UNIQ_KEY
				 
                 DECLARE @extendValues TABLE (Extend NUMERIC(14,2),  SONO VARCHAR(10))
				 INSERT INTO @extendValues
				 SELECT SUM(sp.EXTENDED) AS Extend, sp.SONO FROM @SOPricesInsert spi JOIN SOPRICES sp ON sp.PLPRICELNK=spi.PLPRICELNK Group BY sp.SONO
                 
				 ----Update the SOEXTEND of SOMAIN table for
                 UPDATE sm SET SOEXTEND = Extend  FROM SOMAIN sm JOIN  @extendValues sp ON sm.SONO=sp.SONO

				 ---- SOAMOUNT LOGIC
				 DECLARE @soData TABLE (SONO VARCHAR(10), CustNo VARCHAR(10), DISCOUNT NUMERIC(12,2))

				 DECLARE @SONO VARCHAR(10),@CustNo VARCHAR(10), @DISCOUNT NUMERIC(12,2);

				 INSERT INTO @soData
				 SELECT DISTINCT sd.sono, sm.CUSTNO
				 ,CASE WHEN ISNULL(discount.DISCOUNT,0) = 0 THEN 0 ELSE discount.DISCOUNT END AS  DISCOUNT FROM @SODetailInsert sd
				 INNER JOIN SOMAIN sm ON sd.SONO = sm.SONO
				 INNER JOIN CUSTOMER cust ON sm.CUSTNO = cust.CUSTNO
				 LEFT JOIN SALEDSCT discount ON cust.SALEDSCTID = discount.SALEDSCTID

				 DECLARE SOData_cursor CURSOR LOCAL FAST_FORWARD FOR
				 SELECT SONO,custno,DISCOUNT FROM @soData

				 OPEN SOData_cursor;
				 FETCH NEXT FROM SOData_cursor
				 INTO @SONO,@CustNo,@DISCOUNT ;
				 
				 WHILE @@FETCH_STATUS = 0
				 BEGIN
				 	DECLARE @sodetailtaxes TABLE ( Extended  NUMERIC(12,2), UNIQ_KEY VARCHAR(100))
				 	DECLARE @Taxestbl TABLE (TAX_ID  VARCHAR(100), TaxRate NUMERIC(12,2), TAXTYPE VARCHAR(100),TAXUNIQUE VARCHAR(100), TaxApplicableTo VARCHAR(100), IsProductTotal BIT)
					DECLARE @secondaryTaxTable TABLE (TAX_ID  VARCHAR(100), TaxRate NUMERIC(12,2), TAXTYPE VARCHAR(100),TAXUNIQUE VARCHAR(100), TaxApplicableTo VARCHAR(100), IsProductTotal BIT)
					DECLARE @Extended NUMERIC(12,2), @UNIQ_KEY VARCHAR(100), @Tax_Rate NUMERIC(12,2), @TaxonGoodsAmount NUMERIC(12,2), @TotalTaxOnGoodsAmount NUMERIC(12,2), @actualTaxOnGoods NUMERIC(12,2)
						    ,@TaxRateOfSecondaryTax NUMERIC(12,2), @taxOnTaxAmount  NUMERIC(12,2), @TotalTaxOnTaxAmount  NUMERIC(12,2), @TAX_ID VARCHAR(100), @TaxRate NUMERIC(12,2), @TAXTYPE VARCHAR(100)
						    ,@TAXUNIQUE VARCHAR(100), @TaxApplicableTo VARCHAR(100), @IsProductTotal BIT, @NOofRos NUMERIC(10);

					SET @TaxonGoodsAmount = 0.0;
					SET @TotalTaxOnGoodsAmount = 0.0;
					SET @TotalTaxOnTaxAmount = 0.0;
					
					-- Inserting the taxes data into the @Taxestbl
					INSERT INTO @Taxestbl
					SELECT s.TAX_ID, s.TAX_RATE AS TaxRate, t.TAXTYPE, t.TAXUNIQUE, t.TaxApplicableTo, t.IsProductTotal 
					FROM SHIPTAX s
					JOIN TAXTABL t ON s.TAX_ID=t.TAX_ID
					WHERE s.CUSTNO = @CustNo AND s.TAXTYPE = 'S' 
					
					-- Inserting the SODETAIL data into the @sodetailtaxes
					INSERT INTO @sodetailtaxes 
				   	SELECT sodet.EXTENDED, sodet.UNIQ_KEY FROM SOMAIN so
				   	INNER JOIN SODETAIL sodet ON so.SONO = sodet.SONO
				   	INNER JOIN INVENTOR i ON sodet.UNIQ_KEY = i.UNIQ_KEY
				   	WHERE so.SONO = @SONO AND i.Taxable = 1
				   
					DECLARE SODetail_cursor CURSOR LOCAL FAST_FORWARD FOR

					SELECT Extended ,UNIQ_KEY  FROM @sodetailtaxes

					OPEN SODetail_cursor ;
					FETCH NEXT FROM SODetail_cursor 
					INTO @Extended, @UNIQ_KEY

					WHILE @@FETCH_STATUS = 0
					BEGIN
						-- Checking the taxes are available for the customer or not
						IF EXISTS (SELECT * FROM @Taxestbl)
						BEGIN
							 --Here we are calculating the TaxonGoods of all taxes which are present on customer
							 SET @Tax_Rate = 0.0;
							 SELECT @Tax_Rate = SUM(TAXRATE) FROM @Taxestbl  WHERE TAXTYPE = 'Tax On Goods'
							 SET @TaxonGoodsAmount = (@Extended * @Tax_Rate) / 100;

							 --Here we are calculating the discount on the TaxonGoods
							 SET @TaxonGoodsAmount = @TaxonGoodsAmount - (@TaxonGoodsAmount * @DISCOUNT)/100;
							 
							 -- Storing the total @TotalTaxOnGoodsAmount of every iteration
							 SET @TotalTaxOnGoodsAmount = @TotalTaxOnGoodsAmount + @TaxonGoodsAmount;

							 -- Secondary tax logic
							 INSERT INTO @secondaryTaxTable
							 SELECT * FROM @Taxestbl WHERE TAXTYPE = 'Secondary Tax'
							 
							 IF EXISTS (SELECT * FROM @secondaryTaxTable)	
							 BEGIN								
								SET @taxOnTaxAmount = 0.0;
								DECLARE Tax_cursor CURSOR LOCAL FAST_FORWARD FOR
								SELECT TAX_ID, TaxRate, TAXTYPE, TAXUNIQUE,TaxApplicableTo, IsProductTotal FROM @secondaryTaxTable
								
								OPEN Tax_cursor;
								FETCH NEXT FROM Tax_cursor
				   				INTO @TAX_ID, @TaxRate, @TAXTYPE, @TAXUNIQUE, @TaxApplicableTo, @IsProductTotal;
								WHILE @@FETCH_STATUS = 0
								BEGIN
									SELECT @TaxRateOfSecondaryTax = t.TaxRate FROM @Taxestbl t WHERE t.TAXUNIQUE = @TaxApplicableTo
									
									SET @actualTaxOnGoods = (@Extended * @TaxRateOfSecondaryTax) / 100;
									
									IF (@IsProductTotal = 1)
									BEGIN
										SET @taxOnTaxAmount = @taxOnTaxAmount + ((@Extended + @actualTaxOnGoods) * @TaxRate) / 100;
									END
									ELSE
									BEGIN
										SET @taxOnTaxAmount = @taxOnTaxAmount + (@actualTaxOnGoods * @TaxRate) / 100;
									END
									FETCH NEXT FROM Tax_cursor
				   					INTO @TAX_ID, @TaxRate, @TAXTYPE, @TAXUNIQUE, @TaxApplicableTo, @IsProductTotal;
								END;	

								-- Calculating the discount on the secondary tax
								SET @taxOnTaxAmount = @taxOnTaxAmount - ((@taxOnTaxAmount * @DISCOUNT) / 100);
								
								-- Storing the total @TotalTaxOnGoodsAmount of every iteration
								SET @TotalTaxOnTaxAmount = @TotalTaxOnTaxAmount + @taxOnTaxAmount;

								CLOSE Tax_cursor;
								DEALLOCATE Tax_cursor;
								DELETE FROM @secondaryTaxTable
							END
						END
						ELSE
						BEGIN
							SET @TotalTaxOnGoodsAmount = 0.0;
							SET @TotalTaxOnTaxAmount = 0.0;
						END

						FETCH NEXT FROM SODetail_cursor
				   		INTO  @Extended, @UNIQ_KEY;
					END;

					UPDATE SOMAIN SET SOTAX = @TotalTaxOnGoodsAmount + @TotalTaxOnTaxAmount, SOAMTDSCT = (SOEXTEND * @DISCOUNT)/100 WHERE SONO = @SONO
					UPDATE SOMAIN SET SOAMOUNT = SOEXTEND + SOTAX - SOAMTDSCT WHERE SONO = @SONO

					CLOSE SODetail_cursor;
					DEALLOCATE SODetail_cursor;

					-- Removing the previous records form the table
					DELETE FROM @sodetailtaxes
					DELETE FROM @Taxestbl

				   	FETCH NEXT FROM SOData_cursor
				   	INTO @SONO,@CustNo,@DISCOUNT;
				   END;	
				CLOSE SOData_cursor;
				DEALLOCATE SOData_cursor;
			END  
			COMMIT TRANSACTION  
		END TRY  
		BEGIN CATCH  
		ROLLBACK TRANSACTION;     
	    SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
				   @ErrorSeverity, -- Severity.
				   @ErrorState -- State.
				   );
		END CATCH  
   END  
 
    --Inserting records into the SOPRICESTAX Table   
   IF EXISTS (SELECT 1 FROM @SOPricevaliddata WHERE Taxable=1)  
   BEGIN  
	BEGIN TRY  
		BEGIN TRANSACTION  
			INSERT INTO SOPRICESTAX (UNIQSOPRICESTAX,SONO,UNIQUELN,PLPRICELNK,TAX_ID,TAX_RATE,TAXTYPE)  
			SELECT dbo.fn_GenerateUniqueNumber() AS UNIQSOPRICESTAX, SONO,UNIQUELN,PLPRICELNK,tax.TAX_ID,tax.TAX_RATE,tax.TAXTYPE FROM @SOPricesInsert sop  
			OUTER APPLY(  
			 SELECT TAX_ID,TAX_RATE,TAXTYPE FROM SHIPTAX   
			 WHERE CUSTNO IN(SELECT TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, custno),10))))   
			     FROM @SOMain sm INNER JOIN @SODetail sd ON sm.RowId=sd.SOMainRowId WHERE sd.RowId IN(SELECT RowId FROM @SOPricesInsert WHERE TAXABLE=1))  
			 AND TAXTYPE='S'  
			)tax  
			WHERE sop.RowId IN (SELECT RowId FROM @SOPricesInsert WHERE TAXABLE=1)  
		COMMIT TRANSACTION  
	END TRY  
    BEGIN CATCH  
		ROLLBACK TRANSACTION;  
		SELECT        
		  ERROR_NUMBER() AS ErrorNumber        
		  ,ERROR_SEVERITY() AS ErrorSeverity        
		  ,ERROR_PROCEDURE() AS ErrorProcedure        
		  ,ERROR_LINE() AS ErrorLine        
		  ,ERROR_MESSAGE() AS ErrorMessage;    
	END CATCH  
  END  
END