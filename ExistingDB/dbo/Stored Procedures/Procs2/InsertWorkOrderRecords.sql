-- ============================================================================================================  
-- Date   : 08/26/2019  
-- Author  : Rajendra K 
-- Description : Used for Insert new Work order.  InsertWorkOrderRecords
-- 09/28/2019 Rajendra K : Changed condition for end_date
-- 09/28/2019 Rajendra K : Added leading zero to sono
-- 09/30/2019 Rajendra K : Added condition to update wono when auto number setting is true
-- 11/07/2019 Rajendra K : Put NULL value in COMPLETEDT column of WOENTRY table
-- 04/23/2020 Rajendra K : Get last the wono from sp "GetNextWorkOrderNo" and removed the updation for wmSettingsManagement
-- EXEC InsertWorkOrderRecords '3041A339-4D50-4694-9744-7DEC53084878','49F80792-E15E-4B62-B720-21B360E3108A' ,''  
-- ============================================================================================================  
  
CREATE PROC InsertWorkOrderRecords  
 @importId UNIQUEIDENTIFIER,  
 @userId UNIQUEIDENTIFIER=null,
 @wono char(10) = '' OUTPUT  
AS  
BEGIN  
   
 SET NOCOUNT ON    
 DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName varchar(max),@autoWO BIT,@autoRel BIT,@lastWONO CHAR(10),@uniqKey CHAR(10);  
  
 DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,WORowId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER, CssClass VARCHAR(100),Validation VARCHAR(100), bldqty VARCHAR(10),
							  Due_date VARCHAR(100),End_date VARCHAR(100), JobType VARCHAR(100),kitDefWarehouse VARCHAR(100),Line_no VARCHAR(100),OrderDate VARCHAR(100),
							  PRJNUMBER VARCHAR(100),PRJUNIQUE	VARCHAR(100),RoutingName VARCHAR(100),SONO VARCHAR(100),Start_date VARCHAR(100),wono VARCHAR(100),Wonote VARCHAR(100))
							  
 DECLARE @AssemblyDetail TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),
							  assyDesc VARCHAR(100),assyNum VARCHAR(100),assypartclass VARCHAR(100),
							  assyparttype VARCHAR(100),assyRev VARCHAR(100),custno VARCHAR(100),UNIQ_KEY VARCHAR(10))   							  						  

 -- Insert statements for procedure here    
 SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_BOMtoKITUpload' and FilePath = 'BOMtoKITUpload'   
 SELECT @FieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId  AND FieldName in ('bldqty','Due_date','End_date','JobType','kitDefWarehouse','Line_no','OrderDate','PRJNUMBER','PRJUNIQUE'
						,'RoutingName','SONO','Start_date','wono','Wonote')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')    
  
 SELECT @SQL = N'    
   SELECT PVT.*  
  FROM    
  (   
   SELECT ibf.fkImportId AS importId,ic.WORowId,ibf.AssemblyRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
   FROM ImportFieldDefinitions fd      
	 INNER JOIN ImportBOMToKitWorkOrder ic ON fd.FieldDefId = ic.FKFieldDefId
     INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
     INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
	 INNER JOIN   
	   (   
			SELECT fkImportId,WORowId,AssemblyRowId,MAX(ic.status) as Class ,MIN(ic.Message) as Validation		
			FROM ImportBOMToKitAssemly fd  
				INNER JOIN ImportBOMToKitWorkOrder ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
				INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
			WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''    
				AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')     
			GROUP BY fkImportId,WORowId,AssemblyRowId 
	   ) Sub    
   ON ibf.fkImportid=Sub.FkImportId and ic.WORowId = sub.WORowId AND ic.FKAssemblyRowId = sub.AssemblyRowId 
   WHERE ibf.fkImportId = '''+ CAST(@importId as CHAR(36))+'''  
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @FieldName +')   
  ) as PVT '  
   
 -- Print @SQL  
 INSERT INTO @ImportDetail EXEC sp_executesql @SQL;
 INSERT INTO @AssemblyDetail EXEC GetAssemblyRecords @importId;  

