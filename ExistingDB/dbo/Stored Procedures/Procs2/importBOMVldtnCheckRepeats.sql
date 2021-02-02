-- =============================================
-- Author:		David Sharp
-- Create date: 01/26/2015
-- Description:	check import bom for duplicate parts with different part numbers
-- 02/19/15 YS added check for same partno differenct custpart
-- 05/12/15 YS remove '===== NEW =====' from validation for same partno different custpart
-- 05/14/15 YS remove empty custpartno when checking for duplicates
-- 10/03/16 YS when checking for duplicating cust part number for the same internal part number, need to concider the same part used twice on the BOM. 
-- same customer part numer as well. But the validation will return count of 2 
-- =============================================
CREATE PROCEDURE [dbo].[importBOMVldtnCheckRepeats]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/****** DUPLICATE PART NUMBER IN WC - ensure that the part number is not under two itemno but the same work center ******/	
	DECLARE @partnoId uniqueidentifier
    SELECT @partnoId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='partno'
	DECLARE @white varchar(20)='i00white',@lock varchar(20)='i00lock',@green varchar(20)='i01green',@blue varchar(20)='i03blue',@orange varchar(20)='i04orange',@red varchar(20)='i05red',
			@sys varchar(20)='01system',@usr varchar(20)='03user'
				
	DECLARE  @iTable importBom
	INSERT INTO @iTable
	EXEC [dbo].[sp_getImportBOMItems] @importId
	
	DECLARE @partRepeatedTbl TABLE (partno varchar(MAX))
	INSERT INTO @partRepeatedTbl	
	SELECT partno FROM @iTable GROUP BY partno,rev,workCenter HAVING COUNT(*)>1 AND partno<>'===== NEW ====='
	
	DECLARE @workCenterId uniqueidentifier
    SELECT @workCenterId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName='workCenter'
    
	UPDATE importBOMFields
		SET [status]=@red,[validation]=@sys,[message]='Part Number is used on more than one item number in the same work center'
		WHERE fkFieldDefId = @workCenterId AND rowId IN (SELECT rowId FROM importBOMFields WHERE fkFieldDefId=@partnoId AND adjusted IN (SELECT partno FROM @partRepeatedTbl))

	

	-- mark read internal part numbers
	-- 05/12/15 YS remove '===== NEW =====' from validation for same partno different custpart
	UPDATE importBOMFields
		SET [status]=@red,[validation]=@sys,[message]='Same internal part number cannot be associated with two different customer part numbers.'
		WHERE fkFieldDefId in(@partnoId) AND EXISTS  
		(select 1  
		from @iTable I 
		CROSS APPLY
		-- 05/14/15 YS remove empty custpartno when checking for duplicates
		-- 10/03/16 YS when checking for duplicating cust part number for the same internal part number, need to concider the same part used twice on the BOM. 
		-- same customer part numer as well. But the validation will return count of 2 
		( select partno,rev, count(distinct custpartno+crev) as n from @iTable where partno<>'===== NEW =====' and custpartno<>' ' group by partno,rev 
			having count(distinct custpartno+crev)>1 ) D
		where i.partno=d.partno and I.rev=D.rev and i.rowid=importBOMFields.RowId)

END