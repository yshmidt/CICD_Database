-- =============================================
-- Author:		Yelena Shmidt
-- Create date: ?
-- Description: Check register page on the check form and reports
-- Modified : 
-- 11/25/13 YS change default values to 'All' from ' ', for all parameters, but dates. Added ability to pass multiple supplier list
-- 07/14/15	VL Added FC fields			
-- 02/06/17 VL added functional currency fields  
-- 08/31/17 VL added Fcused_uniq, FuncFcused_uniq, PRFcused_uniq and symbols
--- 07/11/18 YS supname increased from 30 to 50
-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
-- =============================================
CREATE PROCEDURE [dbo].[CheckRegView] 
	-- Add the parameters for the stored procedure here
	--01/15/13 YS change dates parametyers to be char() for the CR report
	--11/25/13 YS change default for All from empty to 'All' to make it concistent for all parameters but date
	@ldStartDt as char(10) = ' ',
	@ldEndDt as char(10) =' ',
	@lcStartCkNo as char(10)= '',
	@lcEndCkNo as char(10) ='',
	@lcUniqSupNo as varchar(max)='All',
	@lcBk_Uniq as char(10)= 'All',
	@lnStatus as int=1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--11/25/13 YS added ability to sent multiple suppliers
	DECLARE @tUnisupno TABLE (Uniqsupno char(10));
	--11/25/13 YS change default for All from empty to 'All' to make it concistent 
	if @lcUniqSupNo is not null and @lcUniqSupNo <>' ' and @lcUniqSupNo <>'All'
		INSERT INTO @tUnisupno  SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo  ,',')

