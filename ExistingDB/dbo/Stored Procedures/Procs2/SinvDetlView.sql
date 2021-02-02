-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <01/12/2011>
-- Description:	<SinvDetl view for a single sinv_uniq. Use in DMR module>
-- Modification:
--	07/12/16	VL	Added FC field CosteachFC and Is_tax
-- 04/19/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[SinvDetlView]
	-- Add the parameters for the stored procedure here
	@lcSinv_uniq char(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT SINVDETL.SINV_UNIQ,SINVDETL.SDET_UNIQ,SINVDETL.LOC_UNIQ,Costeach, CosteachFC, Is_tax, CosteachPR
		FROM SINVDETL where SINV_UNIQ = @lcSinv_uniq 
END