-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <03/31/10>
-- Description:	<Show all the consign parts with customer name and custno for the specific internal part>
-- =============================================
CREATE PROCEDURE dbo.ConsignInventoryView
	-- Add the parameters for the stored procedure here
	@lcUniq_key as char(10) =' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT Customer.Custname,Inventor.CustPartNo,Inventor.CustRev,Inventor.CustNo,Inventor.Uniq_key 
	FROM Inventor,Customer 
	WHERE Int_Uniq=@lcUniq_key 
	AND Customer.Custno=Inventor.CustNo 


END