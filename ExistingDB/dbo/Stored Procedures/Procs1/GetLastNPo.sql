

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified 05/20/14 YS added itemno per request from Rocket
-- =============================================
CREATE PROCEDURE [dbo].[GetLastNPo]
	-- Add the parameters for the function here
	@lcUniq_key char(10) = '',
	@lnNumberOfPOsIncluded int = 5
AS
BEGIN
	SET NOCOUNT ON;	
	-- 05/20/14 YS added itemno per request from Rocket
	-- Add the SELECT statement with parameter references here
	SELECT TOP(@lnNumberOfPOsIncluded ) VerDate ,Supname ,Pomain.Ponum ,Poitems.Itemno,PartMfgr,
	Costeach ,Ord_qty ,Podate ,Mfgr_pt_no,Uniq_key,Poitems.UniqLnNo
		FROM pomain,poitems,supinfo
		where Poitems.Ponum=Pomain.Ponum
		AND Pomain.UniqSupno=Supinfo.UniqSUpno
		AND Poitems.lCancel=0
		AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED') 
		AND Poitems.uniq_key=@lcUniq_key order by verdate DESC,pomain.ponum DESC
END