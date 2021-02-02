-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/29/18 
-- Description:	This procedure will get all Apmaster records for passed in UniqAphead table variable, now used in frmCheckSch to get RecVer to check if the records get changed
-- =============================================
CREATE PROCEDURE [dbo].[GetApmaster4UniqAphead] 
	@ltUniqAphead AS tUniqAphead READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

-- 05/03/13 VL added Instore
SET NOCOUNT ON;
	SELECT *
		FROM Apmaster
		WHERE EXISTS
			(SELECT 1
				FROM @ltUniqAphead t where t.UniqAphead=Apmaster.Uniqaphead)
		
END