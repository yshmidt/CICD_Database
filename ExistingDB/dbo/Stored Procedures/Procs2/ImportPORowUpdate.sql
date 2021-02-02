
-- =============================================
-- Author:		Satish B
-- Create date: 6/20/2018
-- Description:	Update PO Upload detail row
--Modified  22/11/2019 Shiv P : To update the S_ORD_QTY 
--Modified  01/16/2020 Shiv P : Add extra parameter to update warehouse base on validating part data  
--Modified  10/12/2020 Shiv P : Change @ordQty parameter datatype to numeric(10,2) 
-- =============================================

CREATE PROCEDURE [dbo].[ImportPORowUpdate]
	-- Add the parameters for the stored procedure here
		 @importId uniqueidentifier = NULL
		,@rowId uniqueidentifier = NULL
		,@uniqLnNo varchar(10) = ''
		,@itemNo varchar(10)=''
		,@poNote varchar(16)= ''
		,@terms varchar(15)= ''
		,@shipChargeFc varchar(8)= ''
		,@scTaxPct numeric
		,@lFrightAmt bit
		,@note1 nvarchar(max)= ''
		,@poItType varchar(9)= ''
		,@desc varchar(100)= ''
		,@package varchar(15)= ''
		,@costEachFc numeric
	    ,@partMfgr varchar(8)= ''
		,@mfgrPtNo varchar(30)= ''
		,@isFirm bit
		,@firstArticle bit
		,@inspexcept bit
		,@inspection varchar(20)= ''
		,@ordQty numeric(10,2) --Modified  10/12/2020 Shiv P : Change @ordQty parameter datatype to numeric(10,2) 
		--Modified  22/11/2019 Shiv P : To update the S_ORD_QTY 
		,@sOrdQty numeric = 0
		,@costEach numeric(10,7)
		,@partNo varchar(35)= ''
		,@rev varchar(8)= ''
		,@moduleId char(10) = ''
		,@taxable bit
		,@taxId varchar(35)= ''
		,@pur_uofm varchar(35)= ''
		,@PurLead numeric=''
		,@PurLeadUnit varchar(2)=''
		,@MinOrd numeric=''
		,@MultOrd numeric=''
		,@itemNote varchar(MAX)
  --Modified  01/16/2020 Shiv P : Add extra parameter to update warehouse base on validating part data     
  ,@Warehouse VARCHAR(MAX)  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @lFrightAmtId uniqueidentifier,@poNumId uniqueidentifier,@supNameId uniqueidentifier,@poNoteId uniqueidentifier,@termsId uniqueidentifier,@buyerId uniqueidentifier,
			@shipChargeFcId uniqueidentifier,@scTaxPctId uniqueidentifier,@shipChargeId uniqueidentifier,@fobId uniqueidentifier,@shipViaId uniqueidentifier,@note1Id uniqueidentifier,
			@poItTypeId uniqueidentifier,@descId uniqueidentifier,@packageId uniqueidentifier,@costEachFcId uniqueidentifier,@taxItemId uniqueidentifier,@partMfgrId uniqueidentifier,
			@mfgrPtNoId uniqueidentifier,@isFirmId uniqueidentifier,@firstArticleId uniqueidentifier,@inspexceptId uniqueidentifier,@inspectionId uniqueidentifier,@schdDateId uniqueidentifier,
			@reqDateId uniqueidentifier,@origCommitId uniqueidentifier,@schdQtyId uniqueidentifier,@locationId uniqueidentifier,@wonoId uniqueidentifier,@requestorId uniqueidentifier,
			@glnbrId uniqueidentifier,@priorityId uniqueidentifier,@confToId uniqueidentifier,@ordQtyId uniqueidentifier,
			--Modified  22/11/2019 Shiv P : To update the S_ORD_QTY 
			@sOrdQtyId uniqueidentifier,@costEachId uniqueidentifier,@itemNoId uniqueidentifier,
			@partNoId uniqueidentifier,@revId uniqueidentifier,@warehouseId uniqueidentifier,@taxableId uniqueidentifier,@taxIdId uniqueidentifier,@pur_uofmId uniqueidentifier
			,@PurLeadId uniqueidentifier,@PurLeadUnitId uniqueidentifier,@MinOrdId uniqueidentifier,@MultOrdId uniqueidentifier,
			@itemNoteId uniqueidentifier, @itemTypeId uniqueidentifier
	
	DECLARE @green varchar(10)='i01green',@sys varchar(10)='01system',@user varchar(10)='03user'
	
	--Get ID values for each field type	
	SELECT @poNoteId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'PONOTE'		    AND ModuleId=@moduleId		
	SELECT @termsId			=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'TERMS'			AND ModuleId=@moduleId
	SELECT @shipChargeFcId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'SHIPCHGFC'		AND ModuleId=@moduleId
	SELECT @scTaxPctId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'SCTAXPCT'		AND ModuleId=@moduleId
	SELECT @shipChargeId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'SHIPCHARGE'		AND ModuleId=@moduleId
	SELECT @fobId			=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'FOB'				AND ModuleId=@moduleId
	SELECT @shipViaId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'SHIPVIA'			AND ModuleId=@moduleId
	SELECT @lFrightAmtId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'LFREIGHTINCLUDE'	AND ModuleId=@moduleId
	SELECT @note1Id			=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'INSPEXNOTE'		AND ModuleId=@moduleId
	SELECT @itemNoId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'ITEMNO'			AND ModuleId=@moduleId
	SELECT @poItTypeId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'POITTYPE'		AND ModuleId=@moduleId
	SELECT @partNoId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'PARTNO'			AND ModuleId=@moduleId
	SELECT @revId			=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'REVISION'		AND ModuleId=@moduleId
	SELECT @descId			=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'DESCRIPT'		AND ModuleId=@moduleId
	SELECT @packageId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'PACKAGE'			AND ModuleId=@moduleId
	SELECT @costEachFcId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'COSTEACHFC'		AND ModuleId=@moduleId
	SELECT @partMfgrId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'PARTMFGR'		AND ModuleId=@moduleId
	SELECT @mfgrPtNoId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'MFGR_PT_NO'		AND ModuleId=@moduleId
	SELECT @isFirmId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'ISFIRM'			AND ModuleId=@moduleId
	SELECT @firstArticleId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'FIRSTARTICLE'	AND ModuleId=@moduleId
	SELECT @inspexceptId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'INSPEXCEPT'		AND ModuleId=@moduleId
	SELECT @inspectionId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'INSPEXCEPTION'	AND ModuleId=@moduleId
	SELECT @ordQtyId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'ORD_QTY'			AND ModuleId=@moduleId
	--Modified  22/11/2019 Shiv P : To update the S_ORD_QTY 
	SELECT @sOrdQtyId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'S_ORD_QTY'		AND ModuleId=@moduleId
	SELECT @costEachId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'COSTEACH'		AND ModuleId=@moduleId
	SELECT @taxableId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'TAXABLE'			AND ModuleId=@moduleId
	SELECT @taxIdId			=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'TAXID'			AND ModuleId=@moduleId
	SELECT @pur_uofmId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'PUR_UOFM'		AND ModuleId=@moduleId

	SELECT @PurLeadId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'PUR_LTIME'		AND ModuleId=@moduleId
	SELECT @PurLeadUnitId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'PUR_LUNIT'		AND ModuleId=@moduleId
	SELECT @MinOrdId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'MINORD'			AND ModuleId=@moduleId
	SELECT @MultOrdId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'ORDMULT'			AND ModuleId=@moduleId
	SELECT @itemNoteId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'ITEMNOTE'		AND ModuleId=@moduleId
	SELECT @itemTypeId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'POITTYPE'		AND ModuleId=@moduleId
 --Modified  01/16/2020 Shiv P : Add extra parameter to update warehouse base on validating part data     
 SELECT @warehouseId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'WAREHOUSE' AND ModuleId=@moduleId        


    
	--Update fields with new values
	UPDATE ImportPODetails SET adjusted = @poNote,[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @poNoteId AND rowId = @rowId AND adjusted<>@poNote
	UPDATE ImportPODetails SET adjusted = @terms,[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @termsId AND rowId = @rowId AND adjusted<>@terms
	UPDATE ImportPODetails SET adjusted = @shipChargeFc,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @shipChargeFcId AND rowId = @rowId AND adjusted<>@shipChargeFc
	UPDATE ImportPODetails SET adjusted = cast(@scTaxPct AS nvarchar(15)),[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @scTaxPctId AND rowId = @rowId AND adjusted<>cast(@scTaxPct AS nvarchar(15))
	UPDATE ImportPODetails SET adjusted = cast(@lFrightAmt AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @lFrightAmtId AND rowId = @rowId AND adjusted<>cast(@lFrightAmt AS nvarchar(10))
	UPDATE ImportPODetails SET adjusted = @note1,[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @note1Id AND rowId = @rowId AND adjusted<>@note1
	UPDATE ImportPODetails SET adjusted = @package,[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @packageId AND rowId = @rowId AND adjusted<>@package
	UPDATE ImportPODetails SET adjusted = cast(@costEachFc AS nvarchar(15)),[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @costEachFcId AND rowId = @rowId AND adjusted<>cast(@costEachFc AS nvarchar(15))
	UPDATE ImportPODetails SET adjusted = @poItType,[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @poItTypeId AND rowId = @rowId AND adjusted<>@poItType
	UPDATE ImportPODetails SET adjusted = @partNo,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @partNoId AND rowId = @rowId AND adjusted<>@partNo
	UPDATE ImportPODetails SET adjusted = @rev,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @revId AND rowId = @rowId 
	UPDATE ImportPODetails SET adjusted = @desc,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @descId AND rowId = @rowId
	UPDATE ImportPODetails SET adjusted = @partMfgr,[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @partMfgrId AND rowId = @rowId --AND adjusted<>@partMfgr
	UPDATE ImportPODetails SET adjusted = @mfgrPtNo,[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @mfgrPtNoId AND rowId = @rowId-- AND adjusted<>@mfgrPtNo
	UPDATE ImportPODetails SET adjusted = cast(@isFirm AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	 	WHERE fkFieldDefId = @isFirmId AND rowId = @rowId AND adjusted<>cast(@isFirm AS nvarchar(10))
	UPDATE ImportPODetails SET adjusted = cast(@firstArticle AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @firstArticleId AND rowId = @rowId AND adjusted<>cast(@firstArticle AS nvarchar(10))
	UPDATE ImportPODetails SET adjusted = cast(@inspexcept AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @inspexceptId AND rowId = @rowId AND adjusted<>cast(@inspexcept AS nvarchar(10))
	UPDATE ImportPODetails SET adjusted = @inspection,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @inspectionId AND rowId = @rowId AND adjusted<>@inspection
	UPDATE ImportPODetails SET adjusted = cast(@ordQty AS nvarchar(15)),[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @ordQtyId AND rowId = @rowId AND adjusted<>cast(@ordQty AS nvarchar(15))
	--Modified  22/11/2019 Shiv P : To update the S_ORD_QTY 
	IF Exists ( SELECT Adjusted FROM ImportPODetails WHERE fkFieldDefId= @itemTypeId AND ImportPODetails.Adjusted ='Invt Part' )
	UPDATE ImportPODetails SET adjusted =  cast( ISNULL(@sOrdQty,0) AS nvarchar(15)),[status]='',[validation]=@user,[message]=''		
	WHERE fkFieldDefId = @sOrdQtyId AND rowId = @rowId AND adjusted<>cast(ISNULL(@sOrdQty,0) AS nvarchar(15))
	UPDATE ImportPODetails SET adjusted = @costEach,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @costEachId AND rowId = @rowId AND adjusted<>cast(@costEach AS nvarchar(15))
	UPDATE ImportPODetails SET adjusted = cast(@taxable AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @taxableId AND rowId = @rowId AND adjusted<>cast(@taxable AS nvarchar(10))
	UPDATE ImportPODetails SET adjusted = @taxId,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @taxIdId AND rowId = @rowId AND adjusted<>@taxId
	UPDATE ImportPOTax SET adjusted = @taxId,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @taxIdId AND fkRowId = @rowId AND adjusted<>@taxId
	UPDATE ImportPODetails SET adjusted = @pur_uofm,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @pur_uofmId AND rowId = @rowId AND adjusted<>@pur_uofm
	UPDATE ImportPODetails SET adjusted = @PurLead,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @PurLeadId AND rowId = @rowId AND adjusted<>@PurLead
	UPDATE ImportPODetails SET adjusted = @PurLeadUnit,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @PurLeadUnitId AND rowId = @rowId AND adjusted<>@PurLeadUnit
	UPDATE ImportPODetails SET adjusted = @MinOrd,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @MinOrdId AND rowId = @rowId AND adjusted<>@MinOrd
	UPDATE ImportPODetails SET adjusted = @MultOrd,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @MultOrdId AND rowId = @rowId AND adjusted<>@MultOrd
	UPDATE ImportPODetails SET adjusted = @itemNote,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @itemNoteId AND rowId = @rowId AND adjusted<>@itemNote
	UPDATE ImportPODetails SET adjusted = @itemNo,[status]='',[validation]=@user,[message]=''			WHERE fkFieldDefId = @itemNoId AND rowId = @rowId AND adjusted<>@itemNo
 --Modified  01/16/2020 Shiv P : Add extra parameter to update warehouse base on validating part data     
 UPDATE ImportPOSchedule SET adjusted = @Warehouse,[status]='',[validation]=@user,[message]='' WHERE fkFieldDefId = @warehouseId AND FkRowId = @rowId  AND adjusted=''       

	--Recheck Validations
	EXEC ImportPOVldtnCheckValues @importId
END