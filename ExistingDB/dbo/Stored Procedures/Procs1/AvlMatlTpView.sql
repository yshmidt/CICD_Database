

CREATE PROC [dbo].[AvlMatlTpView]   
AS
SELECT Avlmatltp.uqavlmattp, Avlmatltp.avlmatltype,Avlmatltp.avlmatltypedesc
 FROM avlmatltp
 ORDER BY Avlmatltp.avlmatltype, Avlmatltp.avlmatltypedesc
