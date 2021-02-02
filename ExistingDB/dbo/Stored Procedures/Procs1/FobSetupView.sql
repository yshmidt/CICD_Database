


CREATE procedure [dbo].[FobSetupView]
AS SELECT Text, Number,Del_flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'FOB' ORDER BY Number



