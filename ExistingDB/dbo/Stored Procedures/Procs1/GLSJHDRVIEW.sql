
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <06-23-2011>
-- Description:	<Procedure used in JE>
-- Modification
-- 03/27/17 VL separate FC and non-FC and added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[GLSJHDRVIEW]
	-- Add the parameters for the stored procedure here
	@pcGlstndhKey as char(10)=' ' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF dbo.fn_IsFCInstalled()=0
	SELECT Glsjhdr.glstndhkey, Glsjhdr.stdref, Glsjhdr.reason,
	  Glsjhdr.stddescr, Glsjhdr.sjtype, Glsjhdr.last_post, Glsjhdr.post_fy,
	  Glsjhdr.saveinit, Glsjhdr.savedate
	 FROM 
		 glsjhdr
	 WHERE  Glsjhdr.glstndhkey = ( @pcGlstndhKey )
ELSE
	SELECT Glsjhdr.glstndhkey, Glsjhdr.stdref, Glsjhdr.reason,
	  Glsjhdr.stddescr, Glsjhdr.sjtype, Glsjhdr.last_post, Glsjhdr.post_fy,
	  Glsjhdr.saveinit, Glsjhdr.savedate,
	-- 03/27/17 VL added functional currency code
	Glsjhdr.Fcused_uniq, Glsjhdr.Fchist_key, Glsjhdr.PrFcused_uniq, Glsjhdr.FuncFcused_uniq, Fcused.Currency AS Currency
	 FROM 
		 glsjhdr LEFT OUTER JOIN Fcused 
			ON glsjhdr.Fcused_uniq = Fcused.Fcused_uniq
	 WHERE  Glsjhdr.glstndhkey = ( @pcGlstndhKey )

END