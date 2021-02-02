-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/20/20 
-- Description:	This procedure will get all Dmemos records for passed in UniqAphead table variable, now used in frmCheckSch to check if the apmaster have pending DM created
-- =============================================
CREATE PROCEDURE [dbo].[GetDMPendingStatus4UniqAphead] 
	@ltUniqAphead AS tUniqAphead READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;
	SELECT *
		FROM DMEMOS
		WHERE EXISTS
			(SELECT 1
				FROM @ltUniqAphead t where t.UniqAphead=DMEMOS.Uniqaphead)
		AND DMSTATUS = 'Pending'
		
END