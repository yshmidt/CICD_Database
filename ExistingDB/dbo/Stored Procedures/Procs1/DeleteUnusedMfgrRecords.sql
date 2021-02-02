-- =============================================
-- Author:		<Asset A.>
-- Create date: <12/9/2020>
-- Description:	<Deletes all Unused Manufacturers from Part Manufacturer Setup>
-- =============================================
CREATE procedure [dbo].[DeleteUnusedMfgrRecords]
as
with mfgrdelelte
as
(
select UNIQFIELD,text2 from support where fieldname='PARTMFGR' 
and Text2<>'GENR'
and not exists (select 1 from MfgrMaster  where support.text2=mfgrmaster.partmfgr)
UNION
SELECT UNIQFIELD,text2 from support where fieldname='PARTMFGR' 
and TRIM(Text2) IN
(select partmfgr from MfgrMaster 
where not exists (select 1 from Invtmpnlink l where MfgrMaster.MfgrMasterId=l.MfgrMasterId)
and not (MfgrMaster.Partmfgr='GENR' and mfgr_pt_no=''))
)
delete from support where UNIQFIELD in (select UNIQFIELD from mfgrdelelte)