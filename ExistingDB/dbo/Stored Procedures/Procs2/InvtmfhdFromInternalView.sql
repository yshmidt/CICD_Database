-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/07/2010>
-- Description:	<InvtMfhdView>
-- Modified:	10/09/14 YS removed invtmfhd table and replaced with 2 new
-- 10/24/14 YS added mfgrmasterid
-- 10/29/14    move orderpref to invtmpnlink
-- =============================================
CREATE PROCEDURE [dbo].[InvtmfhdFromInternalView]
	-- Add the parameters for the stored procedure here
	@cInt_Uniq char(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 10/09/14 YS removed invtmfhd table and replaced with 2 new
	-- 10/29/14    move orderpref to invtmpnlink
	SELECT DISTINCT M.PartMfgr, Text AS PartMfgrDescript, M.Mfgr_Pt_No,M.MatlType,L.OrderPref ,m.MfgrMasterId
	FROM InvtMpnLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	INNER JOIN Support ON M.partmfgr = dbo.padr(rtrim(LTRIM(Support.text2)),8,' ')
	AND RTRIM(LTRIM(Support.fieldname)) = 'PARTMFGR'
	WHERE L.Uniq_key = @cInt_Uniq 
	AND l.Is_Deleted=0 and m.IS_DELETED=0  ORDER BY OrderPref 
END
