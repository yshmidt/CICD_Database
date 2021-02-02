-- =============================================
-- Author:		Debbie
-- Create date: 09/02/2011
-- Description:	This Stored Procedure was created for the "In Store Items Without Contract"
-- Reports Using Stored Procedure:  icrpt13.rpt
-- Modified:	10/13/14 YS replaced invtmfhd table	  
--				10/03/16:  needed to add a filter to not include inventory parts that have the status of Inactive  
--02/03/17 YS contract tables are changed 
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtWithoutContract]
@userid uniqueidentifier = null
as
begin

SELECT	invtmfgr.uniq_key,part_no,Revision,part_sourc,PART_CLASS,PART_TYPE
		,DESCRIPT,PARTMFGR,MFGR_PT_NO,WAREHOUSE,LOCATION,INSTORE,invtmfgr.uniqsupno
		,SUPNAME,BUYER_TYPE as buyer
		
from	invtmfgr,inventor,InvtMPNLink L, MfgrMaster M, WAREHOUS,SUPINFO

where	invtmfgr.uniq_key = inventor.uniq_key
--10/13/14 YS replaced invtmfhd table
		AND invtmfgr.uniqmfgrhd = l.uniqmfgrhd
		and INVTMFGR.UNIQWH = WAREHOUS.UNIQWH
		and INVTMFGR.uniqsupno = SUPINFO.UNIQSUPNO
		AND invtmfgr.instore = 1
		AND invtmfgr.is_deleted =0
		AND l.is_deleted =0
		and inventor.status <> 'Inactive'	--10/03/16:  Added
		AND NOT EXISTS 
		--02/03/17 YS contract tables are changed 
			(SELECT c.contr_uniq 
			FROm contractheader h inner join Contract C on h.contracth_unique=c.contracth_unique
					INNER JOIN  contmfgr on c.contr_uniq = contmfgr.contr_uniq
			WHERE c.UNIQ_KEY=Inventor.UNIQ_KEY 
			and CONTMFGR.PARTMFGR=m.Partmfgr
			and CONTMFGR.MFGR_PT_NO=m.MFGR_PT_NO 
			and Invtmfgr.uniqsupno =h.UniqSupno)
end
			