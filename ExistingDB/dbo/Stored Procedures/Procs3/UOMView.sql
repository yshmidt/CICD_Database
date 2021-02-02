create proc [dbo].[UOMView]
AS 
SELECT LEFT(support.text,4) as UOM FROM SUPPORT WHERE  support.fieldname = 'U_OF_MEAS' ORDER BY Number
