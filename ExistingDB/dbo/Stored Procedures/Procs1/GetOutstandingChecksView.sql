-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/13/2012
-- Description:	Get all outstending checks for the bank reconciliation
-- Modified: 09/16/2013 YS if no records in ShiBill, use SupName as Payee
-- 01/06/2014 YS added new field ReconUniq to link to an exact record in the bkrecon table. We allow multiple records with the same recondate.
-- 01/06/2014 YS added new parameter for ReconUniq to be able to match transaction to a statement if was connected.
-- 07/12/2018 YS increase size of the supname column from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[GetOutstandingChecksView]
	-- Add the parameters for the stored procedure here
	@lcbk_Uniq char(10)=NULL,@ldDate smalldatetime =NULL,@ReconUniq char(10)=' '
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
     -- 09/16/13 YS if no records in ShiBill, use SupName as Payee
     -- 01/06/14 YS added new field ReconUniq to link to an exact record in the bkrecon table. We allow multiple records with the same recondate.
	-- 07/12/2018 YS increase size of the supname column from 30 to 50

	SELECT CAST(ISNULL(ShipBill.ShipTo,ISNULL(Supinfo.Supname,'')) as NVARCHAR(50)) as ShipTo, 
		CheckDate, CheckNo, CheckAmt, 
		CASE WHEN Reconcilestatus=' ' THEN cast(0 as bit) 
		WHEN Reconcilestatus='C' THEN cast(1 as bit) END AS Cleared, 
		ApChk_Uniq,Reconcilestatus ,ReconcileDate,ReconUniq
		FROM ApChkMst LEFT OUTER JOIN  ShipBill 
		ON ApChkMst.R_Link = ShipBill.LinkAdd 
		LEFT OUTER JOIN SUPINFO on Apchkmst.UNIQSUPNO =Supinfo.UNIQSUPNO 
	WHERE ApChkMst.BK_Uniq = @lcBk_Uniq 
		AND ApChkMst.Reconcilestatus <> 'R'  
		AND CHARINDEX('Void',ApChkMst.Status)=0  
		-- 01/06/14 YS added new field and new parameter
		AND ((ApChkMst.Reconcilestatus = 'C' AND ReconUniq=@ReconUniq)  OR DATEDIFF(day,ApChkMst.CheckDate,@ldDate) >=0 )
		 
	
END