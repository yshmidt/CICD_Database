-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/10/2011>
-- Description:	<GetDMRSOFar>
-- =============================================
CREATE PROCEDURE dbo.GetDMRSOFar
	-- Add the parameters for the stored procedure here
	@lcUniqRecDtl char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Ret_qty AS QtysoFar,Dmr_no 
		FROM Porecmrb 
		WHERE Dmr_no<>' ' 
		AND fk_uniqrecdtl= @lcUniqRecDtl 
END