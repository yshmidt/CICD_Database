-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/30/16
-- Description:	use this SP to find which sales order is using MPN. Will be used in the inventory module when MPn is removed for the validation
-- =============================================
CREATE PROCEDURE GetSOBuyPartsWithMpn
	-- Add the parameters for the stored procedure here
	@Uniq_key char(10),@uniqmfgrhd char(10)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- sales order is saving w_key for now, will use Uniqmfgrdh to find which w_key are attached
	SELECT s.Sono,S.Line_no,s.balance,
			s.w_key,s.UniqueLn,mh.partmfgr,mh.mfgr_pt_no
			FROM  Sodetail s inner join invtmfgr MW on s.w_key=mw.W_KEY
			inner join InvtMpnLink L on L.uniqmfgrhd=mw.uniqmfgrhd
			inner join mfgrmaster MH on l.mfgrmasterid=mh.mfgrmasterid
			inner join somain sm on s.sono=sm.sono
			WHERE s.Uniq_key=@Uniq_key 
			and sm.ord_type NOT IN ('Closed','Cancel') 
			AND S.[Status] not in ('Closed','Cancel')
			and mw.uniqmfgrhd=@uniqmfgrhd
			AND S.Balance>0 			

END