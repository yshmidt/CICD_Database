
CREATE PROC [dbo].[PhyInvtFindView] @lnInvtType numeric(1,0) = 1, @lcCustSupno char(10) = '', @lcPiStatus char(10)=''
AS 
SELECT UniqPiHead, CASE WHEN InvtType = 1 THEN 'INTERNAL' ELSE 
	CASE WHEN InvtType = 2 THEN 'CONSIGNED' ELSE 
	CASE WHEN InvtType = 3 THEN 'INSTORES' ELSE ' ' END END END AS InvType, StartTime, PiStatus, DetailName 
	FROM PhyInvth
	WHERE INVTTYPE = @lnInvtType 
	AND 1 = CASE WHEN (@lnInvtType <> 1 AND @lcCustSupno <> '') THEN CASE WHEN (DETAILNO = @lcCustSupno) THEN 1 ELSE 0 END ELSE 1 END
	AND 1 = CASE WHEN (@lcPiStatus <> '') THEN CASE WHEN (PISTATUS = @lcPiStatus) THEN 1 ELSE 0 END ELSE 1 END









