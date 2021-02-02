-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/13/2012
-- Description:	Get all outstending deposits for the bank reconciliation
-- 12/06/13 YS modified to get sum for each check (rec_advice) will show on the screen by check (rec_advice) without going to
--- detailed information for the invoice
-- should change the structure to have deposits as top level, depostschecks (missing level sshowing summary for each rec_advice) 
-- and then  arcredit - to show where the receipt was applied 
-- for now will keep the detail information in the stored procedure to be able to update the records based on UNIQDETNO. 
-- 01/06/2013 YS added new field ReconUniq to link to an exact record in the bkrecon table. We allow multiple records with the same recondate.
-- 01/06/2014 YS added new parameter for ReconUniq to be able to match transaction to a statement if was connected.
--02/07/14 YS added partition by Deposits.Dep_No . If user had the same rec_advice in the different deposits we will have a problem
-- =============================================
CREATE PROCEDURE [dbo].[GetOutstandingDepositsView]
	-- Add the parameters for the stored procedure here
	@lcbk_Uniq char(10)=NULL,@ldDate smalldatetime =NULL,@ReconUniq char(10)=' '
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  -- 12/06/13 YS changes, see description in the header 
 -- SELECT [Date], Arcredit.REC_AMOUNT, Deposits.Dep_No ,
	--ISNULL(Customer.CUSTNAME,space(35)) as CUSTNAME,INVNO  ,Arcredit.REC_ADVICE,
	--Arcredit.UNIQDETNO ,
	--CASE WHEN ARCREDIT.ReconcileStatus=' ' THEN CAST(0 as bit) 
	--WHEN ARCREDIT.ReconcileStatus='C' THEN CAST(1 as bit) END as Cleared,
	--ARCREDIT.ReconcileStatus,ARCREDIT.ReconcileDate
	--FROM Deposits INNER JOIN ARCREDIT ON Deposits.DEP_NO =Arcredit.DEP_NO 
	--LEFT OUTER JOIN CUSTOMER ON Arcredit.CUSTNO=Customer.CUSTNO 
	--	WHERE ARCREDIT.ReconcileStatus <> 'R' 
	--	AND (Deposits.Bk_Uniq = @lcbk_Uniq ) 
	--    AND DATEDIFF(day,[Date],@ldDate) >=0 
	
	
	
	--  01/06/2013 YS added new field ReconUniq to link to an exact record in the bkrecon table. We allow multiple records with the same recondate.
-- 02/07/14 YS added partition by Deposits.Dep_No . If user had the same rec_advice in the different deposits (don't ask why) we have a problem
	 SELECT [Date], Arcredit.REC_AMOUNT, Deposits.Dep_No ,
		ISNULL(Customer.CUSTNAME,space(35)) as CUSTNAME,INVNO  ,Arcredit.REC_ADVICE,
	Arcredit.UNIQDETNO ,
	CASE WHEN ARCREDIT.ReconcileStatus=' ' THEN CAST(0 as bit) 
	WHEN ARCREDIT.ReconcileStatus='C' THEN CAST(1 as bit) END as Cleared,
	ARCREDIT.ReconcileStatus,ARCREDIT.ReconcileDate,ARCREDIT.reconUniq, 
	SUM(Arcredit.REC_AMOUNT) OVER(PARTITION BY Deposits.Dep_No ,REC_ADVICE) AS [CheckSum]
	FROM Deposits INNER JOIN ARCREDIT ON Deposits.DEP_NO =Arcredit.DEP_NO 
	LEFT OUTER JOIN CUSTOMER ON Arcredit.CUSTNO=Customer.CUSTNO 
		WHERE ARCREDIT.ReconcileStatus <> 'R' 
		AND (Deposits.Bk_Uniq = @lcbk_Uniq ) 
	    -- 01/06/14 YS added new field and new parameter
		AND ((ARCREDIT.Reconcilestatus = 'C' AND Arcredit.ReconUniq=@ReconUniq)  OR DATEDIFF(day,[Date],@ldDate) >=0)
		
	    
		
		
    
    
    
	
	
END