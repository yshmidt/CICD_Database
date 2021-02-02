CREATE FUNCTION dbo.ufn_MeetingView 
( @uniq_key char(10)=' ' )
RETURNS table
AS
RETURN (
        SELECT INVENTOR.UNIQ_KEY,INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.PART_SOURC,INVENTOR.CUSTNO, Customer.CustName 
			FROM Inventor INNER JOIN Customer on Customer.Custno=Inventor.Custno 
			where Inventor.Part_sourc='CONSG' and Inventor.Uniq_key=@Uniq_key
       );