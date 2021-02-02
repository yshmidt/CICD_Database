

CREATE procedure [dbo].[ShipViaSetupView]
AS SELECT Text,Text2,Number,Del_Flag,UniqField,FieldName FROM Support WHERE Fieldname = 'SHIPVIA' ORDER BY Number


