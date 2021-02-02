CREATE PROCEDURE [dbo].[ArCredit4NSFView]
	-- Add the parameters for the stored procedure here
	@gcCustNo as char(10) = ' ', @gdBegDate as smalldatetime = null, @gdEndDate as smalldatetime = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 09/12/12 YS change Uniqklnno+custno not IN ... to  Dep_no+UniqLnno NOT IN (SELECT Dep_no+UniqLnno FROM ArRetCk)
-- Unilnno indicated a single check. This check could come from one customer but paying for multiple invoices by different customers.
-- we need to return the entire check disregarding which customer
    -- Insert statements for procedure here
	
	--SELECT CustName, Rec_Date, Rec_Advice, SUM(Rec_Amount) AS Rec_Amount, 
 --   Dep_no, UniqLnNo 
	--FROM Customer, ArCredit 
	--WHERE Customer.CustNo = ArCredit.CustNo 
	--	AND ArCredit.CustNo = @gcCustNo 
	--	AND DATEDIFF(Day,@gdBegDate,Rec_Date)>=0 
	--	AND DATEDIFF(Day,Rec_date,@gdEndDate)>=0
	--	AND Rec_type <> 'Credit Memo '
	--	AND UniqLnno+ArCredit.CustNo NOT IN (SELECT UniqLnno+Custno FROM ArRetCk)
	--    GROUP BY UniqLnNo,CustName, Rec_Date,Dep_no,Rec_Advice 
	
	-- 01/13/17 VL added functional and Fc code
	SELECT A.Rec_Date, A.Rec_Advice, SUM(A.Rec_Amount) AS Rec_Amount, 
    A.Dep_no, A.UniqLnNo, SUM(A.Rec_AmountFC) AS Rec_AmountFC,  SUM(A.Rec_AmountPR) AS Rec_AmountPR 
	FROM ArCredit A 
	WHERE A.Rec_type <> 'Credit Memo '
		AND A.Dep_no+A.UniqLnno NOT IN (SELECT ArRetCk.Dep_no+ArRetCk.UniqLnno FROM ArRetCk)
		AND A.UNIQLNNO IN (SELECT UNIQLNNO FROM ArCredit WHERE custno=@gcCustNo 
		AND DATEDIFF(Day,@gdBegDate,Rec_Date)>=0 
		AND DATEDIFF(Day,Rec_date,@gdEndDate)>=0)
		GROUP BY UniqLnNo,Rec_Date,Dep_no,Rec_Advice 
	
	
END