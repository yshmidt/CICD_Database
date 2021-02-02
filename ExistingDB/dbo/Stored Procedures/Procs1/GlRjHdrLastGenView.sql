-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <06/30/11>
-- Description:	<get information for last gen date prior to entered date including null dates>
-- Modification:
-- 03/28/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[GlRjHdrLastGenView]
	-- Add the parameters for the stored procedure here
	@pdLastGenDt as smalldatetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF dbo.fn_IsFCInstalled()=0
	SELECT [recref]
      ,[start_dt]
      ,[end_dt]
      ,[reason]
      ,[recdescr]
      ,[lastgen_dt]
      ,[lastperiod]
      ,[last_fy]
      ,[is_reverse]
      ,[freq]
      ,[glrhdrkey]
      ,[saveinit]
      ,[savedate]
  FROM [dbo].[GlRjHdr] where [lastgen_dt] IS NULL OR [lastgen_dt]<@pdLastGenDt
ELSE
	SELECT [recref]
      ,[start_dt]
      ,[end_dt]
      ,[reason]
      ,[recdescr]
      ,[lastgen_dt]
      ,[lastperiod]
      ,[last_fy]
      ,[is_reverse]
      ,[freq]
      ,[glrhdrkey]
      ,[saveinit]
      ,[savedate]
	  -- 03/28/17 VL added functional currency code
	  ,GlRjHdr.Fcused_uniq
	  ,Fchist_key
	  ,PRFcused_uniq
	  ,FUNCFcused_uniq,
	  -- 05/25/17 VL added Currency
	  CASE WHEN GlRjHdr.Fcused_uniq<>'' THEN Fcused.Currency ELSE SPACE(10) END AS Currency
		 FROM GlRjHdr LEFT OUTER JOIN Fcused 
			ON GlRjHdr.Fcused_uniq = Fcused.Fcused_uniq
		WHERE [lastgen_dt] IS NULL OR [lastgen_dt]<@pdLastGenDt
END
select * from glrjhdr