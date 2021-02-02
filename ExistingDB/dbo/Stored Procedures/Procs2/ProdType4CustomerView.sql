-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/06/2016
-- Description:	Prodtype for selected custno, fcused_Uniq (if not empty), use in SO module
-- =============================================
CREATE PROCEDURE [dbo].[ProdType4CustomerView]
	@Custno char(10) = ' ', @Fcused_Uniq char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT Prodtype.*, ISNULL(Inventor.part_no,SPACE(25)) AS part_no, Customer.custname, ISNULL(Fcused.Symbol, SPACE(3)) AS Symbol,  Parttype.U_of_meas
	FROM Prodtype INNER JOIN Customer ON Prodtype.Custno = Customer.Custno 
	INNER JOIN Parttype ON Prodtype.Part_class = Parttype.Part_class AND Prodtype.Part_type = Parttype.Part_type 
	LEFT OUTER JOIN Inventor ON Prodtype.ROUTUNQKEY = Inventor.Uniq_key
	LEFT OUTER JOIN Fcused ON Prodtype.Fcused_uniq = Fcused.Fcused_uniq 
	WHERE (ProdType.Custno = @Custno 
	AND Prodtype.Fcused_uniq = @Fcused_uniq)
	OR ProdType.Custno = '000000000~'	
	ORDER BY Prodtype.Descript, Prodtype.part_class, Prodtype.Part_type

END