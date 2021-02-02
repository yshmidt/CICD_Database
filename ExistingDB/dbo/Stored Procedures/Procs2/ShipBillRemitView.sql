
CREATE PROCEDURE dbo.ShipBillRemitView 
	-- Add the parameters for the stored procedure here
	@gcSupId as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ShipTo, Address1, City, Address2, State, Zip, Country, LinkAdd 
	FROM ShipBill 
	WHERE CustNo = @gcSupId 
	AND RecordType = 'R' 
END
