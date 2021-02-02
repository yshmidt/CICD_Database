CREATE procedure [dbo].[UOMSetupView]
AS SELECT Text, Number,Del_Flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'U_OF_MEAS ' ORDER BY Number
