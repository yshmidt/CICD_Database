

CREATE procedure [dbo].[SalesRepTypeView]
AS SELECT Text, Number,UniqField,FieldName FROM Support WHERE Fieldname = 'SREPTYPE' ORDER BY Number


