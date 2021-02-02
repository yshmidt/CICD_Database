-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 
-- Description:	
-- Modifications: 05/20/14 YS added poitems.itemno
-- Modifications: 11/08/17 : Satish B : Convert Poitems.costeach into string and select costeachstr to display in history grid with decimal places
-- exec GetPoHistory '_01F15SZH9','PODATE',10,'APPROVED'
-- =============================================
-- This View will gather given number of POs (@lnNumberOfPOsIncluded) with given status (@lcPoStatus) for a speicif part (guniq_key) 
CREATE proc [dbo].[GetPoHistory] 
	(@gUniq_key char(10) = null,@lcDateOrder char(10)='PODATE',@lnNumberOfPOsIncluded int=10, @lcPoStatus char(15) = 'APPROVED' )
AS
BEGIN
	---Possible values for @lcPoStatus
	---- @lcPoStatus='APPROVED' (default) - all pos with status 'OPEN' or 'CLOSED'
	---- @lcPoStatus='NOT APPROVED' - all pos with statis 'NEW' OR  'EDITING'
	---- @lcPoStatus='ALL' - all pos 

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	  
	DECLARE	@cmd VARCHAR(1000)
	-- Insert statements for procedure here
	-- 05/20/14 YS added poitems.itemno
	SET @cmd = 'SELECT TOP '+ CAST(@lnNumberOfPOsIncluded as char(3)) +
			' Pomain.podate,Pomain.VerDate, PoMain.PoStatus, '+
			' Supinfo.supname, Pomain.ponum,Poitems.Itemno,Poitems.partmfgr,'+
			--11/08/17 : Satish B : Convert Poitems.costeach into string and select costeachstr to display in history grid with decimal places
			'  Poitems.mfgr_pt_no,Poitems.costeach,Poitems.ord_qty,CAST(Poitems.costeach AS VARCHAR(22)) AS costeachstr'+ 
			' FROM   pomain,    supinfo,    poitems '+
			' WHERE Pomain.ponum = Poitems.ponum '+
			' AND  Supinfo.uniqsupno = Pomain.uniqsupno '+ 
			' AND  Poitems.uniq_key ='''+@gUniq_key+''''+
			CASE WHEN  @lcPoStatus='APPROVED' THEN ' AND (POSTATUS='+'''OPEN'''+' OR POSTATUS='+'''CLOSED''' +')'
			WHEN @lcPoStatus='NOT APPROVED' THEN ' AND (POSTATUS='+'''NEW'''+' OR POSTATUS='+'''EDITING'''+')'
			ELSE '' END + 
			' AND  Poitems.lcancel=0 '+
			' ORDER BY '+
			CASE WHEN (@lcDateOrder='PODATE') THEN ' Pomain.podate DESC' ELSE 'Pomain.VerDate DESC' END
	

	EXEC (@cmd)

END
  


