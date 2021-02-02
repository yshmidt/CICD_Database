

CREATE PROCEDURE [dbo].[BkAdMainView]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 07/13/15 VL added FC
	-- 02/15/17 VL added functional currency code
    -- Insert statements for procedure here
	SELECT Bkadmain.uniqbkadmn, Bkadmain.fk_bk_uniq, Bkadmain.setupdate,
  Bkadmain.dayofmo, Bkadmain.pmtamt, Bkadmain.descript, Bkadmain.maxpmts,
  Bkadmain.pmtsded, Bkadmain.firstpmt, Bkadmain.lastpmtgen,
  Bkadmain.editdate, Bkadmain.init, Bkadmain.reason, Bkadmain.is_closed,
  Bkadmain.adnote, Banks.bk_acct_no, Banks.accttitle, Banks.bank, 
  Bkadmain.pmtamtFC, Bkadmain.Fcused_uniq, Bkadmain.Fchist_key,
  Bkadmain.pmtamtPR, PrFcused_uniq, FuncFcused_uniq
 FROM 
     bkadmain 
    INNER JOIN banks 
   ON  Bkadmain.fk_bk_uniq = Banks.bk_uniq

END