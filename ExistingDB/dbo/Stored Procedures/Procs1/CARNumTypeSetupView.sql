

CREATE procedure [dbo].[CARNumTypeSetupView]
AS SELECT Text, Number,Del_flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'NUM_TYPE' ORDER BY Number


