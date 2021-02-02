-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	???
-- Modified	  : 10/08/14 YS remove invtmfhd table and replace with 2 new tables	
-- =============================================
CREATE PROC [dbo].[DupMPNWithSpaceView]
AS
BEGIN
	-- 12/05/13 VL added part_no, revision and UPPER() outside of PADR() because we have more restricted index UPMU now
	--SELECT Uniq_key,dbo.PADR(LTRIM(RTRIM(Mfgr_pt_no)),30,' ') AS Mfgr_pt_no, Partmfgr, COUNT(*) AS N
	--10/08/14 YS remove invtmfhd table and replace with 2 new tables	
	SELECT Part_no, Revision, l.Uniq_key,UPPER(dbo.PADR(LTRIM(RTRIM(Mfgr_pt_no)),30,' ')) AS Mfgr_pt_no, Partmfgr, COUNT(*) AS N 
		FROM InvtMPNLink L INNER JOIN INVENTOR ON l.uniq_key=Inventor.UNIQ_KEY
		INNER JOIN MfgrMaster M ON l.mfgrMasterId=m.MfgrMasterId
		GROUP BY Part_no, Revision, l.Uniq_key,dbo.PADR(LTRIM(RTRIM(Mfgr_pt_no)),30,' '), Partmfgr
		HAVING COUNT(*)>1
END