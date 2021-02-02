-- =============================================
-- Author:Sachin B
-- Create date:01/20/2018 
-- Description:	This procedure will update WO Routing Template and WO Routing
-- [WORoutingTemplateUpdate] '0000000657','_1LR0NALBN','S6ZPDNZJQJ'
-- Modification:
-- 02/02/2018 Sachin B Update WoCheckList,WOTools,WOEquipments Info According to selection of new template
-- 03/08/2018 Sachin B : Add IsAssemblyAdded flag value true in WoCheckList,WOTools and WOEquipments table
-- =============================================
CREATE PROCEDURE [dbo].[WORoutingTemplateUpdate]              
(                            
 @wono CHAR(10),
 @uniqKey CHAR(10),                           
 @newUniquerout CHAR(10)            
) 

AS              
BEGIN              
       
SET NOCOUNT ON;
                            
BEGIN TRY                  
	BEGIN TRANSACTION 

		DECLARE @errorMessage NVARCHAR(4000),@errorSeverity INT,@errorState INT, -- declare variable to catch an error			
		@lcUniq_keyChk char(10),@lnTotalNo INT,@lnCount INT,@dept_id CHAR(4),@number NUMERIC(4,0),@deptKey CHAR(10),@serialStrt BIT,@currQty NUMERIC(7,0),
		@currDeptKey CHAR(10),@templateId INT

		SELECT @lcUniq_keyChk = Uniq_key FROM Inventor WHERE Uniq_key = @uniqKey 
		IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('Inventory record for this work order does not exist.  The updating shop floor traveler process can not continue to update.  This operation will be cancelled.',1,1)
		END

		--Temp Table for the Routing info according new routing
		DECLARE @quotDept TABLE (nrecno INT IDENTITY, Dept_id CHAR(4), Number NUMERIC(4,0), Uniqnumber CHAR(10), SerialStrt BIT,CURR_QTY NUMERIC(7,0));		
		
		INSERT @quotDept
		SELECT Dept_id, Number, Uniqnumber, SerialStrt,0 FROM QuotDept
		WHERE Uniq_key = @uniqKey AND uniqueRout =@newUniquerout ORDER BY Number

		--Table for get WO Old Routing Info
		DECLARE @dept_Qty TABLE(id INT IDENTITY,Dept_id CHAR(4),wono CHAR(10),CURR_QTY NUMERIC(7,0), Number NUMERIC(4,0),deptKey CHAR(10), SerialStrt BIT,uniquerec CHAR(10));

		INSERT @dept_Qty
		SELECT DEPT_ID,WONO,CURR_QTY,NUMBER,DEPTKEY,SERIALSTRT,UNIQUEREC FROM DEPT_QTY 
		WHERE WONO = @wono ORDER BY Number

		SET @lnTotalNo = @@ROWCOUNT;
		IF (@lnTotalNo>0)
		BEGIN
			   SET @lnCount=0;
			    WHILE @lnTotalNo>@lnCount
				BEGIN
					   SET @lnCount=@lnCount+1;
					   SELECT @dept_id = Dept_id, @number = Number, @deptKey = deptKey, @serialStrt = SerialStrt,@currQty =CURR_QTY
					   FROM @dept_Qty WHERE id = @lnCount
					   IF (@@ROWCOUNT<>0)
					   BEGIN
							IF @dept_id = 'STAG' OR @dept_id = 'SCRP' OR @dept_id = 'RWRK' OR @dept_id = 'RWQC'
							BEGIN
								--Update Current Qty the Current QuotDept temp table
								UPDATE @quotDept SET CURR_QTY = CURR_QTY + @currQty WHERE Dept_id = @dept_id

								--Get @currDeptKey from @quotDept table and Update InvtSer table ID_Value
								Set @currDeptKey = (SELECT Uniqnumber FROM @quotDept WHERE Dept_id = @dept_id)
								UPDATE InvtSer SET ID_Value = @currDeptKey, ActvKey = '' WHERE Wono = @wono AND Id_Key = 'DEPTKEY' AND ID_Value = @deptKey
							END
							IF @dept_id = 'FGI'
							BEGIN
								UPDATE @quotDept SET CURR_QTY = CURR_QTY + @currQty WHERE Dept_id = @dept_id
							END
							IF (@dept_id <> 'FGI' AND @dept_id <> 'STAG' AND @dept_id <> 'SCRP' AND @dept_id <> 'RWRK' AND @dept_id <> 'RWQC')
							BEGIN
								UPDATE @quotDept SET CURR_QTY = CURR_QTY + @currQty WHERE Dept_id = 'STAG'
								Set @currDeptKey = (SELECT Uniqnumber FROM @quotDept WHERE Dept_id = 'STAG')
								UPDATE InvtSer SET ID_Value = @currDeptKey, ActvKey = '' WHERE Wono = @wono AND Id_Key = 'DEPTKEY' AND ID_Value = @deptKey
							END
				       END
			       END
			END

	--Delete the new data from woentry table
	DELETE FROM DEPT_QTY WHERE WONO =@wono

	--Insert new routing info in dept_qty table
	INSERT INTO Dept_qty (Wono, Dept_id, Number, Curr_qty, Deptkey, SerialStrt, UniqueRec)
	SELECT @wono,Dept_id,Number,CURR_QTY,Uniqnumber,SerialStrt,dbo.fn_GenerateUniqueNumber() FROM @quotDept

	--update uniquerout column in wonentry table
	UPDATE WOENTRY SET uniquerout =@newUniquerout WHERE WONO = @wono

    --Getting new templateid
	SELECT @templateId = TemplateId  FROM routingProductSetup WHERE Uniq_key =@uniqKey AND uniquerout =@newUniquerout

	--Code for the Delete old Records of WoCheckList,WOToolsWOEquipments and insert new data according to the Assembly linked new templates
	
	-- 03/08/2018 Sachin B : Add IsAssemblyAdded flag value true in WoCheckList,WOTools and WOEquipments table
	-- WoCheckList Data
	--Delete old checklist
	DELETE FROM WoCheckList WHERE Wono = @wono

	--Insert new checklist according to the selection of new templates default data
	INSERT INTO WoCheckList(Dept_ID, Wono,[Description],UniqueNumber, TemplateId, WOCheckPriority,IsAssemblyAdded)
	SELECT Dept_activ,@wono,Chklst_tit,UNIQNUMBER,@templateId,wccheckpriority,1 FROM WRKCKLST WHERE Uniq_key =@uniqKey AND TemplateId =@templateId 

	-- WOTools Data
	--Delete old wotools
	DELETE FROM WOTools WHERE Wono = @wono

	--Insert new tools info according to the selection of new templates default data
	INSERT INTO WOTools(Dept_Id,WONO,[Description],UniqueNumber,TemplateId, WOToolPriority,ToolsAndFixtureId,IsAssemblyAdded)  
	SELECT t.DEPT_ID,@wono,tf.[Description],UNIQNUMBER,TemplateId,tf.ToolsFixturePriority,tf.ToolsAndFixtureId,1
    FROM TOOLING t 
	INNER JOIN ToolsAndFixtures tf ON t.ToolsAndFixtureId =tf.ToolsAndFixtureId
	WHERE t.UNIQ_KEY=@uniqKey AND t.TemplateId =@templateId 

	-- WOTools Data
	--Delete old equipments
	DELETE FROM WOEquipments WHERE Wono = @wono

	--Insert new equipments info according to the selection of new templates default data
	INSERT INTO WOEquipments(Dept_Id,WONO,[Description],UniqueNumber,TemplateId,WOEquipmentPriority,WcEquipmentId,IsAssemblyAdded)
	SELECT e.DEPT_ID,@wono,wc.Equipment,UNIQNUMBER,TemplateId,wc.EquipmentPriority,wc.WcEquipmentId,1
    FROM Equipment e 
	INNER JOIN WcEquipment wc ON e.WcEquipmentId =wc.WcEquipmentId 
    WHERE e.UNIQ_KEY=@uniqKey AND e.TemplateId =@templateId

	COMMIT TRANSACTION              
              
END TRY      
      
BEGIN CATCH                          
	IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION;      
	    SELECT @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE();
		RAISERROR 
		(	@ErrorMessage, -- Message text.
			 @ErrorSeverity, -- Severity.
			 @ErrorState -- State.
        );
                    
END CATCH                       
END