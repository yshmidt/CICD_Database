-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/27/2011
-- Description:	Drill Down DM
-- Modification:
-- 09/15/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added functional and presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownDM]
	-- Add the parameters for the stored procedure here
	@UniqDmHead char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 05/27/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
   	SELECT DmDate as Trans_Dt, dmemos.UniqSupno,Supinfo.SUPNAME,  
		DMemoNo , DmTotal ,nDiscAmt,Dmemos.DMTYPE,Dmemos.DMNOTE,
		Dmemos.UniqDmHead ,APDMDETL.UNIQDMDETL,Dmemos.INVNO, 
		ApDmDetl.ITEM_TOTAL ,ApdmDetl.ITEM_NO,
		ApDmDetl.ITEM_DESC,
		ApdmDetl.UNIQDMDETL,
		dmemos.UNIQAPHEAD,APDMDETL.UNIQAPDETL,
		DmTotalFC ,nDiscAmtFC , ApDmDetl.ITEM_TOTALFC     
	FROM Dmemos INNER JOIN SUPINFO on Dmemos.UNIQSUPNO = supinfo.UNIQSUPNO 
	INNER JOIN APDMDETL on dmemos.UNIQDMHEAD = APDMDETL.UNIQDMHEAD 
	WHERE Dmemos.UNIQDMHEAD =@UniqDmHead 
ELSE
	-- 12/13/16 VL: added functional and presentation currency fields
  	SELECT DmDate as Trans_Dt, dmemos.UniqSupno,Supinfo.SUPNAME,  
		DMemoNo , DmTotal ,nDiscAmt,Dmemos.DMTYPE,Dmemos.DMNOTE,
		Dmemos.UniqDmHead ,APDMDETL.UNIQDMDETL,Dmemos.INVNO, 
		ApDmDetl.ITEM_TOTAL ,ApdmDetl.ITEM_NO,
		ApDmDetl.ITEM_DESC,
		ApdmDetl.UNIQDMDETL,
		dmemos.UNIQAPHEAD,APDMDETL.UNIQAPDETL,FF.Symbol AS Functional_Currency,
		DmTotalFC ,nDiscAmtFC , ApDmDetl.ITEM_TOTALFC, TF.Symbol AS Transaction_Currency,
		DmTotalPR ,nDiscAmtPR , ApDmDetl.ITEM_TOTALPR, PF.Symbol AS Presentation_Currency          
	FROM Dmemos
				INNER JOIN Fcused TF ON Dmemos.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON Dmemos.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Dmemos.FuncFcused_uniq = FF.Fcused_uniq
	INNER JOIN SUPINFO on Dmemos.UNIQSUPNO = supinfo.UNIQSUPNO 
	INNER JOIN APDMDETL on dmemos.UNIQDMHEAD = APDMDETL.UNIQDMHEAD 
	WHERE Dmemos.UNIQDMHEAD =@UniqDmHead 	
		
END