--SELECT * FROM @ImportDetail   
--SELECT * FROM @AssemblyDetail   
	BEGIN TRY  
		BEGIN TRANSACTION 
			IF (NOT EXISTS(SELECT 1 FROM @AssemblyDetail WHERE CssClass <>'') AND NOT EXISTS(SELECT 1 FROM @ImportDetail WHERE CssClass <>''))
			BEGIN
					SELECT TOP 1 @uniqKey = UNIQ_KEY from @AssemblyDetail

					SELECT @autoWO = CASE WHEN w.settingId IS NOT NULL THEN  w.settingValue ELSE m.settingValue END 
							FROM MnxSettingsManagement m
								LEFT JOIN wmSettingsManagement w on m.settingId = w.settingId
							WHERE settingName = 'AutoWONumber' AND settingDescription = 'AutoGenerateWO' 

					IF(@autoWO=1)  
					BEGIN  
      --SELECT @lastWONO=CASE WHEN w.settingId IS NOT NULL THEN w.settingValue ELSE m.settingValue END  
      --FROM MnxSettingsManagement m JOIN wmSettingsManagement w ON w.settingId = m.settingId  
      --WHERE settingName = 'LastWONO'  
	  -- 04/23/2020 Rajendra K : Get last the wono from sp "GetNextWorkOrderNo" and removed the updation for wmSettingsManagement
		EXEC [GetNextWorkOrderNo] @lastWONO OUTPUT
					END 
		
					SELECT @autoRel=CASE WHEN w.settingId IS NOT NULL THEN w.settingValue ELSE m.settingValue END
						FROM MnxSettingsManagement m JOIN wmSettingsManagement w ON w.settingId = m.settingId
						WHERE settingName= 'WOAutoReleaseSetting'
					
					UPDATE @ImportDetail SET wono = CASE WHEN @autoWO = 1 
	 -- 04/23/2020 Rajendra K : Get last the wono from sp "GetNextWorkOrderNo" and removed the updation for wmSettingsManagement
               THEN RIGHT('0000000000'+ CONVERT(VARCHAR,@lastWONO),10) --RIGHT('0000000000'+ CONVERT(VARCHAR,@lastWONO + 1),10)   
														 ELSE TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,wono),10)) END									

					CREATE TABLE #FinalWorkOrder(WONO VARCHAR(10),UNIQ_KEY VARCHAR(10),OPENCLOS VARCHAR(10),JobType VARCHAR(10),
						ORDERDATE SMALLDATETIME, DUE_DATE SMALLDATETIME,[START_DATE] SMALLDATETIME,End_date SMALLDATETIME,BLDQTY INT,
						COMPLETE INT,BALANCE INT,CUSTNO VARCHAR(10), SONO VARCHAR(10), UNIQUELN VARCHAR(10), PRJUNIQUE VARCHAR(10),
						LFCSTITE VARCHAR(10), CreatedByUserId  UNIQUEIDENTIFIER, KitUniqWh  VARCHAR(10),KIT bit, RELEDATE SMALLDATETIME, 
						ReleasedBy UNIQUEIDENTIFIER, WONOTE VARCHAR(500), SERIALYES BIT, uniquerout VARCHAR(10));


					    INSERT INTO #FinalWorkOrder 
						SELECT RIGHT('0000000000'+ CONVERT(VARCHAR,wono),10) WONO,invt.UNIQ_KEY UNIQ_KEY,'Open' OPENCLOS,TRIM(t.JobType) JobType
						   			-- Order date
									,CASE WHEN LTRIM(t.ORDERDATE) = '' THEN
										CAST(CAST(GETDATE() As date) AS VARCHAR(50))  
									ELSE 
										CAST(t.ORDERDATE AS VARCHAR(50))  
									END	ORDERDATE 		   

									-- Due date
									,CASE WHEN LTRIM(t.DUE_DATE) = '' THEN
										CAST(
											CAST((
													DATEADD(DAY, invt.PROD_LTIME, 
														CASE WHEN LTRIM(t.ORDERDATE) = '' THEN 
															GETDATE() 
															 ELSE 
															CAST(t.ORDERDATE AS VARCHAR(50)) 
														END)
												) As date) AS VARCHAR(50)
											)  
									ELSE 
										CAST(t.DUE_DATE AS VARCHAR(50))  
									END DUE_DATE
									
									-- Start date
									,CASE WHEN LTRIM(t.[START_DATE]) = '' THEN
											CASE WHEN LTRIM(t.ORDERDATE) = '' THEN
												CAST(CAST(GETDATE() As date) AS VARCHAR(50))  
											ELSE 
												CAST(t.ORDERDATE AS VARCHAR(50))  
											END	
									     WHEN (t.[START_DATE] <> '' AND ISDATE(t.[START_DATE])=1) THEN
											CAST(t.[START_DATE] AS VARCHAR(50)) 
									END [START_DATE]
									
									-- End date 
				   				 ,CASE WHEN LTRIM(t.End_date) = '' THEN -- 09/28/2019 Rajendra K : Changed condition for end_date
				   						CAST(CAST((DATEADD(DAY, invt.PROD_LTIME, CASE WHEN LTRIM(t.Due_date) = '' THEN
												CAST(CAST(GETDATE() As date) AS VARCHAR(50))  
											ELSE 
												CAST(t.Due_date AS VARCHAR(50))  
											END	)) As date) AS VARCHAR(50))  
				   					 WHEN (LTRIM(t.End_date) <> '' AND ISDATE(t.End_date)=1) THEN
				   						CAST(t.End_date AS VARCHAR(50)) 
									END End_date
									
								,t.BLDQTY as BLDQTY,0 COMPLETE,t.BLDQTY as BALANCE,
								CASE WHEN Ass.custno = '' OR Ass.custno IS NULL THEN '000000000~' ELSE TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,Ass.custno),10)) END AS CUSTNO
								-- 09/28/2019 Rajendra K : Added leading zero to sono
								,CASE WHEN ISNULL(t.SONO ,'') = '' THEN '' ELSE RIGHT('0000000000'+ CONVERT(VARCHAR,t.SONO),10) END AS SONO,
								ISNULL((
									SELECT TOP 1 UNIQUELN FROM SODETAIL WHERE SONO = RIGHT('0000000000'+ CONVERT(VARCHAR,t.SONO),10) 
										AND (LINE_NO = RIGHT('0000000'+ CONVERT(VARCHAR,t.Line_no),7) OR 1=1)
								),'') UNIQUELN,
								t.PRJUNIQUE,0 LFCSTITE, 
								 @userId CreatedByUserId,								
								ISNULL((select Top 1 UNIQWH FROM WAREHOUS WHERE Warehouse = t.kitDefWarehouse),'') KitUniqWh,
								 -- Fields based on fields on @autoRel settings
								 CASE WHEN @autoRel = 1 THEN 1 ELSE 0 END KIT,
								 CASE WHEN @autoRel = 1 THEN GETDATE() ELSE NULL END RELEDATE,
								 CASE WHEN @autoRel = 1 THEN @userId ELSE NULL END ReleasedBy,
								 '',
								 --t.WONOTE,
								 invt.SERIALYES,
								 TRIM(ISNULL((SELECT Top 1 rp.uniquerout FROM routingProductSetup rp 
								INNER JOIN RoutingTemplate rt ON rp.TemplateID=rt.TemplateID
								WHERE TRIM(rt.TemplateName) = TRIM(RoutingName) 
								AND TRIM(rt.TemplateType) = CASE WHEN TRIM(t.JobType) LIKE 'Rework%' THEN 'Rework' ELSE 'Regular' END
								AND UNIQ_KEY= invt.UNIQ_KEY)
								 ,'')) uniquerout
							FROM @ImportDetail t
								INNER JOIN @AssemblyDetail Ass ON t.AssemblyRowId = Ass.AssemblyRowId
								INNER JOIN INVENTOR invt ON invt.UNIQ_KEY = Ass.UNIQ_KEY
							
							INSERT INTO WOENTRY(WONO,UNIQ_KEY,OPENCLOS,JobType,ORDERDATE,DUE_DATE,[START_DATE],COMPLETEDT,
										BLDQTY,COMPLETE,BALANCE,CUSTNO,SONO,UNIQUELN,PRJUNIQUE,LFCSTITEM,
										CreatedByUserId,KitUniqWh,KIT,RELEDATE,ReleasedBy,WONOTE,SERIALYES,uniquerout)-- 11/07/2019 Rajendra K : Put NULL value in COMPLETEDT column of WOENTRY table
							SELECT WONO, UNIQ_KEY, OPENCLOS, JobType, ORDERDATE, DUE_DATE, [START_DATE], NULL, BLDQTY, COMPLETE, 
								   BALANCE, CUSTNO, SONO, UNIQUELN, PRJUNIQUE, LFCSTITE, CreatedByUserId, KitUniqWh, KIT, RELEDATE, 
								   ReleasedBy, WONOTE, SERIALYES, uniquerout
							FROM #FinalWorkOrder

					-- Insert into PROD_DTS for schedule planner
				   DECLARE @totalWOCount INT, @twoNumber VARCHAR(10),@CompleteDT SMALLDATETIME,@StartDate SMALLDATETIME	
				   				   
				   	SELECT TOP 1  @twoNumber = WONO,@StartDate = [START_DATE] ,@CompleteDT = End_date
				   	FROM #FinalWorkOrder 					
				  	EXEC NewSchPlanningAdjustWOStart @twoNumber,@StartDate,@CompleteDT,@userId,1

  -- 04/23/2020 Rajendra K : Get last the wono from sp "GetNextWorkOrderNo" and removed the updation for wmSettingsManagement
     --IF(@autoWO=1)  -- 09/30/2019 Rajendra K : Added condition to update wono when auto number setting is true  
     --BEGIN   
     -- UPDATE wmSettingsManagement set settingValue=(SELECT TOP 1 WONO FROM #FinalWorkOrder)   
     -- WHERE settingId IN (SELECT settingId FROM MnxSettingsManagement WHERE settingName = 'LastWONO')  
     --END  
		
					-- WmNote and WmNoteRelationship note insert
					-- Insert WmNotes For Work order	
					SELECT NewId() NoteID,Wonote [Description],@userId fkCreatedUserID,GETDATE() CreatedDate,0 IsDeleted,'' NoteType,
						   RIGHT('0000000000'+ CONVERT(VARCHAR,wono),10) RecordId,'WorkOrder' RecordType,2 NoteCategory,0 IsActionClose,0 CarNo,
						   0 IsFollowUpComplete,'' IssueType,NULL Importance,0 IsCustomerSupport,0 Progress,0 IsNewTask,NULL [Priority] 
					INTO #WmNotes 
					FROM @ImportDetail
					WHERE Wonote <> ''
					
					INSERT INTO wmNotes(NoteID,[Description],fkCreatedUserID,CreatedDate,IsDeleted,NoteType,RecordId,RecordType,
										NoteCategory,IsActionClose,CarNo,IsFollowUpComplete,IssueType,Importance,IsCustomerSupport,
										Progress,IsNewTask,[Priority])
					SELECT * FROM #WmNotes WHERE Description <> ''

					-- Insert wmNoteRelationship For Work order Notes
					INSERT INTO wmNoteRelationship(NoteRelationshipId, FkNoteId, CreatedUserId, Note, CreatedDate, ImagePath, IsWhisper, ReplyNoteRelationshipId)
					SELECT NewId(),NoteID,@userId,[Description],CreatedDate,'',0,NULL FROM #WmNotes WHERE Description <> ''
					SELECT TOP 1 @wono = WONO FROM #FinalWorkOrder 
			END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
	END CATCH
END