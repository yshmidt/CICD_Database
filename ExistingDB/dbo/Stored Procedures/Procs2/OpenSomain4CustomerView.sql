CREATE PROCEDURE [dbo].[OpenSomain4CustomerView] @lcCustNo as CHAR(10) ='' 
AS
SELECT Sono, Ord_Type, Terms
 FROM Somain
 WHERE Custno = @lcCustNo
 AND (Ord_type<>'Cancel' AND Ord_type<>'Closed' AND Ord_type<>'ARCHIVED')