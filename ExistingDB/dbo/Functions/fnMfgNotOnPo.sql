-- =============================================
-- Author:		Debbie Peltier
-- Create date: 09/15/2014
-- Description:	Gathers the mfgrs that are not included on the PO
-- Modified:	10/15/15 DRP:  I needed to filter out Deleted Mfgrs from the results. 
-- 02/08/16 YS remove invtmfhd table and use invtmpnlnk and mfgrmaster
-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code, request by Keltech
-- 03/06/20 VL changed the output only show full name of Partmfgr, don't show code because it provides too much information and looks like duplicate on the report
-- =============================================
CREATE FUNCTION [dbo].[fnMfgNotOnPo]
( 
    @lcUniqlnno char (10) = ''
) 
RETURNS varchar(max) 
AS 
BEGIN 
    declare	@output varchar(max) 
	-- 02/08/16 YS remove invtmfhd table and use invtmpnlnk and mfgrmaster
	-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code, request by Keltech
	--select	@output = rtrim(coalesce (@output + char(13)+CHAR(10),'') +'MFgr: ' + rtrim(mfhd2.PARTMFGR) + ' MPN: '+ RTRIM(mfhd2.MFGR_PT_NO) + ' Matl Type: '+ rtrim(mfhd2.matltype)) 
	-- 03/06/20 VL changed the output only show full name of Partmfgr, don't show code because it provides too much information and looks like duplicate on the report
	--select	@output = rtrim(coalesce (@output + char(13)+CHAR(10),'') +'MFgr: ' + rtrim(mfhd2.PARTMFGR) + ' / '+rtrim(ltrim(mfhd2.PartMfgrName))+' MPN: '+ RTRIM(mfhd2.MFGR_PT_NO) + ' Matl Type: '+ rtrim(mfhd2.matltype)) 
	select	@output = rtrim(coalesce (@output + char(13)+CHAR(10),'') +'MFgr: ' +rtrim(ltrim(mfhd2.PartMfgrName))+' MPN: '+ RTRIM(mfhd2.MFGR_PT_NO) + ' Matl Type: '+ rtrim(mfhd2.matltype)) 
	from	poitems OUTER APPLY 
	-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code, request by Keltech
	(select m.partmfgr,m.mfgr_pt_no,m.matltype,l.uniq_key,l.Uniqmfgrhd, ISNULL(LEFT(Text,30),SPACE(30)) AS PartMfgrName
	from InvtMPNLink as L INNER JOIN MfgrMaster M on l.Mfgrmasterid=m.mfgrmasterid 
		-- 02/18/20 VL added partmfgr full name because suppliers really don't have ideas what's the partmfgr code, request by Keltech
		LEFT OUTER JOIN Support ON m.Partmfgr = LEFT(Text2,8) AND Support.FIELDNAME = 'PARTMFGR'
		WHERE m.is_deleted=0 and l.is_deleted=0
		and poitems.UNIQ_KEY = L.UNIQ_KEY and POITEMS.UNIQMFGRHD <> L.UNIQMFGRHD ) mfhd2  
	where	uniqlnno  = @lcUniqlnno
			
	
    return @output 
END 