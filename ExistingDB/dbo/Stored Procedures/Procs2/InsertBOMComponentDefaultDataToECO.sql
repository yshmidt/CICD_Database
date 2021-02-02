-- =============================================
-- Author:Sachin B
-- Create date: 08/16/2018
-- Description:	this procedure will be called from the ECO module and Insert BOM Alt Parts,Ref Des,and Anti AVL Data to ECO When ECO Created for BOM Components
-- InsertBOMComponentDefaultDataToECO
-- =============================================

CREATE PROCEDURE InsertBOMComponentDefaultDataToECO
@uniqBOMNo CHAR(10),
@bomParent CHAR(10),
@uniqKey CHAR(10),
@uniqECNo CHAR(10),
@uniqECDet CHAR(10)

AS
BEGIN

SET NOCOUNT ON; 

DECLARE @ErrorMessage NVARCHAR(4000);
DECLARE @ErrorSeverity INT;
DECLARE @ErrorState INT;

BEGIN TRY

	BEGIN TRANSACTION
	-- insert BOM Ref Des data to ECO Ref Des
	INSERT INTO ECREFDES(UNIQBOMNO,REF_DES,NBR,UNIQECDET,UNIQECRFNO,UNIQECNO)
	SELECT UNIQBOMNO,REF_DES,NBR,@uniqECDet,dbo.fn_GenerateUniqueNumber(),@uniqECNo FROM Bom_ref WHERE UNIQBOMNO =@uniqBOMNo

	--Insert BOM Alt parts data to ECO Alt Parts
	INSERT INTO ECAlternateParts(ECAltPartUniq,BOMPARENT,ALT_FOR,UNIQ_KEY,IsSynchronizedFlag,UNIQECDET)
	SELECT dbo.fn_GenerateUniqueNumber(),@bomParent,@uniqKey,UNIQ_KEY,IsSynchronizedFlag,@uniqECDet FROM BOM_ALT 
	WHERE BOMPARENT =@bomParent AND ALT_FOR =@uniqKey

	--Insert BOM Anti AVL data to ECO Anti AVL
	INSERT INTO ECANTIAVL(UNIQECANTI,UNIQECNO,UNIQECDET,UNIQBOMNO,UNIQ_KEY,PARTMFGR,MFGR_PT_NO)
	SELECT dbo.fn_GenerateUniqueNumber(),@uniqECNo,@uniqECDet,@uniqBOMNo,UNIQ_KEY,PARTMFGR,MFGR_PT_NO FROM ANTIAVL 
	WHERE BOMPARENT =@bomParent AND UNIQ_KEY =@uniqKey    

END TRY
BEGIN CATCH
	IF @@TRANCOUNT>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
		@ErrorSeverity = ERROR_SEVERITY(),
		@ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
            @ErrorSeverity, -- Severity.
            @ErrorState -- State.
            );

END CATCH	

IF @@TRANCOUNT>0
	COMMIT  

END	     