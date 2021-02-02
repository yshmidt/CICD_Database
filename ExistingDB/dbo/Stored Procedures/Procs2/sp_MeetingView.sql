-- example of the stored procedure/view and inline UDF

CREATE Procedure dbo.sp_MeetingView 
	@Uniq_key char(10)=' '
	as  
	BEGIN
		SELECT INVENTOR.UNIQ_KEY,INVENTOR.PART_NO,INVENTOR.REVISION,INVENTOR.PART_SOURC,INVENTOR.CUSTNO, Customer.CustName 
			FROM Inventor INNER JOIN Customer on Customer.Custno=Inventor.Custno 
			where Inventor.Part_sourc='CONSG' and Inventor.Uniq_key=@Uniq_key
	END
	
	
	