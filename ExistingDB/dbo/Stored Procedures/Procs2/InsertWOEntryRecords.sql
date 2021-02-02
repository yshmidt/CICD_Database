-- ============================================================================================================
-- Date			: 07/09/2019
-- Author		: Satyawan H
-- Description	: Insert only valid Work Order after Upload
-- Satyawan H 11/11/2019: Add NULL value for CompleteDt when creating WO 
-- ============================================================================================================
-- EXEC InsertWOEntryRecords '96850E6F-1C63-436D-96A4-3A20FBE78464','49F80792-E15E-4B62-B720-21B360E3108A'

CREATE PROC InsertWOEntryRecords 
	@ImportId UNIQUEIDENTIFIER,
	@userId UNIQUEIDENTIFIER
AS
BEGIN
	SET NOCOUNT ON  
	DECLARE @SQL NVARCHAR(MAX),@ModuleId INT,@FieldName varchar(max),
			@autoWO BIT,@autoRel BIT,@lastWONO CHAR(10)
	
	DECLARE @ImportDetail TABLE (importId UNIQUEIDENTIFIER,rowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),[Validation] VARCHAR(100), 
								 IsValid VARCHAR(100),BLDQTY VARCHAR(100),custName VARCHAR(100),CUSTNO VARCHAR(100),DUE_DATE VARCHAR(100), 
								 End_date VARCHAR(100),JobType VARCHAR(100),Line_no VARCHAR(100),OPENCLOS VARCHAR(100),ORDERDATE VARCHAR(100),	
								 PART_NO VARCHAR(100),PRJNUMBER	VARCHAR(100),PRJUNIQUE VARCHAR(100),RELEDATE VARCHAR(100),Revision VARCHAR(100),
								 RoutingName VARCHAR(100),SONO VARCHAR(100),[START_DATE] VARCHAR(100),UNIQ_KEY VARCHAR(100),Warehouse VARCHAR(100), 
								 WONO VARCHAR(100),WONOTE VARCHAR(100)) 

	-- Insert statements for procedure here  
	SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleName = 'WO Upload' and FilePath = 'WOUpload'
	SELECT @FieldName = STUFF(  
						(  
							SELECT  ',[' +  F.FIELDNAME + ']' FROM ImportFieldDefinitions F    
							WHERE ModuleId = @ModuleId 
							ORDER BY F.FIELDNAME 
							FOR XML PATH('')  
						),  
						1,1,'')   

	SELECT @SQL = N'  
		SELECT PVT.*
		FROM  
		(
			SELECT ibf.fkImportId AS importId,ibf.rowId,sub.class as CssClass,sub.Validation,fd.fieldName,adjusted,IsValidWO.IsValid'  
			+' FROM ImportFieldDefinitions fd    
			INNER JOIN ImportWOUploadFields ibf ON fd.FieldName = ibf.FieldName AND fd.ModuleId = ' + CAST(@ModuleId as varchar(10))
			+' Outer APPLY (
					SELECT TOP 1 CASE WHEN (count(FkImportId) = 0) THEN 1 ELSE 0 END IsValid 
						from ImportWOUploadFields i 
						WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+''' 
						AND Message <> ''''
						AND FIELDNAME IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')
						AND i.rowid= ibf.rowid
			) IsValidWO	
			INNER JOIN ImportWOUploadHeader h ON h.ImportId = ibf.FkImportId 
			INNER JOIN (SELECT fkImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation  
				FROM ImportWOUploadFields WHERE fkImportId ='''+ CAST(@importId as CHAR(36))+'''  
				AND FieldName IN ('+REPLACE(REPLACE(@FieldName,'[',''''),']','''')+')
				GROUP BY fkImportId,rowid) Sub  
			ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid  
			WHERE ibf.fkImportId ='''+ CAST(@importId as CHAR(36))+'''   
			) st  
		PIVOT (MAX(adjusted) FOR fieldName IN ('+ @FieldName +')) as PVT 
		LEFT JOIN CUSTOMER c ON c.CUSTNO = PVT.CUSTNO WHERE isValid = 1  
		ORDER BY [part_no],[revision]'

		INSERT INTO @ImportDetail EXEC sp_executesql @SQL   
		
		-- Update the CustName and CustNo
		UPDATE impt 
		SET 
			CUSTNO = CASE WHEN TRIM(impt.Custno) <> '' THEN 
							TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10)) 
						  WHEN TRIM(impt.custName) <> '' THEN
						  	ISNULL((select TOP 1 TRIM(CUSTNO) FROM CUSTOMER WHERE custName = TRIM(impt.custName)),'')
					 ELSE
						TRIM(impt.CUSTNO)
					 END 
		   ,CUSTNAME = CASE WHEN TRIM(impt.Custno) <> '' THEN 
								ISNULL((SELECT TOP 1 TRIM(CUSTNAME) FROM CUSTOMER WHERE CUSTNO = TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR,impt.CUSTNO),10))),'')
							ELSE 
								TRIM(custName)
					   END
		FROM @ImportDetail impt 
		LEFT JOIN INVENTOR Inv ON ((impt.UNIQ_KEY <> '' AND impt.UNIQ_KEY = Inv.UNIQ_KEY ) OR (impt.UNIQ_KEY ='' AND 
									impt.PART_NO = inv.PART_NO AND TRIM(impt.Revision) = TRIM(inv.REVISION)))

		-- Get Auto_WO and WO_AutoRel setting value
		SELECT @autoWO = CASE WHEN w.settingId IS NOT NULL THEN  w.settingValue ELSE m.settingValue END FROM MnxSettingsManagement m
			LEFT JOIN wmSettingsManagement w on m.settingId = w.settingId
			WHERE settingName = 'AutoWONumber' AND settingDescription = 'AutoGenerateWO' 
		
		IF OBJECT_ID('tempdb..#temp') IS NOT NULL
			DROP TABLE #Results
		
		IF(@autoWO=1)  
        BEGIN  
			SELECT @lastWONO=CASE WHEN w.settingId IS NOT NULL THEN w.settingValue ELSE m.settingValue END
			FROM MnxSettingsManagement m JOIN wmSettingsManagement w ON w.settingId = m.settingId
			WHERE settingName= 'LastWONO'
        END 
		
		SELECT @autoRel=CASE WHEN w.settingId IS NOT NULL THEN w.settingValue ELSE m.settingValue END
			FROM MnxSettingsManagement m JOIN wmSettingsManagement w ON w.settingId = m.settingId
			WHERE settingName= 'WOAutoReleaseSetting'
		
		-- Populate WOs
		;WITH tempWo AS (
			SELECT CASE WHEN @autoWO = 1 THEN 
				   RIGHT('0000000000'+ CONVERT(VARCHAR,@lastWONO + ROW_NUMBER() OVER (ORDER BY WONO)),10) 
				ELSE WONO END WONOT, * FROM @ImportDetail		
		),
		tempWoEnt AS (
			SELECT TT.EWONO AS WOWN, * FROM tempWo WN
				OUTER APPLY (SELECT WONO EWONO FROM WOENTRY WHERE WN.WONO = WOENTRY.WONO) TT 
		)
		,tempTotalWoEnt AS (
			SELECT CASE WHEN @autoWO = 1 THEN WONOT ELSE WONOT END AS TEWONO, 
				*,0 As ISUPDATE FROM tempWoEnt 
			OUTER APPLY (SELECT MAX(WONOT) AS WON FROM tempWoEnt WHERE 1=0) TT
			WHERE ISNULL(WOWN,'') = ''
			UNION ALL
			SELECT CASE WHEN @autoWO = 1 THEN 
						RIGHT('0000000000'+ CONVERT(VARCHAR,TT.WON  + ROW_NUMBER() OVER (ORDER BY TT.WON )),10) 
				   ELSE 
						WOWN END AS TEWONO,*,0 As ISUPDATE 
			FROM tempWoEnt
			OUTER APPLY (SELECT MAX(WONOT) AS WON FROM tempWoEnt) TT
			WHERE ISNULL(WOWN,'') <> ''
		)
		SELECT * INTO #temp FROM tempTotalWoEnt
		
		IF(@@RowCount>0)
		BEGIN
			CREATE TABLE #FinalWorkOrders(WONO VARCHAR(10),UNIQ_KEY VARCHAR(10),OPENCLOS VARCHAR(10),JobType VARCHAR(10),
				ORDERDATE SMALLDATETIME, DUE_DATE SMALLDATETIME,[START_DATE] SMALLDATETIME,End_date SMALLDATETIME,BLDQTY INT,
				COMPLETE INT,BALANCE INT,CUSTNO VARCHAR(10), SONO VARCHAR(10), UNIQUELN VARCHAR(10), PRJUNIQUE VARCHAR(10),
				LFCSTITE VARCHAR(10), CreatedByUserId  UNIQUEIDENTIFIER, KitUniqWh  VARCHAR(10),KIT bit, RELEDATE SMALLDATETIME, 
				ReleasedBy UNIQUEIDENTIFIER, WONOTE VARCHAR(500), SERIALYES BIT, uniquerout VARCHAR(10),ISUpdate BIT)

			-- Insert WOEntry Records
			INSERT INTO #FinalWorkOrders 
			SELECT RIGHT('0000000000'+ CONVERT(VARCHAR,TEWONO),10) WONO,t.UNIQ_KEY UNIQ_KEY,'Open' OPENCLOS,TRIM(t.JobType) JobType
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
									DATEADD(DAY, i.PROD_LTIME, 
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
				   ,CASE WHEN LTRIM([End_date]) = '' THEN
				   		CAST(CAST((DATEADD(DAY, i.PROD_LTIME, CASE WHEN LTRIM(t.ORDERDATE) = '' THEN
								CAST(CAST(GETDATE() As date) AS VARCHAR(50))  
							ELSE 
								CAST(t.ORDERDATE AS VARCHAR(50))  
							END	)) As date) AS VARCHAR(50))  
				   	 WHEN (LTRIM([End_date]) <> '' AND ISDATE([End_date])=1) THEN
				   		CAST([End_date] AS VARCHAR(50)) 
				    END End_date
					
				,t.BLDQTY as BLDQTY,0 COMPLETE,t.BLDQTY as BALANCE,RIGHT('0000000000'+ CONVERT(VARCHAR,t.CUSTNO),10),t.SONO,
				ISNULL((
					SELECT TOP 1 UNIQUELN FROM SODETAIL WHERE SONO = RIGHT('0000000000'+ CONVERT(VARCHAR,t.SONO),10) 
						AND LINE_NO = RIGHT('0000000'+ CONVERT(VARCHAR,t.Line_no),7)
				),'') UNIQUELN,
				t.PRJUNIQUE,0 LFCSTITE, 
				   @userId CreatedByUserId,
				   ISNULL((select Top 1 UNIQWH FROM WAREHOUS WHERE Warehouse = t.Warehouse),'') KitUniqWh,
				   -- Fields based on fields on @autoRel settings
				   CASE WHEN @autoRel = 1 THEN 1 ELSE 0 END KIT,
				   CASE WHEN @autoRel = 1 THEN GETDATE() ELSE NULL END RELEDATE,
				   CASE WHEN @autoRel = 1 THEN @userId ELSE NULL END ReleasedBy,
				   '',
				   --t.WONOTE,
				   i.SERIALYES,
				   TRIM(ISNULL((SELECT Top 1 rp.uniquerout FROM routingProductSetup rp 
						INNER JOIN RoutingTemplate rt ON rp.TemplateID=rt.TemplateID
						WHERE TRIM(rt.TemplateName) = TRIM(RoutingName) 
						AND TRIM(rt.TemplateType) = CASE WHEN TRIM(t.JobType) LIKE 'Rework%' THEN 'Rework' ELSE 'Regular' END
						AND UNIQ_KEY= t.UNIQ_KEY)
				   ,'')) uniquerout,
				   ISUPDATE
			FROM #temp t
			JOIN INVENTOR i ON i.UNIQ_KEY = t.UNIQ_KEY
			
			INSERT INTO WOENTRY(WONO,UNIQ_KEY,OPENCLOS,JobType,ORDERDATE,DUE_DATE,[START_DATE],COMPLETEDT,
								BLDQTY,COMPLETE,BALANCE,CUSTNO,SONO,UNIQUELN,PRJUNIQUE,LFCSTITEM,
								CreatedByUserId,KitUniqWh,KIT,RELEDATE,ReleasedBy,WONOTE,SERIALYES,uniquerout)
			-- Satyawan H 11/11/2019: Add NULL value for CompleteDt when creating WO 
			SELECT WONO, UNIQ_KEY, OPENCLOS, JobType, ORDERDATE, DUE_DATE, [START_DATE], NULL, BLDQTY, COMPLETE, 
				   BALANCE, CUSTNO, SONO, UNIQUELN, PRJUNIQUE, LFCSTITE, CreatedByUserId, KitUniqWh, KIT, RELEDATE, 
				   ReleasedBy, WONOTE, SERIALYES, uniquerout
			FROM #FinalWorkOrders

			-- Insert into PROD_DTS for schedule planner
			DECLARE @totalWOCount INT, @tWONumber VARCHAR(10),@CompleteDT SMALLDATETIME,@StartDate SMALLDATETIME
			SET @totalWOCount =  (SELECT COUNT(DISTINCT WONO) FROM #FinalWorkOrders)	
			
			WHILE (@totalWOCount > 0)
			BEGIN 
				SELECT TOP 1 @tWONumber = WONO,@StartDate=[START_DATE],@CompleteDT= End_date
				FROM #FinalWorkOrders WHERE ISUPDATE = 0
				SET @totalWOCount = @totalWOCount -1;

				EXEC NewSchPlanningAdjustWOStart @tWONumber,@StartDate,@CompleteDT,@userId,1
				UPDATE #FinalWorkOrders SET ISUPDATE = 1 WHERE WONO =  @tWONumber 
			END	

			-- Update Last Created WONO
			IF(@autoWO=1) 
			BEGIN
			UPDATE wmSettingsManagement set settingValue=(SELECT MAX(WONO) FROM #FinalWorkOrders)
			WHERE settingId IN (SELECT settingId FROM MnxSettingsManagement WHERE settingName = 'LastWONO')
			END
		
			-- Insert Notes -- 
			-- Insert WmNotes For Work order	
			SELECT NewId() NoteID,WONOTE [Description],@userId fkCreatedUserID,GETDATE() CreatedDate,0 IsDeleted,'' NoteType,
				   RIGHT('0000000000'+ CONVERT(VARCHAR,TEWONO),10) RecordId,'WorkOrder' RecordType,2 NoteCategory,0 IsActionClose,0 CarNo,
				   0 IsFollowUpComplete,'' IssueType,NULL Importance,0 IsCustomerSupport,0 Progress,0 IsNewTask,NULL [Priority] 
				   INTO #WmNotes FROM #temp WHERE TRIM(WONOTE) <> ''
			
			INSERT INTO wmNotes(NoteID,[Description],fkCreatedUserID,CreatedDate,IsDeleted,NoteType,RecordId,RecordType,
								NoteCategory,IsActionClose,CarNo,IsFollowUpComplete,IssueType,Importance,IsCustomerSupport,
								Progress,IsNewTask,[Priority])
			SELECT * FROM #WmNotes

			---- Insert wmNoteRelationship For Work order Notes
			INSERT INTO wmNoteRelationship(NoteRelationshipId, FkNoteId, CreatedUserId, Note, CreatedDate, ImagePath, IsWhisper, ReplyNoteRelationshipId)
			SELECT NewId(),NoteID,@userId,[Description],CreatedDate,'',0,NULL FROM #WmNotes
		END
END