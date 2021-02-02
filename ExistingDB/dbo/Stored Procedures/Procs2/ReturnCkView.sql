CREATE PROCEDURE [dbo].[ReturnCkView]
	-- Add the parameters for the stored procedure here
	@gcUniqRetNo as char(10) = ' '
	AS
BEGIN 
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Deposits.date, Deposits.bk_acct_no, Arretck.custno,
  Arretck.dep_no, Arretck.uniqlnno, Arretck.rec_date, Arretck.rec_advice,
  Arretck.rec_amount, Arretck.bankcode, Arretck.ret_date, Arretck.ret_note,
  Customer.custname, Banks.accttitle, Banks.bank, Banks.acct_type, Banks.Bk_Uniq,
  Arretck.uniqretno, Arretck.gl_nbr, ARRETCK.cInitials, ARRETCK.dRetDate
 FROM 
    customer 
    INNER JOIN  arretck 
    INNER JOIN  deposits 
    INNER JOIN banks 
   ON  Deposits.bk_acct_no = Banks.bk_acct_no 
   ON  Arretck.dep_no = Deposits.dep_no 
   ON  Customer.custno = Arretck.custno
 WHERE  Arretck.uniqretno = @gcUniqRetNo
END