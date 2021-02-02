
create PROCEDURE [dbo].[InventorByPartClassPartTypeView]
	-- Add the parameters for the stored procedure here
	@lcPart_class char(8) = ' ', @lcPart_type char(8) = ' '

AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT Uniq_key, Part_class, Part_type, Abc, U_OF_MEAS, PUR_UOFM, PACKAGE, SCRAP, SETUPSCRAP, INSP_REQ, ORD_POLICY, DAY, 
		DAYOFMO, DAYOFMO2, PULL_IN, PUSH_OUT, ORDMULT, MINORD, REORDPOINT, REORDERQTY, PUR_LTIME, Pur_lunit, KIT_LTIME, 
		Kit_lunit, PROD_LTIME, Prod_lunit, Buyer_Type, LastChangeDt, LastChangeInit, PART_NO, REVISION, Descript
	FROM Inventor
	WHERE 1 = CASE WHEN @lcPart_type = '' THEN
				CASE WHEN PART_CLASS = @lcPart_class THEN 1 ELSE 0 END
				ELSE CASE WHEN PART_CLASS = @lcPart_class AND PART_TYPE = @lcPart_type THEN 1 ELSE 0 END END
        
END