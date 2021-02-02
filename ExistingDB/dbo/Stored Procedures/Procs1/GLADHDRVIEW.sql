-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <07/13/11 My brother's BD>
-- Description:	<View for auti distribution (header)>
-- Modification:
-- 05/24/17 VL separate FC and non-FC and added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[GLADHDRVIEW]
	-- Add the parameters for the stored procedure here
	@pcglahdrkey as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF dbo.fn_IsFCInstalled()=0
			SELECT Gladhdr.glahdrkey, Gladhdr.adref, Gladhdr.reason, Gladhdr.addescr,
		  Gladhdr.last_post, Gladhdr.post_fy, Gladhdr.post_dt, Gladhdr.saveinit,
		  Gladhdr.savedate
		 FROM gladhdr
		 WHERE  Gladhdr.glahdrkey = @pcglahdrkey
ELSE
		SELECT Gladhdr.glahdrkey, Gladhdr.adref, Gladhdr.reason, Gladhdr.addescr,
	  Gladhdr.last_post, Gladhdr.post_fy, Gladhdr.post_dt, Gladhdr.saveinit,
	  Gladhdr.savedate,
	  -- 05/24/17 VL added functional currency code
	 Gladhdr.Fcused_uniq, Gladhdr.Fchist_key, Gladhdr.PrFcused_uniq, Gladhdr.FuncFcused_uniq, Fcused.Currency AS Currency
	 FROM gladhdr LEFT OUTER JOIN Fcused 
			ON Gladhdr.Fcused_uniq = Fcused.Fcused_uniq
	 WHERE  Gladhdr.glahdrkey = @pcglahdrkey

END