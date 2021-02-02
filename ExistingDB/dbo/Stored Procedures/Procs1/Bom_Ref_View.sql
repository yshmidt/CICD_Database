
-- =============================================
-- Author:??
-- Create date:??
-- Description:	this procedure will be called from the SF module and Get BOM Ref Designator data
-- 07/31/2018 Shripati U add coulmn IsAdd and IsEdit for getting Edited and Added Record at client side
-- 10/23/2018 Shrikant B Arrange data in assending order by Ref_des 
-- 12/04/2018 Shrikant B Arrange data in assending order by Ref_des by First find length
-- 07/03/2019 Shrikant B Added column IsChecked to delete one or more reference designator based on checkbox selected 
-- [Bom_Ref_View] '4V144DEU7W'
-- =============================================

CREATE PROCEDURE [dbo].[Bom_Ref_View] @gUniqBomNo char(10)=' '

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

	SELECT Ref_des, Nbr, Assign, Uniqbomno, Body, Xor, Yor, Orient, UniqueRef,
	-- 07/31/2018 Shripati U add coulmn IsAdd and IsEdit for getting Edited and Added Record at client side
	CAST(0 as bit) as IsAdd,CAST(0 as bit) as IsEdit,
	-- 07/03/2019 Shrikant B Added column IsChecked to delete one or more reference designator based on checkbox selected 
	CAST(0 as bit) as IsChecked 
	FROM Bom_ref
	WHERE Uniqbomno = @gUniqBomNo
	-- 10/23/2018 Shrikant B Arrange data in assending order by Ref_des 
	-- 12/04/2018 Shrikant B Arrange data in assending order by Ref_des by First find length
	ORDER BY len(Ref_des), Ref_des, Nbr

END