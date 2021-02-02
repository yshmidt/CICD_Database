
CREATE PROCEDURE [dbo].[OpenWO4ChkListView]

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
SELECT DISTINCT Jbshpchk.Wono, CONVERT(varchar(10),Due_date,101) AS Due_date, Part_no, Revision, BldQty, 
	LEFT(dbo.PADR(LTRIM(RTRIM(Part_class))+' '+LTRIM(RTRIM(Part_type))+' '+LTRIM(RTRIM(Descript)),40,' '),25) AS Descript, 
	Sono, LEFT(CustName,14) AS CustName, CASE WHEN Pjctmain.PrjNumber IS NULL THEN SPACE(10) ELSE Pjctmain.PrjNumber END AS PrjNumber, OpenClos 
 	FROM Inventor, Jbshpchk, Customer, Woentry
 	LEFT OUTER JOIN PjctMain 
 	ON PjctMain.PrjUnique = Woentry.PrjUnique
	WHERE Woentry.Uniq_key = Inventor.Uniq_key
	AND (Woentry.OpenClos <> 'Closed'
	AND Woentry.OpenClos <> 'Cancel')
	AND Woentry.Wono = Jbshpchk.Wono
	AND Woentry.Custno = Customer.Custno
	AND ChkFlag = 0
	AND Woentry.Kit = 0
	ORDER BY Jbshpchk.Wono
END