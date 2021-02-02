-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/27/2012
-- Description:	Get outstanding JE Debit to an account assigned to a specific banks. Using to reconcile bank statement
-- Modified: 01/06/2013 YS added new field ReconUniq to link to an exact record in the bkrecon table. We allow multiple records with the same recondate.
-- 01/06/2014 YS added new parameter for ReconUniq to be able to match transaction to a statement if was connected.
-- =============================================
CREATE PROCEDURE [dbo].[GetOutstandingJeBankDeposits]
	-- Add the parameters for the stored procedure here
	@gl_nbr char(13)=' ', 
	@TRANSDATE smalldatetime = null,
	@ReconUniq char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 12/03/12 YS changed to use TransDate insted of the PostedDt
   --01/06/2013 YS added new field ReconUniq to link to an exact record in the bkrecon table. We allow multiple records with the same recondate.

	SELECT gljehdr.je_no,gljehdr.reason,gljehdr.jetype,gljehdr.TransDate ,gljedet.Debit ,GlJeHdr.UNIQJEHEAD,gljedet.UNIQJEDET,
		gljedet.Reconcilestatus ,gljedet.ReconcileDate ,
		CASE WHEN gljedet.Reconcilestatus=' ' THEN cast(0 as bit) 
				WHEN gljedet.ReconcileStatus='C' THEN cast(1 as bit) END AS Cleared,gljedet.ReconUniq
		FROM gljehdr INNER JOIN gljedet ON gljehdr.uniqjehead = gljedet.uniqjehead 
		WHERE gljedet.gl_nbr =@gl_nbr
		AND Debit<>0.00
		AND gljedet.Reconcilestatus <>'R'
		-- 01/06/14 YS added new field and new parameter
		AND ((gljedet.Reconcilestatus = 'C' AND gljedet.ReconUniq=@ReconUniq)  OR DATEDIFF(day,GlJeHdr.TRANSDATE,@TRANSDATE) >=0 )
		--AND DATEDIFF(day,GlJeHdr.TRANSDATE,@TRANSDATE) >=0 
END