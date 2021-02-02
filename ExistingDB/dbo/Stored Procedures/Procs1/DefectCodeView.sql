

CREATE procedure [dbo].[DefectCodeView]
AS SELECT Text2,Text3,Text4,Number,Uniqfield,FieldName FROM Support WHERE Fieldname = 'DEF_CODE' ORDER BY Number


