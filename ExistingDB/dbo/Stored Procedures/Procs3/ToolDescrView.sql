

CREATE procedure [dbo].[ToolDescrView]
AS SELECT Text, Number,Uniqfield,FieldName FROM Support WHERE Fieldname = 'TOOLSDESCR' ORDER BY Number


