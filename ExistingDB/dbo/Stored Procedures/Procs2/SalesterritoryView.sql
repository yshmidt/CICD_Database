

CREATE procedure [dbo].[SalesterritoryView]
AS SELECT Text, Number,Uniqfield,FieldName FROM Support WHERE Fieldname = 'TERRITORY' ORDER BY Number


