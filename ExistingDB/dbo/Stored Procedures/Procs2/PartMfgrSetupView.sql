
CREATE procedure [dbo].[PartMfgrSetupView]
AS SELECT Text2,Text,Number,Del_Flag,Uniqfield,FieldName FROM Support WHERE Fieldname = 'PARTMFGR' ORDER BY Text2

