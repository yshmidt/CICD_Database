-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <11/19/2010>
-- Description:	<All Invtmfgr records for a PO>
-- Modified: 10/09/14 YS removed invtmfhd table and added 2 new tables
-- 10/29/14    move orderpref to invtmpnlink
-- =============================================
CREATE PROCEDURE [dbo].[Invtmfhd4POView]
	-- Add the parameters for the stored procedure here
	@pcPoNum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 10/09/14 YS removed invtmfhd table and added 2 new tables
    -- Insert statements for procedure here
	SELECT DISTINCT l.UNIQ_KEY,l.UNIQMFGRHD,m.PARTMFGR,m.MFGR_PT_NO,m.AUTOLOCATION,
		m.MATLTYPE ,m.MARKING,m.MATLTYPEVALUE,l.IS_DELETED,m.LDISALLOWBUY,
		l.ORDERPREF           
		FROM InvtMPNLink L INNER JOIN MfgrMaster M ON l.mfgrmasterid=m.mfgrmasterid
		WHERE Exists (SELECT 1 from POITEMS WHere POITEMS.PONUM=@pcPoNum
					AND POITEMS.UNIQ_KEY = l.UNIQ_KEY) 
		
		
		
END