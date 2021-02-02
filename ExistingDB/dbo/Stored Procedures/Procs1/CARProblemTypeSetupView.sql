

CREATE procedure [dbo].[CARProblemTypeSetupView]
AS SELECT Text, Number,Del_flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'PROB_TYPE' ORDER BY Number


