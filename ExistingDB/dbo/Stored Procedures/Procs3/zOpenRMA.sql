-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/08/2012
-- Description:	get information for MRP replaces ZOpenRMA cursor
-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
-- =============================================
CREATE PROCEDURE [dbo].[zOpenRMA]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT DISTINCT SoDetail.SoNo, SoDetail.Uniqueln, SoDetail.Uniq_Key, Ship_Dts, -Qty AS Balance, 
	CAST('Supl RMA' + SoDetail.SoNo as CHAR(24)) AS Ref,DueDt_Uniq, 
	Ship_Dts AS ReqDate, 
	-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
	PrjUnique, 'RMA' + RIGHT(SoMain.SoNo,7) AS WoNo,'ReworkFirm' AS JobType,'Open' as OpenClos,
	Z.Make_buy,Z.Phant_make,Z.Mrp_code,Z.SCRAP
	FROM SoMain INNER JOIN  SoDetail ON SoMain.SoNo = SoDetail.SoNo 
	INNER JOIN Due_dts ON SoDetail.Uniqueln = Due_dts.Uniqueln
	INNER JOIN Inventor Z ON Z.Uniq_key=SoDetail.Uniq_key
	WHERE is_rma=1 
	AND SoMain.Ord_Type = 'Open' 
	AND Qty < 0 
	AND (UPPER(SoDetail.Status) <> 'CLOSED' AND UPPER(SoDetail.Status) <> 'CANCEL')
	AND  SoDetail.MrponHold =0
	AND  SoDetail.Uniq_Key<>' '
END