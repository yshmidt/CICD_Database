-- =============================================
-- Author:		Debbie
-- Create date: 09/06/2011
-- Modified:
-- Description:	This Stored Procedure was created for the "In Store Issued Items Without Contract"
-- Reports Using Stored Procedure:  icrpt14.rpt
-- 06/13/18 YS contract structere changed 
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtIssuWoutContract]
@userid uniqueidentifier = null
AS
BEGIN
-- 06/13/18 YS contract structere changed
select distinct	POSTORE.UNIQ_KEY, PARTMFGR, MFGR_PT_NO, PONUM, PART_NO, REVISION, PART_CLASS, PART_TYPE, DESCRIPT, INVENTOR.BUYER_TYPE as Buyer, SUPINFO.SUPNAME,SUPINFO.SUPID,postore.UNIQSUPNO

from	POSTORE inner join INVENTOR on iNVENTOR.UNIQ_KEY = POSTORE.UNIQ_KEY
inner join supinfo on SUPINFO.UNIQSUPNO = POSTORE.UNIQSUPNO
where postore.PONUM = ''
		AND NOT EXISTS 
			(SELECT 1
			FROm Contract INNER JOIN  contmfgr on contract.contr_uniq = contmfgr.contr_uniq
			inner join contractHeader h on contract.contracth_unique=h.contracth_unique
			WHERE contract.UNIQ_KEY=Inventor.UNIQ_KEY 
			and CONTMFGR.PARTMFGR=POSTORE.Partmfgr
			and CONTMFGR.MFGR_PT_NO=POSTORE.MFGR_PT_NO 
			and POSTORE.uniqsupno =H.UniqSupno)
END