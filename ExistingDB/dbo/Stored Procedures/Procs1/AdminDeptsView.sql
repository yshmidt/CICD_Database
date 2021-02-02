
CREATE procedure [dbo].[AdminDeptsView]
AS SELECT Text, Number,Logic1,Logic2,Uniqfield,FieldName FROM Support WHERE Fieldname = 'DEPT' ORDER BY Number
