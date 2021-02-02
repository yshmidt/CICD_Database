
-- =============================================
-- Author:			Debbie
-- Create date:		02/22/2013
-- Description:		Created for the AP Debit Memo Report
-- Reports:			dmreport.rpt
-- Modifications:   06/14/2013 DRP:  originally created for just WebManex on 2/22/2013, but it had not yet been converted to Stimulsoft as of 6/14/2013 and customers were requesting.  
--									 Made modification to work for Crystal report and created a CR and will.  
--					09/20/2013 DRP:  Added @lcUniqSupNo to work with the WebVersion of the report 
--					12/03/13	YS	use 'All' in place of ''  	
--									get list of approved suppliers for this user
--					01/23/14 DRP:	we found that if the user left All for the Supplier that it was bringing forward all Suppliers regardless if the user was approved for the Userid or not. 
--					12/12/14 DS Added supplier status filter
--					03/14/16 VL:	Added FC codes
--					04/08/16 VL:	Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--					02/06/17 VL:	Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptDebitMemoReport]

	@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
	,@lcSup as varchar (35) = '*'
	,@lcUniqSupNo as varchar(max) = 'All' -- 09/20/2013 DRP:  this was added for the WebManex Version of the report only 
	,@userId uniqueidentifier=null 
	,@supplierStatus varchar(20) = 'All'
as
begin


--09/20/2013 DRP:  allow @lcuniqsup have multiple csv
--12/03/13 YS get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
--01/23/14 DRP:  ADDED THE BELOW
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus;


--12/03/13	YS	use 'All' in place of ''. Empty or null means no supplier is entered  	
IF @lcUniqSupNo<>'All' and @lcUniqSupNo<>'' and @lcUniqSupNo is not null
	insert into @tSupNo  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',') WHERE cast(ID as char(10)) IN (SELECT UniqSupno from @tSupplier)
ELSE
	BEGIN
		IF @lcUniqSupNo='All'
		insert into @tSupno  select UniqSupno from @tSupplier
	END				

			
	-- 03/14/16 VL added for FC installed or not
	DECLARE @lFCInstalled bit
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	BEGIN
	IF @lFCInstalled = 0
		BEGIN
			
			select	dmemos.uniqdmhead,dmemos.DMEMONO,supinfo.uniqsupno,supinfo.SUPNAME,dmemos.DMDATE,dmemos.INVNO,dmemos.DMTOTAL
					,dmemos.DMAPPLIED,dmemos.DMTOTAL - dmemos.DMAPPLIED as Balance,dmemos.DMNOTE,micssys.LIC_NAME
			from	DMEMOS
					inner join SUPINFO on dmemos.UNIQSUPNO = supinfo.UNIQSUPNO
					cross apply micssys
			where	dmemos.DMSTATUS <> 'Cancelled'	
					and dmemos.dmdate>=@lcDateStart AND dmemos.dmdate<@lcDateEnd+1
					--12/03/13 YS change to use PATINDEX instead of LIKE. Work fasater
					--and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and 1= CASE WHEN @lcSup ='*' THEN 1 
								WHEN PATINDEX('%'+@lcSup+'%',SUPNAME)<>0 THEN 1 ELSE 0 end
		--09/20/2013 DRP: allow @lcuniqsup have multiple csv
		--12/03/13	YS	use 'All' in place of ''.
		--01/23/14	and 1= CASE WHEN @lcUniqSupNo = 'ALl' then 1 
		--				WHEN Supinfo.Uniqsupno IN (select UNIQSUPNO from @unisupno ) then 1 ELSE 0 END
					AND 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
		END
	ELSE
	-- FC installed
		BEGIN
			select	dmemos.uniqdmhead,dmemos.DMEMONO,supinfo.uniqsupno,supinfo.SUPNAME,dmemos.DMDATE,dmemos.INVNO,dmemos.DMTOTAL
					,dmemos.DMAPPLIED,dmemos.DMTOTAL - dmemos.DMAPPLIED as Balance,dmemos.DMNOTE,micssys.LIC_NAME
					,dmemos.DMTOTALFC, dmemos.DMAPPLIEDFC,dmemos.DMTOTALFC - dmemos.DMAPPLIEDFC as BalanceFC
					-- 02/06/17 VL comment out currency and added functional currency fields
					--, Fcused.Symbol AS Currency
					,dmemos.DMTOTALPR,dmemos.DMAPPLIEDPR,dmemos.DMTOTALPR - dmemos.DMAPPLIEDPR as BalancePR
					,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			from	DMEMOS
					-- 02/06/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON DMEMOS.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON DMEMOS.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON DMEMOS.Fcused_uniq = TF.Fcused_uniq			
					inner join SUPINFO on dmemos.UNIQSUPNO = supinfo.UNIQSUPNO
					cross apply micssys
			where	dmemos.DMSTATUS <> 'Cancelled'	
					and dmemos.dmdate>=@lcDateStart AND dmemos.dmdate<@lcDateEnd+1
					--12/03/13 YS change to use PATINDEX instead of LIKE. Work fasater
					--and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and 1= CASE WHEN @lcSup ='*' THEN 1 
								WHEN PATINDEX('%'+@lcSup+'%',SUPNAME)<>0 THEN 1 ELSE 0 end
		--09/20/2013 DRP: allow @lcuniqsup have multiple csv
		--12/03/13	YS	use 'All' in place of ''.
		--01/23/14	and 1= CASE WHEN @lcUniqSupNo = 'ALl' then 1 
		--				WHEN Supinfo.Uniqsupno IN (select UNIQSUPNO from @unisupno ) then 1 ELSE 0 END
					AND 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			-- 02/06/17 VL changed from currency to TSymbol
			ORDER BY TSymbol
		END
	END-- End of IF FC installed

end