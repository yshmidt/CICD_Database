CREATE PROCEDURE [dbo].[SupplierTypeSetupView]
AS SELECT Text, Number,Del_Flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'SUP_TYPE  ' ORDER BY Number
