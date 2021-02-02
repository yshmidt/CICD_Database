
CREATE procedure [dbo].[PkPgNmView]
AS SELECT PageNo,PageDesc,Type,PkInPgNmUk FROM PkInPgNm WHERE [Type] = 'P' ORDER BY PageNo

