---- =============================================
---- Author:		Yelena Shmidt
---- Create date: 5/15/2015
---- Description:	separate validation for part type because it depands on the class 
---- update importBomFieldDefinitions set valueSql=' ' where fielddefid='2E9FB279-0788-E111-B197-1016C92052BC' to remove the parttype from
---- importBOMVldtnCheckValues
---- Vijay G: 02/02/2018 : Part type is not required field. So validation is not applied if the part type is not provided. Added the condition to check original and adjusted value is not empty.
---- Vijay G: 03/09/2018: Removed unwanted commente script.
---- 03/27/2018: Vijay G: Added the @importRowId parameter. While updating any specific row data then there is no need to update all other rows part type status. 
---- 01/31/2018: Vijay G: Fix the Issue the Part_Type are become green while importing data even user does't change any thing
---- =============================================
CREATE PROCEDURE [dbo].[importBOMVldtnPartTypeValues] 
	-- Add the parameters for the stored procedure here
	-- 03/27/2018: Vijay G: Added the @importRowId parameter.
	@importId uniqueidentifier,
	@importRowId UNIQUEIDENTIFIER = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 -- Insert statements for procedure here
    DECLARE @fdid uniqueidentifier, @rCount int, @adjusted varchar(MAX),@erMsg varchar(max),@rowid uniqueidentifier
    
    /* Declare status values to make it easier to update if we change the method in the future */
    DECLARE @white varchar(50)='i00white',@skip varchar(50)='i00skipped',@green varchar(50)='i01green',@blue varchar(50)='i03blue',@orange varchar(50)='i04orange',@red varchar(50)='i05red',
			@sys varchar(50)='01system',@usr varchar(10)='03user'
    
    /*	Get a list of field definitions to be processed with this sp and with a valueSQL set */
    DECLARE @parttypeFid uniqueidentifier,@mpartClassFid uniqueidentifier
    DECLARE @nBOM importBOM

    SELECT @mpartClassFid=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='partClass'
    SELECT @parttypeFid=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='partType'
 
 -- bring all records


	INSERT INTO @nBOM
	exec [sp_getImportBOMItems] @importId
	
	-- 03/27/2018: Vijay G: While updating any specific row data then there is no need to update all other rows part type status.
	-- Previously it was updating all rows part type status by green even if user updating single record.
	-- For part type status we are already updating status in dbo.importBOMRowUpdate SP
	---- 01/31/2018: Vijay G: Fix the Issue the Part_Type are become green while importing data even user does't change any thing
	IF @importRowId IS NOT Null
	BEGIN
		update importBOMFields
				SET [status] = @green,[validation] = @sys, [message] = ' '
				WHERE fkFieldDefId=@parttypeFid and fkImportId=@importId
				and exists (
			select 1 from @nbom n 
			INNER JOIN PARTTYPE ON PartType.Part_class=RTRIM(n.partclass) and PARTTYPE.Part_Type=RTRIM(n.parttype)
			--where cast(rtrim(partclass) as char(8))+cast(rtrim(parttype) as char(8)) IN (SELECT Part_class+part_type from parttype)
			and n.rowId=importBOMFields.rowId and n.rowId = @importRowId)
	END

	-- Vijay G: 02/02/2018 : Part type is not required field. So validation is not applied if the part type is not provided.
	-- Added the condition to check original and adjusted value is not empty.	
	UPDATE importBOMFields
			SET [status] = @red,[validation] = @sys, [message] = 'Incorrect Value'
			WHERE fkFieldDefId=@parttypeFid and fkImportId=@importId and original <> '' and adjusted <> ''
			and exists (
		select 1 from @nbom n
		where NOT EXISTS (Select 1 FROM PartType where PartType.PART_CLASS=rtrim(n.partclass) and parttype.PART_TYPE=rtrim(n.parttype))
		--cast(rtrim(partclass) as char(8))+cast(rtrim(parttype) as char(8)) NOT IN (SELECT Part_class+part_type from parttype)
		and n.rowId=importBOMFields.rowId)
		
	END