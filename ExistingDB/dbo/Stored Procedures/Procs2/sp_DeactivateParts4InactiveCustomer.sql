-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/07/17
-- Description:	Deactive parts for inactive customers with no SO, WO, PO, BOM and no Qty_oh, also create another SQL to show 
--				why some of parts are not deactivated
-- Modification: 
-- 10/12/17 VL changed revision from char(4) to char(8)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================

CREATE PROCEDURE [dbo].[sp_DeactivateParts4InactiveCustomer] @ltCustList AS tCustno READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @FinalParts TABLE (Part_no char(35), Revision char(8), Part_sourc char(10), Uniq_key char(10), BOM char(35), 
		PO char(15), SO char(10), WO char(10), TotQtyOH numeric(12,2), HasConsg char(1), Int_Uniq char(10), Ok char(1))

INSERT @FinalParts EXEC [GetParts4Customer] @ltCustList;

-- Really update inventor table from @FinalParts which OK = 1
UPDATE Inventor
	SET STATUS = 'Inactive'
	FROM @FinalParts F, INVENTOR I
	WHERE F.Uniq_key = I.UNIQ_KEY
	AND F.Ok = 'Y'
	


END TRY

BEGIN CATCH
	RAISERROR('Error occurred in updating inactive part number records. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		