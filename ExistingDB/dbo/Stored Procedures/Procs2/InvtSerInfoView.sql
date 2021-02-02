CREATE PROCEDURE [dbo].[InvtSerInfoView] @gWono AS char(10) = '', @lcSerialno AS char(30) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @lcSerialno AS Serialno, @gWono AS Wono, Part_no, Revision, Part_class, Part_type, Descript, Custname, CustPartNo, CustRev
	FROM Inventor, Woentry, Customer
	WHERE Inventor.Uniq_key = Woentry.Uniq_key
	AND Woentry.Custno = Customer.Custno
	AND Woentry.Wono = @gWono
	
END