-- 12/21/12 YS added dbo.fRemoveLeadingZeros for the @lcStartCkNo and @lcEndCkNo
    -- Insert statements for procedure here
    -- 09/04/12 YS change SP to use new  ReconcileStatus column
    --01/14/13 YS  when bank setup to have auto number use dbo.padl, when manual remove leading zeros
    IF @lnStatus=1   --- all transactions
		--11/25/13 YS change default for All from empty to 'All' to make it concistent and added uniqsupno
		-- 07/14/15 VL added CheckAmtFC
		-- 02/06/17 VL added CheckAmtPR
		--- 07/11/18 YS supname increased from 30 to 50
		SELECT ApChk_Uniq, Bank, Banks.Bk_Acct_no, dbo.fRemoveLeadingZeros(CheckNo) as iCheckno,Checkno, CheckDate, 
		ISNULL(SupName,CAST('N/A' as CHAR(50))) AS SupName,
		CheckAmt, ApChkMst.Status, 'Detail' AS Detail, CheckNote,ReconcileStatus,ReconcileDate,APCHKMST.UNIQSUPNO, CheckAmtFC, CheckAmtPR,
		-- 08/31/17 VL added Fcused_uniq, FuncFcused_uniq, PRFcused_uniq and symbols
		Apchkmst.Fcused_Uniq, FUNCFCUSED_UNIQ, PRFCUSED_UNIQ, ISNULL(FF.Symbol, SPACE(3)) AS FSymbol, ISNULL(TF.Symbol, SPACE(3)) AS TSymbol,ISNULL(PF.Symbol, SPACE(3)) AS PSymbol
		-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
		,ShipTo AS RemitTo    
		FROM  banks INNER JOIN apchkmst ON  Banks.bk_uniq = Apchkmst.bk_uniq
		LEFT OUTER JOIN supinfo 
   		ON  Apchkmst.uniqsupno = Supinfo.uniqsupno 
		LEFT OUTER JOIN @tUnisupno t on APCHKMST.UNIQSUPNO =t.Uniqsupno 
		-- 08/31/17 VL added to link to Fcused
		LEFT JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
		LEFT JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq			
		LEFT JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq		
		-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
		LEFT OUTER JOIN Shipbill ON APCHKMST.R_LINK = Shipbill.Linkadd
		WHERE CheckDate >=CASE WHEN @ldStartDt =' ' or @ldStartDt IS NULL THEN CheckDate ELSE CAST(@ldStartDt as DATE) END
		and CheckDate< CASE WHEN @ldEndDt=' ' or  @ldEndDt is null THEN CheckDate+1 ELSE DATEADD(Day,1,@ldEndDt) END
		AND Apchkmst.CHECKNO>=CASE WHEN @lcStartCkNo= 'All' OR @lcStartCkNo= '' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcStartCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcStartCkNo,10,'0') END
		AND Apchkmst.CHECKNO<=CASE WHEN @lcEndCkNo= 'All' OR @lcEndCkNo= '' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcEndCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcEndCkNo,10,'0') END
		AND ApChkMst.Bk_Uniq=CASE WHEN @lcBk_Uniq<>'All' THEN @lcBk_Uniq ELSE ApChkMst.Bk_Uniq END	
		AND 1= CASE WHEN @lcUniqSupNo ='All' THEN 1 
			WHEN t.Uniqsupno IS NOT NULL THEN 1 ELSE 0 ENd				
	
	IF 	@lnStatus=2 -- Printed/OS Only 
	--09/10/12 YS added and ApchkMst.ReconcileStatus=' '
	--11/25/13 YS change default for All from empty to 'All' to make it concistent and added uniqsupno
	-- 07/14/15 VL added CheckAmtFC
	-- 02/06/17 VL added CheckAmtPR
	--- 07/11/18 YS supname increased from 30 to 50
		SELECT ApChk_Uniq, Bank, Banks.Bk_Acct_no, dbo.fRemoveLeadingZeros(CheckNo) as iCheckno,Checkno, CheckDate, 
			ISNULL(SupName,CAST('N/A' as CHAR(50))) AS SupName,
			CheckAmt, ApChkMst.Status, 'Detail' AS Detail, CheckNote,ReconcileStatus,ReconcileDate  ,APCHKMST.UNIQSUPNO, CheckAmtFC, CheckAmtPR,    
			-- 08/31/17 VL added Fcused_uniq, FuncFcused_uniq, PRFcused_uniq and symbols
			Apchkmst.Fcused_Uniq, FUNCFCUSED_UNIQ, PRFCUSED_UNIQ, ISNULL(FF.Symbol, SPACE(3)) AS FSymbol, ISNULL(TF.Symbol, SPACE(3)) AS TSymbol,ISNULL(PF.Symbol, SPACE(3)) AS PSymbol
			-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
			,ShipTo AS RemitTo    
			FROM  banks INNER JOIN apchkmst
		LEFT OUTER JOIN supinfo 
   			ON  Apchkmst.uniqsupno = Supinfo.uniqsupno 
			ON  Banks.bk_uniq = Apchkmst.bk_uniq
			LEFT OUTER JOIN @tUnisupno t on APCHKMST.UNIQSUPNO =t.Uniqsupno 
		-- 08/31/17 VL added to link to Fcused
		LEFT JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
		LEFT JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq			
		LEFT JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq		
		-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
		LEFT OUTER JOIN Shipbill ON APCHKMST.R_LINK = Shipbill.Linkadd
		WHERE CheckDate >=CASE WHEN @ldStartDt =' ' or @ldStartDt IS NULL THEN CheckDate ELSE CAST(@ldStartDt as DATE) END
		and CheckDate< CASE WHEN @ldEndDt=' ' or  @ldEndDt is null THEN CheckDate+1 ELSE DATEADD(Day,1,@ldEndDt) END
		AND Apchkmst.CHECKNO>=CASE WHEN @lcStartCkNo= 'All' or @lcStartCkNo= '' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcStartCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcStartCkNo,10,'0') END
		AND Apchkmst.CHECKNO<=CASE WHEN @lcEndCkNo= 'All'  or @lcEndCkNo= '' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcEndCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcEndCkNo,10,'0') END
		AND ApChkMst.STATUS='Printed/OS' 
		and ApchkMst.ReconcileStatus=' '
		AND ApChkMst.Bk_Uniq=CASE WHEN @lcBk_Uniq<>'All' THEN @lcBk_Uniq ELSE ApChkMst.Bk_Uniq END	
		AND 1= CASE WHEN @lcUniqSupNo ='All' THEN 1 
			WHEN t.Uniqsupno IS NOT NULL THEN 1 ELSE 0 ENd	
	IF 	@lnStatus=3 -- Cleared Only 
	--11/25/13 YS change default for All from empty to 'All' to make it concistent and added uniqsupno
	-- 07/14/15 VL added CheckAmtFC
	-- 02/06/17 VL added CheckAmtPR
	--- 07/11/18 YS supname increased from 30 to 50
		SELECT ApChk_Uniq, Bank, Banks.Bk_Acct_no, dbo.fRemoveLeadingZeros(CheckNo) as iCheckno,Checkno, CheckDate, 
			ISNULL(SupName,CAST('N/A' as CHAR(50))) AS SupName,
			CheckAmt, ApChkMst.Status, 'Detail' AS Detail, CheckNote,ReconcileStatus,ReconcileDate,APCHKMST.UNIQSUPNO, CheckAmtFC, CheckAmtPR,
			-- 08/31/17 VL added Fcused_uniq, FuncFcused_uniq, PRFcused_uniq and symbols
			Apchkmst.Fcused_Uniq, FUNCFCUSED_UNIQ, PRFCUSED_UNIQ, ISNULL(FF.Symbol, SPACE(3)) AS FSymbol, ISNULL(TF.Symbol, SPACE(3)) AS TSymbol,ISNULL(PF.Symbol, SPACE(3)) AS PSymbol
			-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
			,ShipTo AS RemitTo    
			FROM  banks INNER JOIN apchkmst
		LEFT OUTER JOIN supinfo 
   			ON  Apchkmst.uniqsupno = Supinfo.uniqsupno 
			ON  Banks.bk_uniq = Apchkmst.bk_uniq
			LEFT OUTER JOIN @tUnisupno t on APCHKMST.UNIQSUPNO =t.Uniqsupno 
		-- 08/31/17 VL added to link to Fcused
		LEFT JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
		LEFT JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq			
		LEFT JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq		
		-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
		LEFT OUTER JOIN Shipbill ON APCHKMST.R_LINK = Shipbill.Linkadd
		WHERE CheckDate >=CASE WHEN @ldStartDt =' ' or @ldStartDt IS NULL THEN CheckDate ELSE CAST(@ldStartDt as DATE) END
		and CheckDate< CASE WHEN @ldEndDt=' ' or  @ldEndDt is null THEN CheckDate+1 ELSE DATEADD(Day,1,@ldEndDt) END
		AND Apchkmst.CHECKNO>=CASE WHEN @lcStartCkNo= 'All'  or @lcStartCkNo= 'All' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcStartCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcStartCkNo,10,'0') END
		AND Apchkmst.CHECKNO<=CASE WHEN @lcEndCkNo= 'All' or @lcEndCkNo= 'All' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcEndCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcEndCkNo,10,'0') END
		AND ApChkMst.ReconcileStatus IN ('C','R') 
		AND ApChkMst.Bk_Uniq=CASE WHEN @lcBk_Uniq<>'All' THEN @lcBk_Uniq ELSE ApChkMst.Bk_Uniq END	
		AND 1= CASE WHEN @lcUniqSupNo ='All' THEN 1 
			WHEN t.Uniqsupno IS NOT NULL THEN 1 ELSE 0 ENd					
	IF 	@lnStatus=4 -- Printed/OS Or Cleared 
	--11/25/13 YS change default for All from empty to 'All' to make it concistent and added uniqsupno
	-- 07/14/15 VL added CheckAmtFC
	-- 02/06/17 VL added CheckAmtPR
	--- 07/11/18 YS supname increased from 30 to 50
		SELECT ApChk_Uniq, Bank, Banks.Bk_Acct_no, dbo.fRemoveLeadingZeros(CheckNo) as iCheckno,Checkno, CheckDate, 
			ISNULL(SupName,CAST('N/A' as CHAR(50))) AS SupName,
			CheckAmt, ApChkMst.Status, 'Detail' AS Detail, CheckNote,ReconcileStatus,ReconcileDate ,APCHKMST.UNIQSUPNO, CheckAmtFC, CheckAmtPR,
			-- 08/31/17 VL added Fcused_uniq, FuncFcused_uniq, PRFcused_uniq and symbols
			Apchkmst.Fcused_Uniq, FUNCFCUSED_UNIQ, PRFCUSED_UNIQ, ISNULL(FF.Symbol, SPACE(3)) AS FSymbol, ISNULL(TF.Symbol, SPACE(3)) AS TSymbol,ISNULL(PF.Symbol, SPACE(3)) AS PSymbol
			-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
			,ShipTo AS RemitTo    
			FROM  banks INNER JOIN apchkmst
		LEFT OUTER JOIN supinfo 
   			ON  Apchkmst.uniqsupno = Supinfo.uniqsupno 
			ON  Banks.bk_uniq = Apchkmst.bk_uniq
			LEFT OUTER JOIN @tUnisupno t on APCHKMST.UNIQSUPNO =t.Uniqsupno 
		-- 08/31/17 VL added to link to Fcused
		LEFT JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
		LEFT JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq			
		LEFT JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq		
		-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
		LEFT OUTER JOIN Shipbill ON APCHKMST.R_LINK = Shipbill.Linkadd
		WHERE CheckDate >=CASE WHEN @ldStartDt =' ' or @ldStartDt IS NULL THEN CheckDate ELSE CAST(@ldStartDt as DATE) END
		and CheckDate< CASE WHEN @ldEndDt=' ' or  @ldEndDt is null THEN CheckDate+1 ELSE DATEADD(Day,1,@ldEndDt) END
		AND Apchkmst.CHECKNO>=CASE WHEN @lcStartCkNo= 'All' or @lcStartCkNo= '' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcStartCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcStartCkNo,10,'0') END
		AND Apchkmst.CHECKNO<=CASE WHEN @lcEndCkNo= 'All' OR @lcEndCkNo= '' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcEndCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcEndCkNo,10,'0') END
		AND (ApChkMst.STATUS='Printed/OS' OR ApChkMst.ReconcileStatus IN ('C','R') )
		AND ApChkMst.Bk_Uniq=CASE WHEN @lcBk_Uniq<>'All' THEN @lcBk_Uniq ELSE ApChkMst.Bk_Uniq END						
		AND 1= CASE WHEN @lcUniqSupNo ='All' THEN 1 
			WHEN t.Uniqsupno IS NOT NULL THEN 1 ELSE 0 ENd	
	
	IF 	@lnStatus=5 -- Void Transactions
	--11/25/13 YS change default for All from empty to 'All' to make it concistent and added uniqsupno
	-- 07/14/15 VL added CheckAmtFC
	-- 02/06/17 VL added CheckAmtPR
		SELECT ApChk_Uniq, Bank, Banks.Bk_Acct_no, dbo.fRemoveLeadingZeros(CheckNo) as iCheckno,Checkno, CheckDate, 
			ISNULL(SupName,CAST('N/A' as CHAR(50))) AS SupName,
			CheckAmt, ApChkMst.Status, 'Detail' AS Detail, CheckNote,ReconcileStatus,ReconcileDate ,APCHKMST.UNIQSUPNO, CheckAmtFC, CheckAmtPR,
			-- 08/31/17 VL added Fcused_uniq, FuncFcused_uniq, PRFcused_uniq and symbols
			Apchkmst.Fcused_Uniq, FUNCFCUSED_UNIQ, PRFCUSED_UNIQ, ISNULL(FF.Symbol, SPACE(3)) AS FSymbol, ISNULL(TF.Symbol, SPACE(3)) AS TSymbol,ISNULL(PF.Symbol, SPACE(3)) AS PSymbol
			-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
			,ShipTo AS RemitTo    
			FROM  banks INNER JOIN apchkmst
		LEFT OUTER JOIN supinfo 
   			ON  Apchkmst.uniqsupno = Supinfo.uniqsupno 
			ON  Banks.bk_uniq = Apchkmst.bk_uniq
			LEFT OUTER JOIN @tUnisupno t on APCHKMST.UNIQSUPNO =t.Uniqsupno 
		-- 08/31/17 VL added to link to Fcused
		LEFT JOIN Fcused PF ON Apchkmst.PrFcused_uniq = PF.Fcused_uniq
		LEFT JOIN Fcused FF ON Apchkmst.FuncFcused_uniq = FF.Fcused_uniq			
		LEFT JOIN Fcused TF ON Apchkmst.Fcused_uniq = TF.Fcused_uniq		
		-- 04/22/20 VL Added ShipTo as RemitTo, request by Paramit, zendesk#6244
		LEFT OUTER JOIN Shipbill ON APCHKMST.R_LINK = Shipbill.Linkadd
		WHERE CheckDate >=CASE WHEN @ldStartDt =' ' or @ldStartDt IS NULL THEN CheckDate ELSE CAST(@ldStartDt as DATE) END
		and CheckDate< CASE WHEN @ldEndDt=' ' or  @ldEndDt is null THEN CheckDate+1 ELSE DATEADD(Day,1,@ldEndDt) END
		AND Apchkmst.CHECKNO>=CASE WHEN @lcStartCkNo= 'All' or @lcStartCkNo= '' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcStartCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcStartCkNo,10,'0') END
		AND Apchkmst.CHECKNO<=CASE WHEN @lcEndCkNo= 'All' or @lcEndCkNo='' THEN Apchkmst.CHECKNO 
			WHEN Banks.XXCKNOSYS =0 THEN dbo.fRemoveLeadingZeros(@lcEndCkNo) 
			WHEN Banks.XXCKNOSYS =1 THEN dbo.padl(@lcEndCkNo,10,'0') END
		AND (ApChkMst.STATUS IN ('Void','Void/Reprinted') )
		AND ApChkMst.Bk_Uniq=CASE WHEN @lcBk_Uniq<>'All' THEN @lcBk_Uniq ELSE ApChkMst.Bk_Uniq END						
		AND 1= CASE WHEN @lcUniqSupNo ='All' THEN 1 
			WHEN t.Uniqsupno IS NOT NULL THEN 1 ELSE 0 ENd	
	
	
    	
END