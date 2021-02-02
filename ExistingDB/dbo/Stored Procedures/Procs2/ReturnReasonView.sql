CREATE PROCEDURE [dbo].[ReturnReasonView]
AS SELECT LEFT(Text,15) as Reason FROM Support WHERE Fieldname = 'REASON    ' ORDER BY Number
