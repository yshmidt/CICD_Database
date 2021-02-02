-- =============================================
-- Author:		Bill Blake
-- Create date: ?
-- Description:	used in accounts receivable  
---	i.e. deposits, NSF, AR Offset, AR write-off modules
--- Modified: 11/05/13 YS added terms and discount information, custname
-- use this view in the deposit form in place of [AcctRec4DepositView]
-- seems redundant to have both views
-- 03/24/15 VL added FC fields
-- 03/30/15 VL added A.INVTOTALFC - ARCREDITSFC <> 0 criteria for FC
-- 06/16/15 YS added new column isManualCM 
-- 06/16/15 YS check if FC used, and check for the appropriate balance
-- 10/17/16 VL added presentation currency
-- 01/13/17 VL added PrFcused_uniq and FuncFcused_uniq
-- =============================================
CREATE PROCEDURE [dbo].[AcctsRecOpenView] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 06/16/15 YS check if FC used, and check for the appropriate balance
	DECLARE @lFCInstalled bit
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
    
	-- Insert statements for procedure here
	SELECT A.CUSTNO
      ,[INVNO]
      ,A.INVDATE
      ,A.INVTOTAL
      ,[DUE_DATE]
      ,[ARCREDITS]
      ,[ARNOTE]
      ,[UNIQUEAR]
      ,[lPrepay]
      ,C.CustName
      ,isnull(P.TERMS ,SPACE(15)) as Terms
      ,ISNULL(t.Disc_Days ,cast(0 as numeric(3))) as Disc_days
      ,ISNULL(t.DISC_PCT,CAST(0.0 as numeric(4,1))) as disc_pct
	  ,cast (0000000.00 AS numeric(10,4)) as nDiscAvail,
	  A.INVTOTALFC, ArcreditsFC, cast (0000000.00 AS numeric(10,4)) as nDiscAvailFC, A.Fcused_uniq, A.FCHIST_KEY,
	 -- 06/16/15 YS added new column isManualCM
	  isManualCM,
	  -- 10/17/16 VL added InvtotalPR, ArcreditsPR and nDiscAvailPR
	  A.INVTOTALPR, A.ARCREDITSPR, cast (0000000.00 AS numeric(10,4)) as nDiscAvailPR,
	  -- 01/13/17 VL added PrFcused_uniq and FuncFcused_uniq
	  A.PRFcused_Uniq, A.FUNCFCUSED_UNIQ
  FROM [ACCTSREC] A LEFT OUTER JOIN PLMAIN P on A.invno =p.invoiceno 
  left outer join PMTTERMS T on p.TERMS=t.DESCRIPT
  INNER JOIN CUSTOMER C on A.CUSTNO =C.Custno
  WHERE 
  -- 06/16/15 YS check if FC used, and check for the appropriate balance
  (@lFCInstalled=0 and A.INVTOTAL - ARCREDITS <> 0)
  OR (@lFCInstalled=1 AND A.INVTOTALFC - ARCREDITSFC <> 0)

END