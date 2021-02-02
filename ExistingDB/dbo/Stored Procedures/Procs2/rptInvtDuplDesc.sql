-- =============================================
-- Author:		Debbie
-- Create date: 08/12/2011
-- Description:	This Stored Procedure was created for the "List of Duplicate Descriptions"
-- Reports:		icrpt12.rpt
-- Modified:	10/28/15 DRP:  Needed to added "where	part_sourc <> 'CONSG'" to the ZDupDesc without it we were getting too many results(incorrect results)
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtDuplDesc]
@userid uniqueidentifier = null
as
begin
							
;
with ZDupDesc as	(
					select	DESCRIPT,COUNT(*)as NCount
					from	INVENTOR
					where	part_sourc <> 'CONSG'	--10/28/15 DRP:  Added
					group by DESCRIPT
					)
					,
				
ZInvtPart as		(
					select inventor.UNIQ_KEY, PART_NO, REVISION, PART_CLASS, PART_TYPE, DESCRIPT, STATUS, sum(QTY_OH) as TotQty_oh
					from INVENTOR
					left outer join INVTMFGR on INVENTOR.UNIQ_KEY = INVTMFGR.UNIQ_KEY
					where IS_DELETED = 0
					AND PART_SOURC <> 'CONSG'
					group by inventor.UNIQ_KEY, PART_NO, REVISION, PART_CLASS, PART_TYPE, descript, Status
					)
				
select zinvtPart.uniq_key, PART_NO, REVISION, PART_CLASS, PART_TYPE, ZDupDesc.DESCRIPT, ZInvtPart.STATUS, ZInvtPart.TotQty_oh
from ZDupDesc
inner join ZInvtPart on ZDupDesc.DESCRIPT = ZInvtPart.DESCRIPT
where NCount > 1
order by DESCRIPT

end

 