

CREATE PROC [dbo].[MatTpLogicView]   
AS
SELECT DISTINCT Mattplogic.uqmtlogic, Mattplogic.uqinvmattp, Mattplogic.uqavlmattp, Invmatltp.invmatltype,
  Invmatltp.invmatltypedesc, Avlmatltp.avlmatltype, Avlmatltp.avlmatltypedesc, Mattplogic.logic
 FROM mattplogic, invmatltp, avlmatltp
 WHERE  Mattplogic.uqinvmattp = Invmatltp.uqinvmattp
   AND  Mattplogic.uqavlmattp = Avlmatltp.uqavlmattp
 ORDER BY Invmatltp.invmatltype, Avlmatltp.avlmatltype
