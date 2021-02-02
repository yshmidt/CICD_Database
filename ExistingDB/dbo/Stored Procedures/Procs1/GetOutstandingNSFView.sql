-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/27/2012
-- Description:	Get all outstending NSF (Arretck) for the bank reconciliation
-- Modified: 01/06/2013 YS added new field ReconUniq to link to an exact record in the bkrecon table. We allow multiple records with the same recondate.
-- 01/06/2014 YS added new parameter for ReconUniq to be able to match transaction to a statement if was connected.
-- 01/06/2017 VL added functional currency code, separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[GetOutstandingNSFView]
	-- Add the parameters for the stored procedure here
	@lcbk_Uniq char(10)=NULL,@ldDate smalldatetime =NULL,
	@ReconUniq char(10)=' '
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --get nsf 
    --01/06/2013 YS added new field ReconUniq to link to an exact record in the bkrecon table
-- 01/06/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
IF @lFCInstalled = 0	

    SELECT ARRETCK.Ret_Date as [Date], -ArretDet.Rec_Amount as Rec_amount,ArRetCk.Dep_no, ISNULL(Customer.CUSTNAME,SPACE(35)) as CustName,
		ARRETCK.RET_NOTE, ARRETDET.REC_ADVICE,ARRETDET.ARRETDETUNIQ,ARRETDET.UNIQDETNO ,   
		CASE WHEN ARRETDET.Reconcilestatus=' ' THEN CAST(0 as bit) 
			WHEN ARRETDET.Reconcilestatus='C' THEN CAST(1 as bit) END  as Cleared,
		 ARRETDET.Reconcilestatus,ARRETDET.ReconcileDate,ARRETDET.ReconUniq  
	FROM ArRetCk INNER JOIN Deposits ON Arretck.Dep_no=Deposits.Dep_no
	INNER JOIN Arretdet ON ArretCk.UniqRetNo = ARRETDET.UniqRetno
	LEFT OUTER JOIN Customer ON Arretdet.Custno=Customer.CUSTNO 
		WHERE ArRetDet.ReconcileStatus <> 'R'
		AND (Deposits.Bk_Uniq = @lcbk_Uniq) 
	    -- 01/06/14 YS added new field and new parameter
		AND ((ArRetDet.Reconcilestatus = 'C' AND ArRetDet.ReconUniq=@ReconUniq)  OR DATEDIFF(day,Ret_Date,@ldDate) >=0 )
	    --AND DATEDIFF(day,Ret_Date,@ldDate) >=0 
ELSE
   SELECT ARRETCK.Ret_Date as [Date], -ArretDet.Rec_Amount as Rec_amount,ArRetCk.Dep_no, ISNULL(Customer.CUSTNAME,SPACE(35)) as CustName,
		ARRETCK.RET_NOTE, ARRETDET.REC_ADVICE,ARRETDET.ARRETDETUNIQ,ARRETDET.UNIQDETNO ,   
		CASE WHEN ARRETDET.Reconcilestatus=' ' THEN CAST(0 as bit) 
			WHEN ARRETDET.Reconcilestatus='C' THEN CAST(1 as bit) END  as Cleared,
		 ARRETDET.Reconcilestatus,ARRETDET.ReconcileDate,ARRETDET.ReconUniq,
		 -- 01/06/17 VL added functional currency fields
		 -ArretDet.Rec_AmountPR as Rec_amountPR, FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency  
	FROM ArRetCk 
		-- 01/06/17 VL added to show currency symbol
		INNER JOIN Fcused PF ON ArRetCk.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON ArRetCk.FuncFcused_uniq = FF.Fcused_uniq
	INNER JOIN Deposits ON Arretck.Dep_no=Deposits.Dep_no
	INNER JOIN Arretdet ON ArretCk.UniqRetNo = ARRETDET.UniqRetno
	LEFT OUTER JOIN Customer ON Arretdet.Custno=Customer.CUSTNO 
		WHERE ArRetDet.ReconcileStatus <> 'R'
		AND (Deposits.Bk_Uniq = @lcbk_Uniq) 
	    -- 01/06/14 YS added new field and new parameter
		AND ((ArRetDet.Reconcilestatus = 'C' AND ArRetDet.ReconUniq=@ReconUniq)  OR DATEDIFF(day,Ret_Date,@ldDate) >=0 )
	    --AND DATEDIFF(day,Ret_Date,@ldDate) >=0 
		
    
    
    
	
	
END