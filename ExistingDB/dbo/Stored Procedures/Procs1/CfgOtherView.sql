-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/12/2016
-- Description:	Order Configuration Others
-- =============================================
CREATE PROCEDURE [dbo].[CfgOtherView]
	@gUniq_key char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT Cfgother.descript, Cfgother.saleprice, Cfgother.uniq_other,  Cfgother.uniq_key, Cfgother.salepricefc
		FROM Cfgother
		WHERE Cfgother.Uniq_key = @gUniq_key
END