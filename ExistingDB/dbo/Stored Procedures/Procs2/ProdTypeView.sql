-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/05/2016
-- Description:	Prodtype setup, used in Product Type setup
-- =============================================
CREATE PROCEDURE [dbo].[ProdTypeView]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT Prodtype.*, ISNULL(Inventor.part_no,SPACE(25)) AS part_no, Customer.custname, ISNULL(Fcused.Symbol, SPACE(3)) AS Symbol
	FROM Prodtype INNER JOIN Customer ON Prodtype.Custno = Customer.Custno 
	LEFT OUTER JOIN Inventor ON Prodtype.ROUTUNQKEY = Inventor.Uniq_key
	LEFT OUTER JOIN Fcused ON Prodtype.Fcused_uniq = Fcused.Fcused_uniq 
	ORDER BY Prodtype.part_class, Prodtype.part_type, Prodtype.descript

END