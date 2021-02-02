
-- =============================================
-- Author:		Debbie
-- Create date: 05/29/2013
-- Description:	This Stored Procedure was created for the Credit Memo Register reports 
-- Reports Using Stored Procedure: cmrep3.rpt
-- Modified:	06/11/2014 DRP:  needed to filter out credit memo records with cstatus of 'CANCELLED'
--							Also needed to add @userId to the procedure. 
--				03/14/2016	VL:	 Added FC codes
--				04/08/2016	VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/18/2017	VL:	 added functional currency code
--				02/01/2017 DRP:  added cmreason to the results per request
-- =============================================
CREATE PROCEDURE [dbo].[rptCreditMemoRegister]


		@lcDateStart as smalldatetime= NULL
		,@lcDateEnd as smalldatetime = NULL
		,@userId uniqueidentifier=null
as
begin	

-- 03/14/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN	
	select	sname,CMEMONO,INVOICENO,CMDATE,SONO,CMTOTEXTEN,CM_FRT,CM_FRT_TAX+TOTTAXE as TAXES,CMTOTAL,LIC_NAME
			,cmreason	--02/01/2017 DRP: Added
	from	CMMAIN
			cross join micssys
	WHERE	CMDATE>=@lcDateStart AND CMDATE<@lcDateEnd+1
			AND CSTATUS <> 'CANCELLED'
	END
ELSE
-- FC installed
	BEGIN
	-- 01/18/17 VL:   added functional currency code
	select	sname,CMEMONO,INVOICENO,CMDATE,SONO,CMTOTEXTEN,CM_FRT,CM_FRT_TAX+TOTTAXE as TAXES,CMTOTAL,LIC_NAME
			,CMTOTEXTENFC,CM_FRTFC,CM_FRT_TAXFC+TOTTAXEFC as TAXESFC,CMTOTALFC 
			,CMTOTEXTENPR,CM_FRTPR,CM_FRT_TAXPR+TOTTAXEPR as TAXESPR,CMTOTALPR
			,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			,cmreason	--02/01/2017 DRP: Added
	from	Cmmain
			-- 01/18/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON Cmmain.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Cmmain.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON Cmmain.Fcused_uniq = TF.Fcused_uniq
			cross join micssys
	WHERE	CMDATE>=@lcDateStart AND CMDATE<@lcDateEnd+1
			AND CSTATUS <> 'CANCELLED'
	ORDER BY TSymbol, CMEMONO
	END
END-- END of If FC installed
end