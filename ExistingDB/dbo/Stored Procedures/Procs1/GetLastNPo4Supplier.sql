

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/05/2012
-- Description:	Get Last n POs for a part and specific supplier 
-- =============================================
CREATE PROCEDURE [dbo].[GetLastNPo4Supplier]
	-- Add the parameters for the function here
	@lcUniq_key char(10) = '',
	@lcUniqSUpno char(10)='',
	@lnNumberOfPOsIncluded int = 5
AS
BEGIN
	SET NOCOUNT ON;	
	-- Add the SELECT statement with parameter references here
	SELECT TOP(@lnNumberOfPOsIncluded ) VerDate ,Supname ,Pomain.Ponum ,PartMfgr,
	Costeach ,Ord_qty ,Podate ,Mfgr_pt_no,Uniq_key,Poitems.UniqLnNo
		FROM pomain,poitems,supinfo
		where Poitems.Ponum=Pomain.Ponum
		AND Pomain.uniqsupno=@lcUniqSUpno 
		AND Poitems.uniq_key=@lcUniq_key
		AND Pomain.UniqSupno=Supinfo.UniqSUpno
		AND Poitems.lCancel=0
		AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED') 
		 order by verdate DESC,pomain.ponum DESC
END