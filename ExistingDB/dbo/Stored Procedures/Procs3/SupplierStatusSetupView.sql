CREATE PROCEDURE [dbo].[SupplierStatusSetupView]
AS SELECT Text,Text2, Number,Del_Flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'SUPPL_STAT' ORDER BY Text2
