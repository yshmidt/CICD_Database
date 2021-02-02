
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <06-23-2011>
-- Description:	<Procedure used in JE>
-- Modification
-- 03/27/17 VL added functional currency
-- 04/03/17 VL change the sequence of the fields debitFC and creditFC to be after debit and credit, so in the form, no need to add extra code to assign grid controlsource
-- =============================================
CREATE PROCEDURE [dbo].[GLSJDETVIEW]
	-- Add the parameters for the stored procedure here
	@pcGlstndhKey as char(10)=' ' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Glsjdet.gl_nbr, Gl_nbrs.gl_descr, Glsjdet.debit, Glsjdet.credit,
	-- 03/27/17 VL added functional currency
  Glsjdet.debitFC, Glsjdet.creditFC, Glsjdet.debitPR, Glsjdet.creditPR,
  Glsjdet.glstnddkey, Glsjdet.fkglstndhkey
  FROM 
     glsjdet 
    LEFT OUTER JOIN gl_nbrs 
   ON  Glsjdet.gl_nbr = Gl_nbrs.gl_nbr
 WHERE  Glsjdet.fkglstndhkey = ( @pcGlstndhKey )
END