
CREATE PROCEDURE [dbo].[SupplierView] @gUniqSupno as Char(10)=' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT * 
	FROM SUPINFO
	WHERE UNIQSUPNO = @gUniqSupno

END