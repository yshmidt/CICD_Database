-- =============================================
-- Author:		Yelena 
-- Create date: 01/12/2016
-- Description:	Find all Internal Parts using the same MPN
-- Parameter List:
-- Modified:
-- =============================================
CREATE PROCEDURE getInternalByMPN
	-- Add the parameters for the stored procedure here
	@mpn varchar(30) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	/*comma seperator*/
	--declare @tMpn table(mfgr_pt_no varchar(30))
	-- 01/12/16 for now impliment a single mpn. Multiple MPN separated with ',' is not going to work because a lot of MPNs has comma as part of the value 
	--if @mpn is not null and @mpn <> '' 
	--	insert into @tMpn select * from dbo.[fn_simpleVarcharlistToTable](@mpn,',')
	
	--select M.Uniq_key,P.Part_no,P.Revision,M.PartMfgr ,p.[Status]
	--	FROM Invtmfhd M inner join INVENTOR P on m.UNIQ_KEY=p.UNIQ_KEY
	--	inner join @tmpn t on m.MFGR_PT_NO=t.mfgr_pt_no
	--	where m.IS_DELETED=0 and m.MFGR_PT_NO<>' ' 
	--	and P.Part_sourc<>'CONSG'

	select L.Uniq_key,P.Part_no,P.Revision,M.PartMfgr ,m.mfgr_pt_no,p.[Status]
		FROM MfgrMaster M inner join InvtMpnLink L on m.mfgrmasterid=l.mfgrmasterid
		inner join INVENTOR P on l.UNIQ_KEY=p.UNIQ_KEY
		where m.IS_DELETED=0 and m.MFGR_PT_NO<>' '
		and l.is_deleted=0 
		and P.Part_sourc<>'CONSG'
		and @mpn<>' ' and @mpn is not null
		and m.MFGR_PT_NO=@mpn

END