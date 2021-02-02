CREATE PROCEDURE [dbo].[AcctRec4DepositView] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT customer.CustName, AcctsRec.InvNO, AcctsRec.InvDate, AcctsRec.InvTotal - AcctsRec.ArCredits AS Balance, 
		PLMAIN.Terms, cast (0000000.00 AS numeric(10,4)) as nDiscAvail,lPrepay
	FROM Customer, AcctsRec, PlMain
	where AcctsRec.InvTotal - AcctsRec.Arcredits <> 0
		and PLMAIN.INVOICENO = ACCTSREC.InvNo
		and CUSTOMER.CUSTNO = ACCTSREC.CustNo
	
END