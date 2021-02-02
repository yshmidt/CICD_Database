CREATE PROCEDURE [dbo].[ReturnReasonSetupView]
AS SELECT Text, Number,Del_Flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'REASON    ' ORDER BY Number
