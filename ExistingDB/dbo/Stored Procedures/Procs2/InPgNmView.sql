
CREATE procedure [dbo].[InPgNmView]
AS SELECT PageNo,PageDesc,Type,PkInPgNmUk FROM PkInPgNm WHERE [Type] = 'I' ORDER BY PageNo

