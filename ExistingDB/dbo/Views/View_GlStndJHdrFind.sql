

CREATE VIEW [dbo].[View_GlStndJHdrFind]
AS
SELECT StdRef, SjType,StdDescr,SUBSTRING(Reason,1,50) as ShortReason,glStndHKey FROM  GLSjHdr 