 -- ============================================================================================================  
-- Date   : 08/28/2019  
-- Author  : Rajendra K 
-- Description : Used to add new bill of materials, Add Reference designator and insert BOM item notes 
-- Rajendra K 09/28/2019 : Change for Ref designator 
-- Rajendra K 09/30/2019 : Added condition for NULL or Empty avls
-- Rajendra K 10/04/2019 : Changed the Condition
-- Rajendra K 10/24/2019 : Added the @AUniqKey table and condition to take Avls,which will skip AVLS While inserting AnitAVLS entry
-- 12/26/2019 Rajendra k  : Added useipkey and serialyes in @MfgrDetails table
-- AddBillOfMaterial 'A8E52947-E1E5-435A-A72A-B2AD54E83964','49F80792-E15E-4B62-B720-21B360E3108A'
-- ============================================================================================================    
CREATE PROC AddBillOfMaterial
 @importId UNIQUEIDENTIFIER,
 @userId UNIQUEIDENTIFIER=null
 AS  
BEGIN    
 SET NOCOUNT ON; 
   DECLARE @Bomparent CHAR(10),@item_no NUMERIC(4,0);
   DECLARE @BomDetails TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),itemno NUMERIC
							,partSource  VARCHAR(100),partno  VARCHAR(100),rev  VARCHAR(100),custPartNo  VARCHAR(100),crev  VARCHAR(100),qty NUMERIC,bomNote  VARCHAR(MAX)
							,workCenter VARCHAR(100),used BIT,UNIQ_KEY VARCHAR(100),PART_CLASS VARCHAR(100),PART_TYPE VARCHAR(100),U_OF_MEAS VARCHAR(100),IsLotted BIT,useipkey BIT,SERIALYES BIT) 	

	DECLARE @BomDet Table (CompRowId UNIQUEIDENTIFIER,bomparent CHAR(10),uniqbomno CHAR(10),uniq_key CHAR(10),Qty NUMERIC(9,2),Item_no NUMERIC(4,0)
							,Used_inkit CHAR(1),dept_id CHAR(4),Item_note VARCHAR(MAX),ItemNum NUMERIC(4,0)) 
							   
	DECLARE @Bom Table (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),assyDesc VARCHAR(100)
							 ,assyNum VARCHAR(100),assypartclass VARCHAR(100),assyparttype VARCHAR(100),assyRev VARCHAR(100),custno VARCHAR(100),UNIQ_KEY VARCHAR(10));  

	DECLARE @BomRef Table (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId UNIQUEIDENTIFIER ,RefDesRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100)
							,Validation VARCHAR(100),refdesg VARCHAR(100),Nbr NUMERIC(4,0));

	DECLARE @MfgrDetails TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId	UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),
							Validation VARCHAR(100),partMfg	VARCHAR(100), mpn VARCHAR(100),Warehouse VARCHAR(100),Location VARCHAR(100),ResQty	VARCHAR(100),UNIQ_KEY VARCHAR(100),
							partno	VARCHAR(100),rev VARCHAR(100),custPartNo VARCHAR(100),crev VARCHAR(100),IsLotted BIT,WorkCenter VARCHAR(100),useipkey BIT,SERIALYES BIT)
							-- 12/26/2019 Rajendra k  : Added useipkey and serialyes in @MfgrDetails table
	DECLARE @AntiAvls Table (mfgrmasteridd CHAR(10),UNIQ_KEY CHAR(10),partmfgr CHAR(8),mfgr_pt_no CHAR(30));
	DECLARE @AUniqKey Table (uniq_key CHAR(10));-- Rajendra K 10/24/2019 : Added the @AUniqKey table and condition to take Avls,which will skip AVLS While inserting AnitAVLS entry

	INSERT INTO @BomDetails EXEC GetComponentsData @importId
	INSERT INTO @Bom EXEC GetAssemblyRecords @importId
	INSERT INTO @BomRef EXEC GetRefDesignatorUploadData @importId
	INSERT INTO @MfgrDetails EXEC GetManufactureUploadData @importId;		
	SELECT TOP 1 @Bomparent= UNIQ_KEY FROM @Bom

	--SELECT * FROM @BomDetails
	--SELECT * FROM @Bom
	--SELECT * FROM @BomRef
	--SELECT * FROM @MfgrDetails

	IF (@Bomparent <>'')
	BEGIN
		BEGIN TRY    
		BEGIN TRANSACTION  	
			 IF EXISTS(SELECT 1 FROM BOM_DET WHERE BOMPARENT = @Bomparent)
			 BEGIN		  			  
			 	  IF EXISTS(SELECT * FROM wmNotes WHERE RecordType='BOM_DET' AND RecordId IN (SELECT UNIQBOMNO FROM BOM_DET WHERE UNIQ_KEY = @Bomparent))  
			 	  BEGIN  
			 	  DELETE FROM wmNoteRelationship   
			 	  WHERE FkNoteId IN (SELECT NoteID FROM wmNotes WHERE RecordType='BOM_DET' AND RecordId IN (SELECT UNIQBOMNO FROM BOM_DET WHERE UNIQ_KEY = @Bomparent))  
			 	  
			 	  DELETE FROM wmNotes   
			 	  WHERE NoteID IN (SELECT NoteID FROM wmNotes WHERE RecordType='BOM_DET' AND RecordId IN (SELECT UNIQBOMNO FROM BOM_DET WHERE UNIQ_KEY = @Bomparent))  
			 	  END  
			 	  
			 	  DELETE FROM BOM_REF WHERE UNIQBOMNO IN (SELECT UNIQBOMNO FROM BOM_DET WHERE BOMPARENT = @Bomparent)    
			 	  DELETE FROM BOM_ALT WHERE BOMPARENT = @Bomparent    
			 	  DELETE FROM BOM_DET WHERE BOMPARENT = @Bomparent    
			 	  DELETE FROM AntiAvl WHERE BOMPARENT = @Bomparent    
			 END			
			 
			 IF EXISTS(SELECT 1 FROM @BomDetails)
			 BEGIN
				--Auto-generate Itemno 
				 SELECT @item_no = MAX(itemno) FROM @BomDetails
				 ;with data As(
				 select itemno+@item_no+ROW_NUMBER() over(order by itemno asc) as itemno,CompRowId
				 from @BomDetails where itemno =0
				 )					
				UPDATE bd SET bd.itemno = d.itemno 
				FROM @BomDetails bd
				INNER JOIN data d on bd.CompRowId = d.CompRowId 

			 	INSERT INTO @BomDet (CompRowId,bomparent,uniqbomno,uniq_key,Qty,Item_no,Used_inKit,Dept_id,Item_note)       
			 	SELECT CompRowId,@Bomparent,dbo.fn_GenerateUniqueNumber(),uniq_key,Qty,itemno,CASE WHEN used = 0 THEN 'N' ELSE 'Y' END,workCenter,bomNote 
				FROM @BomDetails   
				
			 END
			 
			 IF (EXISTS (SELECT 1 FROM @BomDet))      
			 BEGIN    
				 INSERT INTO BOM_DET (bomparent,uniqbomno,uniq_key,Qty,Item_no,Used_inKit,Dept_id,ModifiedBy)       
			 	 SELECT bomparent,uniqbomno,uniq_key,Qty,Item_no,Used_inKit,
				 CASE WHEN Dept_id IS NULL OR Dept_id = '' THEN 'STAG' ELSE UPPER (Dept_id) END,@userId 
				 FROM @BomDet  				 
			 
			 	IF (EXISTS(SELECT 1 FROM @BomRef))    
			 	BEGIN    
			 		 INSERT INTO BOM_REF(uniqbomno,REF_DES,NBR,UNIQUEREF,IsSynchronizedFlag)      -- Rajendra K 09/28/2019 : Change for Ref designator 
			 		 SELECT uniqbomno,refdesg,Nbr,dbo.fn_GenerateUniqueNumber(),0 FROM @BomDet b JOIN @BomRef r on b.CompRowId = r.CompRowId WHERE refdesg <> ''
			 	END
			 	
			 	 --WmNote and WmNoteRelationship note insert
			 	 --Insert WmNotes For BOM item notes	
			 	SELECT NewId() NoteID,Item_note AS [Description],@userId fkCreatedUserID,GETDATE() CreatedDate,0 IsDeleted,'' NoteType,
			 			   	  uniqbomno AS RecordId,'BOM_DET' RecordType,2 NoteCategory,0 IsActionClose,0 CarNo,
			 				  0 IsFollowUpComplete,'' IssueType,NULL Importance,0 IsCustomerSupport,0 Progress,0 IsNewTask,NULL [Priority] INTO #WmNotes FROM @BomDet
							  WHERE Item_note <>''
			 
			 	INSERT INTO wmNotes(NoteID,[Description],fkCreatedUserID,CreatedDate,IsDeleted,NoteType,RecordId,RecordType,
			 					NoteCategory,IsActionClose,CarNo,IsFollowUpComplete,IssueType,Importance,IsCustomerSupport,
			 					Progress,IsNewTask,[Priority])
			 	SELECT * FROM #WmNotes WHERE Description <> ''
			 
			 	-- Insert wmNoteRelationship For BOM item notes 
			 	INSERT INTO wmNoteRelationship(NoteRelationshipId, FkNoteId, CreatedUserId, Note, CreatedDate, ImagePath, IsWhisper, ReplyNoteRelationshipId)
			 	SELECT NewId(),NoteID,@userId,[Description],CreatedDate,'',0,NULL FROM #WmNotes  WHERE Description <> ''
			 END
			  
			  --To insert Antiavls 
			  -- Rajendra K 10/24/2019 : Added the @AUniqKey table and condition to take Avls,which will skip AVLS While inserting AnitAVLS entry
				INSERT INTO @AUniqKey
				SELECT UNIQ_KEY 
				FROM  @MfgrDetails md
				OUTER APPLY
				(
					SELECT mfM.PartMfgr,mfM.mfgr_pt_no FROM InvtMPNLink mpn     
					INNER JOIN  MfgrMaster mfM ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
					WHERE (TRIM(mfM.PartMfgr) = TRIM(md.partMfg) AND TRIM(mfM.mfgr_pt_no) = TRIM(md.mpn) and md.UNIQ_KEY=mpn.uniq_key)
				) AS manufact
				WHERE (manufact.mfgr_pt_no  IS NULL OR manufact.mfgr_pt_no = '')

				INSERT INTO @AntiAvls 
				SELECT DISTINCT mfM.MfgrMasterId, md.UNIQ_KEY,TRIM(PartMfgr) partmfgr,TRIM(mfgr_pt_no) mpn
				FROM  @MfgrDetails md
				LEFT JOIN  InvtMPNLink mpn ON mpn.uniq_key = md.UNIQ_KEY    
				LEFT JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0 
				EXCEPT				
				SELECT mfM.MfgrMasterId as mfgrmasteridd,  md.UNIQ_KEY,TRIM(PartMfgr) AS partmfgr,TRIM(mfgr_pt_no) AS mpn
				FROM  @MfgrDetails md
				INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = md.UNIQ_KEY    
				INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
				WHERE (TRIM(mfM.PartMfgr) = TRIM(md.partMfg) AND TRIM(mfM.mfgr_pt_no) = TRIM(md.mpn) and md.UNIQ_KEY=mpn.uniq_key)
				 
				-- Insert into antiavl table 
			 IF (EXISTS (SELECT 1 FROM @BomDet))      
			 BEGIN  
				INSERT INTO ANTIAVL (Bomparent ,uniq_key ,partmfgr ,mfgr_pt_no ,uniqanti) 
				SELECT @Bomparent,UNIQ_KEY,partmfgr,mfgr_pt_no,dbo.fn_GenerateUniqueNumber()  -- Rajendra K 09/30/2019 : Added condition for NULL or Empty avls
				FROM @AntiAvls
				WHERE ((partmfgr IS NOT NULL OR mfgr_pt_no  IS NOT NULL) OR (partmfgr <> '' AND mfgr_pt_no <> ''))-- Rajendra K 10/04/2019 : Changed the Condition
				 AND UNIQ_KEY NOT IN (SELECT UNIQ_KEY FROM @AUniqKey)-- Rajendra K 10/23/2019 : Added the @AUniqKey table and condition to take Avls,which will skip AVLS While inserting AnitAVLS entry
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
END
