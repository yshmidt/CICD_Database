
CREATE PROC [dbo].[MrcSetupView] As
SELECT Text,Number,Del_Flag,Uniqfield,FieldName FROM Support where Fieldname = 'MRC' ORDER BY Text
