-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/18/2010>
-- Description:	<Find all the locations for the given UniqMfgrhd with parts in Cycle Count or PI>
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new
-- =============================================
CREATE PROCEDURE [dbo].[InvtMfHdCountFlagView]
	@lcUniqMfgrhd char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 10/09/14 YS removed invtmfhd table and replaced with 2 new
	SELECT M.Partmfgr,M.Mfgr_pt_no,Invtmfgr.CountFlag  
	FROM Invtmfgr INNER JOIN Invtmpnlink L ON Invtmfgr.UNIQMFGRHD=L.uniqmfgrhd
	INNER JOIN MfgrMaster M on L.mfgrMasterId=M.MfgrMasterId  
	WHERE l.UniqMfgrHd =@lcUniqMfgrhd
	AND Invtmfgr.CountFlag<>' '
    
END