CREATE procedure [dbo].[PartPkgSetupView]
AS SELECT Text, Number,Del_Flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'PART_PKG' ORDER BY Number
