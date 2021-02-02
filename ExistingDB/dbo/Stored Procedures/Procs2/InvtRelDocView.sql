
CREATE proc [dbo].[InvtRelDocView] (@gUniq_key char(10) ='')
AS
SELECT Invtreldoc.doc_uniq, Invtreldoc.fk_uniqueid,
  Invtreldoc.docno, Invtreldoc.docrevno, Invtreldoc.docdescr,
  Invtreldoc.docdate, Invtreldoc.docnote, Invtreldoc.docexec
  FROM 
     invtreldoc
 WHERE  Invtreldoc.fk_uniqueid = @gUniq_key 
 ORDER BY Invtreldoc.docno


