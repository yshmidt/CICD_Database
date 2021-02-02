---- =============================================
---- Author: Vijay G
---- Create date: 04/25/2018
---- Description: Update the UseCustPFX column value in importbomfields table depending up on UseCustPFX value from parttype table with respect to class,type provided in template.
---- =============================================
CREATE PROCEDURE [dbo].[importBOMUseCustPFXUpdate] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		    
    -- Declare importBOM temp table
	DECLARE @nBOM importBOM, @custPFX VARCHAR(4)=''

	-- Get tempalte import bom data in to the temp table
	INSERT INTO @nBOM
	EXEC [sp_getImportBOMItems] @importId

	-- 04/25/2018: Vijay G: Get the customer prefix depending upon the customer associated with current imported bom.
	SELECT @custPFX = ISNULL(CUSTPFX,'') FROM CUSTOMER WHERE CUSTNO =(SELECT CUSTNO FROM importBOMHeader WHERE importId=@importId)

	--04/25/2018: Update the UseCustPFX as per customer prefix if exist and the provided part class and type use cust prefix must be true
	If (@custPFX IS NOT NULL AND @custPFX <> '' AND Exists(SELECT 1 FROM @nbom n INNER JOIN PARTTYPE ON PartType.Part_class=RTRIM(n.partclass) AND PARTTYPE.Part_Type=RTRIM(n.parttype)
	WHERE n.importId=@importId AND PARTTYPE.UseCustPFX=1))
	BEGIN
		UPDATE importBOMFields SET UseCustPFX=1 WHERE fkImportId=@importId and rowId IN(
			SELECT n.rowId FROM @nbom n INNER JOIN PARTTYPE ON PartType.Part_class=RTRIM(n.partclass) AND PARTTYPE.Part_Type=RTRIM(n.parttype)
			WHERE n.importId=@importId AND PARTTYPE.UseCustPFX=1)
	END
END