

CREATE VIEW [dbo].[View_GlJeHdrFind]
AS
-- 06/01/16 VL added Currtrfr.Ref_no as Ref_no and LEFT OUTER JOIN and DISTINCT
SELECT DISTINCT GLJEHDR.JE_NO, ISNULL(GLJEHDR.TRANSDATE, SPACE(19)) AS TransDate, PERIOD, FY, JETYPE, STATUS, CONVERT(char(50), SUBSTRING(REASON, 1, 50)) AS ShortReason, 
	ISNULL(currtrfr.ref_no, SPACE(10)) as ref_no, UNIQJEHEAD
FROM         dbo.GLJEHDR LEFT OUTER JOIN currtrfr on GlJeHdr.UniqJeHead = currtrfr.JeOHkey