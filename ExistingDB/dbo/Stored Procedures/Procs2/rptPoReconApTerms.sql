
-- =============================================
-- Author:			Debbie
-- Create date:		04/01/2013
-- Description:		Created for the AP Terms Verification Report
-- Reports:			aptermvr
-- Modifications:   
-- =============================================

CREATE PROCEDURE [dbo].[rptPoReconApTerms]

	@userId uniqueidentifier = null

as
Begin

SELECT	DISTINCT	Supinfo.SupName,Supinfo.Terms as SupTerms,Poitschd.Ponum,Porecloc.Receiverno
		,Pomain.Terms as PoTerms,Pomain.UniqSupno			
FROM	Porecloc,Poitschd,pomain,supinfo
WHERE	Porecloc.AccptQty<>0
		AND Porecloc.Sdet_uniq = ''
		AND Poitschd.UniqDetNo=Porecloc.UniqDetno
		AND Pomain.Ponum=Poitschd.Ponum
		AND Supinfo.UniqSupno=Pomain.UniqSupno
		AND Supinfo.Terms<>Pomain.Terms
ORDER BY Supinfo.Supname,Porecloc.Receiverno,Poitschd.Ponum

end