

CREATE PROC [dbo].[InvMatlTpView]   
AS
 SELECT Invmatltp.uqinvmattp, Invmatltp.invmatltype,
  Invmatltp.invmatltypedesc, Invmatltp.checkorder, ' ' AS changed, 'N    ' AS hasall
 FROM invmatltp ORDER BY Invmatltp.checkorder, Invmatltp.invmatltype,Invmatltp.invmatltypedesc
