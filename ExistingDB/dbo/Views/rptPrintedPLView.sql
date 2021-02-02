CREATE VIEW [dbo].[rptPrintedPLView]
AS
SELECT     PACKLISTNO
FROM         dbo.PLMAIN
WHERE     (PRINTED = 1)
