-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <02/24/2010>
-- Description:	<InvtMfhdView>
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables, added mfgrmasterid
-- 10/29/14    move orderpref to invtmpnlink
-- 03/24/15   Added part_pkg column (was in the inventor table,will remove)
--09/28/17 YS convert(int,[MfgrMasterId]) as [MfgrMasterId] untill desk top is removed. VFP cannot handle bigint
-- =============================================
CREATE PROCEDURE [dbo].[InvtmfhdView]
	-- Add the parameters for the stored procedure here
	@gUniq_key char(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	-- 03/24/15   Added part_pkg column (was in the inventor table,will remove)
	SELECT L.uniqmfgrhd, M.partmfgr, L.uniq_key,
	M.mfgr_pt_no, M.marking, M.body, M.pitch,
	M.part_spec, M.uniqpkg, Syspkg.pkg, L.is_deleted,
	M.matltype, M.autolocation, Support.text AS mfgrdescr,
	l.orderpref, CAST(0.00 as numeric(12,2)) AS totavlqty,
	M.matltypevalue, M.ldisallowbuy, M.ldisallowkit,
	--09/28/17 YS convert(int,[MfgrMasterId]) as [MfgrMasterId] untill desk top is removed. VFP cannot handle bigint
	M.sftystk,m.Part_pkg, convert(int,m.MfgrMasterId) as [MfgrMasterId]
	FROM InvtMPNLink L inner join MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId 
	inner join SUpport ON  RTRIM(LTRIM(Support.fieldname)) = 'PARTMFGR'
    AND  M.partmfgr = dbo.padr(rtrim(LTRIM(Support.text2)),8,' ')
    LEFT OUTER JOIN syspkg 
	ON  M.uniqpkg = Syspkg.uniqpkg
	WHERE  L.uniq_key = @gUniq_Key
	ORDER BY l.orderpref
END