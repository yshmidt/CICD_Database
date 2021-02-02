-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/10/2016
-- Description:	Order Configuration Header (Inventor)
-- =============================================
CREATE PROCEDURE [dbo].[CnfgHeadView]
	@gUniq_key char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT Inventor.*, Custname, Prodtype.Fcused_uniq, ISNULL(Fcused.Symbol,SPACE(3)) AS Symbol
		FROM Inventor INNER JOIN Customer 
		ON Inventor.CnfgCustno = Customer.Custno 
		INNER JOIN Prodtype 
		ON Inventor.ProdTpUniq = Prodtype.ProdTpUniq 
		LEFT OUTER JOIN Fcused
		ON Prodtype.Fcused_uniq = Fcused.Fcused_uniq
	WHERE Inventor.Uniq_key = @gUniq_key
	AND CnfgCustno<>''

END