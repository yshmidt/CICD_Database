CREATE PROCEDURE [dbo].[PoReconRelDocView] 
	-- Add the parameters for the stored procedure here
	@lcSinv_Uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Poreconreldoc.sinv_uniq, Poreconreldoc.doc_uniq,
	Poreconreldoc.sdet_uniq, Poreconreldoc.docno, Poreconreldoc.docrevno,
    Poreconreldoc.docdescr, Poreconreldoc.docdate, Poreconreldoc.docnote,
    Poreconreldoc.docexec, Poreconreldoc.docpdf
 FROM 
     poreconreldoc
 WHERE  Poreconreldoc.sinv_uniq = @lcSinv_Uniq

END
