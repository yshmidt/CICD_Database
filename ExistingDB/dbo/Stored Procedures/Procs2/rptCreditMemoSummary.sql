
-- =============================================
-- Author:		Debbie
-- Create date: 05/29/2013
-- Description:	This Stored Procedure was created for the Credit Memo Summary 
-- Reports Using Stored Procedure:   cmrep2.rpt
-- Modified:	04/16/2014 DRP:  Requested by the users that we include the custno into the quickview results.  
--			Also made modifications so that it will only work with WebManex Reports.  It will no longer work with the CR versions of the reports. 
--				06/12/2014 DRP: needed to filter out credit memo records with cstatus of 'CANCELLED'
--				01/06/2015 DRP:  Added @customerStatus Filter 
--				03/14/2016	VL:	 Added FC codes
--				04/08/2016	VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/18/2017	VL:	 added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptCreditMemoSummary]


		@lcDateStart as smalldatetime= null,
		@lcDateEnd as smalldatetime = null,
		@lcCustNo as varchar(max) = 'All'
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		,@userId uniqueidentifier= null 
as
begin	

/*GATHERING THE CUSTOMER LISTING FOR THE USER*/
	--/*04/16/2014:  added this section below for the comma seperator*/
	DECLARE  @tCustomer as tCustomer
	DECLARE @Customer TABLE (custno char(10))
	-- get list of Customers for @userid with access
	INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;
	--SELECT * FROM @tCustomer	

	IF @lcCustno is not null and @lcCustNo <>'' and @lcCustNo<>'All'
		insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
				where CAST (id as CHAR(10)) in (select Custno from @tCustomer)
	ELSE

	IF  @lccustNo='All'	
	BEGIN
		INSERT INTO @Customer SELECT Custno FROM @tCustomer
	END	

/*GATHERING THE DETAILED INFORMATION*/

	-- 03/14/16 VL added for FC installed or not
	DECLARE @lFCInstalled bit
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	BEGIN
	IF @lFCInstalled = 0
		BEGIN

		select	sname,CMEMONO,INVOICENO,CMDATE,SONO,CMTOTEXTEN,CM_FRT,CM_FRT_TAX+TOTTAXE as TAXES,CMTOTAL,cmmain.custno
		from	CMMAIN
				cross join micssys
		WHERE	CMDATE>=@lcDateStart AND CMDATE<@lcDateEnd+1
				and 1= case WHEN cmmain.custNO IN (SELECT custno FROM @custOMER) THEN 1 ELSE 0  END
				AND CSTATUS <> 'CANCELLED' /*06/12/2014 DRP:  added*/
		/*04/16/2014:--and SNAME like case when @lcCust ='*' then '%' else @lcCust + '%' end*/

		END
	ELSE
	-- FC installed
		BEGIN
		-- 01/18/17 VL:   added functional currency code
		select	sname,CMEMONO,INVOICENO,CMDATE,SONO,CMTOTEXTEN,CM_FRT,CM_FRT_TAX+TOTTAXE as TAXES,CMTOTAL,cmmain.custno
				,CMTOTEXTENFC,CM_FRTFC,CM_FRT_TAXFC+TOTTAXEFC as TAXESFC, CMTOTALFC
				,CMTOTEXTENPR,CM_FRTPR,CM_FRT_TAXPR+TOTTAXEPR as TAXESPR, CMTOTALPR
				,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
		from	CMMAIN 
				-- 01/18/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON Cmmain.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Cmmain.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN Fcused TF ON Cmmain.Fcused_uniq = TF.Fcused_uniq
				cross join micssys
		WHERE	CMDATE>=@lcDateStart AND CMDATE<@lcDateEnd+1
				and 1= case WHEN cmmain.custNO IN (SELECT custno FROM @custOMER) THEN 1 ELSE 0  END
				AND CSTATUS <> 'CANCELLED' /*06/12/2014 DRP:  added*/
		ORDER BY TSymbol
		/*04/16/2014:--and SNAME like case when @lcCust ='*' then '%' else @lcCust + '%' end*/
		END
	END--IF FC installed
end