
CREATE VIEW [dbo].[View_GlJeHdrOFind]
AS
-- 06/01/16 VL added Currtrfr.Ref_no as Ref_no and LEFT OUTER JOIN and DISTINCT
SELECT DISTINCT GLJEHDRO.JE_NO, ISNULL(GLJEHDRO.TRANSDATE, SPACE(19)) AS TransDate, PERIOD, FY, JETYPE, STATUS, CONVERT(char(50), SUBSTRING(REASON, 1, 50)) AS ShortReason, ISNULL(currtrfr.ref_no, SPACE(10)) as ref_no, GLJEHDRO.JEOHKEY
FROM     dbo.GLJEHDRO LEFT OUTER JOIN currtrfr on GlJeHdro.jeohkey = currtrfr.JeOHkey