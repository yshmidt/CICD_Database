CREATE PROCEDURE [dbo].[SupplierTypeView]
AS SELECT Text FROM Support WHERE Fieldname = 'SUP_TYPE' ORDER BY Number
