-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <06/22/2011>
-- Description:	<General JE module>
-- Modification
-- 03/27/17 VL separate FC and non-FC and added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[GLRJHDRVIEW]
	-- Add the parameters for the stored procedure here
	@pcGlRHdrKey as char(10)=' '  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF dbo.fn_IsFCInstalled()=0
	SELECT Glrjhdr.glrhdrkey, Glrjhdr.recref, Glrjhdr.start_dt,
           Glrjhdr.end_dt, Glrjhdr.reason, Glrjhdr.recdescr, Glrjhdr.lastgen_dt,
           Glrjhdr.lastperiod, Glrjhdr.last_fy, Glrjhdr.is_reverse, Glrjhdr.freq,
           Glrjhdr.saveinit, Glrjhdr.savedate
        FROM glrjhdr
     WHERE  Glrjhdr.glrhdrkey = ( @pcGlRHdrKey )
ELSE
	SELECT Glrjhdr.glrhdrkey, Glrjhdr.recref, Glrjhdr.start_dt,
           Glrjhdr.end_dt, Glrjhdr.reason, Glrjhdr.recdescr, Glrjhdr.lastgen_dt,
           Glrjhdr.lastperiod, Glrjhdr.last_fy, Glrjhdr.is_reverse, Glrjhdr.freq,
           Glrjhdr.saveinit, Glrjhdr.savedate,
		   -- 03/27/17 VL added functional currency code
		   Glrjhdr.Fcused_uniq, Glrjhdr.Fchist_key, Glrjhdr.PrFcused_uniq, Glrjhdr.FuncFcused_uniq, 
		   CASE WHEN Glrjhdr.Fcused_uniq<>'' THEN Fcused.Currency ELSE SPACE(10) END AS Currency
		 FROM glrjhdr LEFT OUTER JOIN Fcused 
			ON Glrjhdr.Fcused_uniq = Fcused.Fcused_uniq
     WHERE  Glrjhdr.glrhdrkey = ( @pcGlRHdrKey )

END