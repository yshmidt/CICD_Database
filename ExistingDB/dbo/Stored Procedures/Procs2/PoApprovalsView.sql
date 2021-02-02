-- =============================================
-- Author:		Yelena Shmidt
-- Create date:
-- Description:	PO Approval authorization
-- 12/05/13 YS added fk_aspnetUsers column
-- =============================================
CREATE PROCEDURE [dbo].[PoApprovalsView] 
as 
	SELECT UserId,[Name],Initials,cFinalInvtAmt,cFinalMroAmt,cMroAmt,cInvtAmt,PoApprovals.Uniq_user,fk_aspnetUsers,nPOAPPRID  
		from  PoApprovals join Users on Poapprovals.Uniq_user=Users.Uniq_user
