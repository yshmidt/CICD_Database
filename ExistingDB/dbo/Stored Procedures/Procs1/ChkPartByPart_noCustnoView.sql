-- =============================================
-- Author:		Vicky	
-- Create date: 04/14/2011
-- Description:	Try to get inventory records that match passed part class, type, part source and custno
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[ChkPartByPart_noCustnoView] @lcIsCONSG char(5) = ' ', @lcWhereFrom char(4) = ' ', 
	--- 03/28/17 YS changed length of the part_no column from 25 to 35
	@lcPart_no char(35) = ' ', @lcCustno char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

IF @lcIsCONSG = 'CONSG'
	BEGIN
	IF @lcWhereFrom = 'Int'
		SELECT Part_No, Revision, Part_Class, Part_Type, Descript, CustPartNo, CustRev, Uniq_key, Part_sourc
			FROM Inventor
			WHERE Part_No = @lcPart_no
			AND Custno = @lcCustno
			AND PART_SOURC <> 'PHANTOM'
			AND Status = 'Active'
			ORDER BY CustPartNo, CustRev, Part_Class, Part_Type
	ELSE
		SELECT Part_No, Revision, Part_Class, Part_Type, Descript, CustPartNo, CustRev, Uniq_key, Part_sourc
			FROM Inventor
			WHERE CustPartNo = @lcPart_no
			AND CustNo = @lcCustno
			AND Part_Sourc <> 'PHANTOM'
			AND Status = 'Active'
			ORDER BY CustPartNo, CustRev, Part_Class, Part_Type
	END
ELSE
	BEGIN
	IF @lcWhereFrom = 'Int'
		SELECT Part_No, Revision, Part_Class, Part_Type, Descript, CustPartNo, CustRev, Uniq_key, Part_sourc
			FROM Inventor
			WHERE Part_No = @lcPart_no
			AND Custno = ''
			AND PART_SOURC <> 'PHANTOM'
			AND Status = 'Active'
			ORDER BY Part_no, Revision, Part_Class, Part_Type
	ELSE
		SELECT Part_No, Revision, Part_Class, Part_Type, Descript, CustPartNo, CustRev, Uniq_key, Part_sourc
			FROM Inventor
			WHERE CustPartNo = @lcPart_no
			AND CustNo = @lcCustno
			AND Part_Sourc <> 'PHANTOM'
			AND Status = 'Active'
			ORDER BY CustPartNo, CustRev, Part_Class, Part_Type
	END
END



