

CREATE procedure [dbo].[ShipChargeSetupView]
AS SELECT Text,Number,Uniqfield,FieldName FROM Support WHERE Fieldname = 'SHIPCHARGE' ORDER BY Number


