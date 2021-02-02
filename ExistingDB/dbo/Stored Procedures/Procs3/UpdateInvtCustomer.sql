-- =============================================  
-- Author:  Nitesh B  
-- Create date: 11/2/2018  
-- Description: Updated the Customer 
-- EXEC UpdateInvtCustomer 'd6660419-8706-4286-a688-40a967821354', 'General Boards Inc.', '0000000004'    
-- =============================================  
CREATE PROCEDURE [dbo].[UpdateInvtCustomer]   
 -- Add the parameters for the stored procedure here  
 @importId UNIQUEIDENTIFIER,       
 @custName nvarchar(50),
 @custNo nvarchar(10)      
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
SET NOCOUNT ON;  
  
DECLARE @Fieldid NVARCHAR(Max);  
DECLARE @TempTable TABLE (TRowId UNIQUEIDENTIFIER, isUpdate bit);
DECLARE @TempRowId UNIQUEIDENTIFIER, @PartNo CHAR(100), @Rev VARCHAR(100) , @CustPartno CHAR(100), @CustRev VARCHAR(100);

	UPDATE InvtImportHeader SET CompanyName = @custName, CompanyNo = @custNo where InvtImportId = @importId;  

	SELECT @Fieldid = FieldDefId FROM ImportFieldDefinitions WHERE FieldName = 'CompanyName' AND  Moduleid IN (SELECT ModuleId FROM MnxModule WHERE FilePath = 'InventoryUpload' AND ModuleDesc='MnxM_Upload');     
	UPDATE ImportInvtFields set Original=@custName,Adjusted=@custName,[Status]='i00white',[Validation]='',[Message]=''  WHERE FkFieldDefId=@Fieldid AND FkImportId= @importId;   

    INSERT INTO @TempTable (TRowId, isUpdate)
			SELECT DISTINCT RowId, 0 as isUpdate from ImportInvtFields where FkImportId = @importId

	    DECLARE @rowCount INT
		SELECT @rowCount = COUNT(TRowId) FROM @TempTable
	    WHILE(@rowCount > 0)
		BEGIN
			Select top 1 @TempRowId = TRowId from @TempTable where isUpdate = 0;

			Select @CustPartno = f.Adjusted from ImportInvtFields f join ImportFieldDefinitions d on f.FkFieldDefId = d.FieldDefId WHERE FieldName = 'custpartno' AND f.RowId = @TempRowId
			Select @CustRev = f.Adjusted from ImportInvtFields f join ImportFieldDefinitions d on f.FkFieldDefId = d.FieldDefId WHERE FieldName = 'custrev' AND f.RowId = @TempRowId

			--Select top 1 @PartNo = PART_NO, @Rev = REVISION from INVENTOR where CUSTNO = @custNo AND CUSTPARTNO = @CustPartno AND CUSTREV = @CustRev;
			
			UPDATE f SET f.Adjusted = 
			CASE 
				WHEN imf.FieldName = 'Part_no' AND invtPart.PART_NO IS NOT NULL THEN invtPart.PART_NO 
				WHEN imf.FieldName = 'revision' AND invtPart.REVISION IS NOT NULL THEN invtPart.REVISION
				WHEN imf.FieldName = 'descript' AND invtPart.DESCRIPT IS NOT NULL THEN invtPart.DESCRIPT 
				ELSE f.Adjusted END

			FROM ImportInvtFields f 
			JOIN InvtImportHeader i ON  f.FkImportId =  i.InvtImportId          
            JOIN importFieldDefinitions imf ON f.FkFieldDefId = imf.FieldDefId 
			OUTER APPLY 
			(
				SELECT TOP 1 PART_NO,REVISION,DESCRIPT FROM INVENTOR WHERE CUSTNO = @custNo AND CUSTPARTNO = @CustPartno AND CUSTREV = @CustRev
			)AS invtPart
			WHERE f.RowId = @TempRowId AND f.FkImportId= @importId AND (imf.FieldName = 'Part_no' OR imf.FieldName = 'revision');

			SET @rowCount = @rowCount -1;
			UPDATE @TempTable SET ISUPDATE = 1 WHERE TRowId =  @TempRowId       
		END
		DELETE FROM @TempTable;
END