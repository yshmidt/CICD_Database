
-- =============================================
-- Author:		Vicky Lu	
-- Create date: <08/24/12>
-- Description:	<Get all wonos that belong to selected customers
-- =============================================
cREATE PROCEDURE [dbo].[AllWOPart4CustnoView] 
	-- Add the parameters for the stored procedure here
	@ltCustList AS tCustno READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- 08/24/12 VL changed to pass table variable as paramter, not pass a custo each time
--ALTER PROC [dbo].[AllWOPart4CustnoView] @lcCustno AS char(10) = ' '
--AS
-- SELECT Wono, Part_no, Revision, Part_class, Part_type, Descript, Inventor.Uniq_key
-- 	FROM Inventor, WOENTRY
-- 	WHERE Inventor.Uniq_key = Woentry.Uniq_key
-- 	AND Woentry.Custno = @lcCustno
-- 	ORDER BY 1,2,3

SELECT DISTINCT Wono, Part_no, Revision, Part_class, Part_type, Descript, Inventor.Uniq_key
 	FROM Inventor, WOENTRY
 	WHERE Inventor.Uniq_key = Woentry.Uniq_key
 	AND Woentry.Custno IN (SELECT Custno FROM @ltCustList)
 	ORDER BY 1,2,3

END