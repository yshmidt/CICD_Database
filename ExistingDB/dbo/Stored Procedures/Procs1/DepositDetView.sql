CREATE PROCEDURE [dbo].[DepositDetView]
	-- Add the parameters for the stored procedure here
	@gcDep_no as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Customer.custname, Arcredit.*
 FROM customer 
    INNER JOIN arcredit 
   ON  Customer.custno = Arcredit.custno
 WHERE  Arcredit.dep_no = @gcDep_no 
	AND ARCREDIT.REC_TYPE <> 'Credit Memo'
END
