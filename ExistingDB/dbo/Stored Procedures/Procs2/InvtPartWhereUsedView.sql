
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/28/10 - Todays is Glynn's BD. 
-- Description:	This view/stored procedure is to query "where use" for the part number. 
-- Use in the Inventor module "Where Part Number Used" button 
-- 05/11/16 YS remove restriction on the desciprtion size (request by fusion)
-- =============================================
CREATE PROCEDURE [dbo].[InvtPartWhereUsedView]
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 05/11/16 YS remove restriction on the desciprtion size
	SELECT Part_no,Revision,Item_no,Descript,Qty, LEFT(Bom_Status,8) AS Bom_Status, Status,Eff_Dt, 
		Term_Dt,Bom_det.BomParent  
	FROM Bom_det,Inventor 
	WHERE Bom_det.Bomparent = Inventor.Uniq_key
		AND Bom_det.Uniq_key = @lcUniq_key
	ORDER BY Part_no, Revision,Item_no
END