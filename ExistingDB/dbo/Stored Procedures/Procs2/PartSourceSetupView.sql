CREATE procedure [dbo].[PartSourceSetupView]
AS SELECT Text, Number,Del_Flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'PART_SOURC' ORDER BY Number
