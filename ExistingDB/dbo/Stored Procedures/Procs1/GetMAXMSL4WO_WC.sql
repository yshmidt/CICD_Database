CREATE PROCEDURE [dbo].[GetMAXMSL4WO_WC] 
	-- Add the parameters for the stored procedure here
	@wono char(10) = NULL,  --- if @wono = null empty data set will be returned
	@Dept_id char(4) = NULL--- if @Dept_id = null the dataset will include all work centers for a given work order
AS
DECLARE
@MOISTURE Nvarchar(3);
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Get maximum Msl value
	select @MOISTURE=max(m.MOISTURE)
	from iReserveIpKey IR left outer join iReserveIpKey IU on ir.ipkeyunique=iu.ipkeyunique and ir.KaSeqnum=iu.KaSeqnum and iu.qtyAllocated<0
	inner join invt_res r on ir.invtres_no=r.INVTRES_NO
	inner join inventor i on r.UNIQ_KEY=i.UNIQ_KEY
	inner join invtmfgr q on r.W_KEY=q.W_KEY
	inner join InvtMPNLink l on q.UNIQMFGRHD=l.uniqmfgrhd
	inner join MfgrMaster m on l.MfgrMasterId=m.MfgrMasterId
	where m.MOISTURE<>'' and 
	ir.qtyAllocated>0 and
	exists (select 1 from kamain where dbo.fRemoveLeadingZeros(Wono)=dbo.fRemoveLeadingZeros(@wono) and (@Dept_id is null or DEPT_ID=@Dept_id) and kamain.KASEQNUM=ir.KaSeqnum);
	
	--Get Msl data of maximum MSL
	select m.PartMfgr,m.mfgr_pt_no,i.PART_NO,i.REVISION,ir.ipkeyunique as MTC,m.MOISTURE as MSL,
	CAST(NULL as datetime) as EndMslTime, 
	ir.invtres_no,ir.qtyAllocated,
	--- will replace this when I have new table where the start time for MSL will be enterd
	isnull(sum(iu.qtyallocated),0.00) as sumUnalloc,ir.KaSeqnum,r.UNIQ_KEY,r.W_KEY,q.UNIQMFGRHD,m.MfgrMasterId, mnl.Hours
	from iReserveIpKey IR left outer join iReserveIpKey IU on ir.ipkeyunique=iu.ipkeyunique and ir.KaSeqnum=iu.KaSeqnum and iu.qtyAllocated<0
	inner join invt_res r on ir.invtres_no=r.INVTRES_NO
	inner join inventor i on r.UNIQ_KEY=i.UNIQ_KEY
	inner join invtmfgr q on r.W_KEY=q.W_KEY
	inner join InvtMPNLink l on q.UNIQMFGRHD=l.uniqmfgrhd
	inner join MfgrMaster m on l.MfgrMasterId=m.MfgrMasterId
	left join MNXMSLLevel mnl on m.MOISTURE=mnl.MSL
	where m.MOISTURE<>'' and ir.qtyAllocated>0 and m.MOISTURE=@MOISTURE and
	exists (select 1 from kamain where dbo.fRemoveLeadingZeros(Wono)=dbo.fRemoveLeadingZeros(@wono) and (@Dept_id is null or DEPT_ID=@Dept_id) and kamain.KASEQNUM=ir.KaSeqnum) and m.MOISTURE=@MOISTURE
	group by m.PartMfgr,m.mfgr_pt_no,i.PART_NO,i.REVISION,ir.ipkeyunique ,ir.invtres_no,ir.qtyAllocated,ir.KaSeqnum,
	r.UNIQ_KEY,r.W_KEY,q.UNIQMFGRHD,m.MfgrMasterId,m.MOISTURE,mnl.Hours
	HAVING ir.qtyAllocated-isnull(sum(iu.qtyallocated),0.00) >0
	ORDER BY m.MOISTURE Desc
END