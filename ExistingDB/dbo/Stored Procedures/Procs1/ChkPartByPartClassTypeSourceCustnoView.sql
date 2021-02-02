-- =============================================
-- Author:		Vicky	
-- Create date: 04/14/2011
-- Description:	Try to get inventory records that match passed part class, type, part source and custno
-- =============================================
CREATE PROCEDURE [dbo].[ChkPartByPartClassTypeSourceCustnoView] @lcPart_class char(8) = ' ' , @lcPart_type char(8) = ' ',
	 @lcPart_Sourc char(8) = ' ', @lcCustno char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT Part_No, Revision, Part_Class, Part_Type, Descript, CustPartNo, CustRev, Uniq_key, Part_sourc
	FROM Inventor
	WHERE Status = 'Active'
	AND Part_class = @lcPart_class
	AND Part_Type = @lcPart_type
	AND Part_sourc = @lcPart_Sourc
	AND Custno = @lcCustno

END



