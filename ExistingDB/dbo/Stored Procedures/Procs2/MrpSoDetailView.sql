-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/09/12
-- Description:	Open Sales Orders for specific Level (Used in MRP)
--11/08/15 YS remove  buy parts
--11/19/15 YS added temporary solution for the missing forecast. Vicky added new status for the so detail item 'Forecast'
-- will use this to drive components demands for that item, but not a work order actions
--11/20/15 YS add flag 0 by default, 1 if forecast item. It will allow me to  set the index for the forecast items after the regular items
-- =============================================
CREATE PROCEDURE [dbo].[MrpSoDetailView] 
	-- Add the parameters for the stored procedure here
	@mrp_code int = 0 
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	--11/08/15 YS remove  buy parts. Different procedure MrpSalesView is used for the buy parts
	--11/19/15 YS added temporary solution for the missing forecast. Vicky added new status for the so detail item 'Forecast'
	-- will use this to drive components demands for that item, but not a work order actions
	--11/20/15 YS add flag 0 by default, 1 if forecast item. It will allow me to  set the index for the forecast items after the regular items in the application, use integer type
	SELECT DISTINCT SoDetail.SoNo, SoDetail.Uniqueln, SoDetail.Uniq_Key, Ship_Dts, 
		Qty AS ReqQty, 
		CAST(CASE WHEN is_rma=1 THEN 'Dem RMA' 
			--11/19/15 YS added temporary solution for the missing forecast
			WHEN sodetail.Status='Forecast' THEN 'FC'
			ELSE 'Dem SO' END 
			+ dbo.PADR(SoDetail.SoNo,20,' ')  as char(24)) AS Ref,
		DueDt_Uniq,	PrjUnique, @mrp_code AS Testlevel, LP.Mrp_Code, Sodetail.Lfcstitem, SoMain.Custno  ,
		LP.Scrap,LP.Make_buy,LP.Phant_make, 
		case when sodetail.Status='Forecast' THEN cast(1 as integer) else cast(0 as int) end as is_Forecast 
		FROM SoMain INNER JOIN SoDetail ON SoMain.SoNo = SoDetail.SoNo
		INNER JOIN Due_dts ON SoDetail.Uniqueln = Due_dts.Uniqueln
		INNER JOIN Inventor LP ON LP.Uniq_Key = SoDetail.Uniq_Key 
		WHERE  SoMain.Ord_Type = 'Open' 
		AND Qty > 0 
		AND UPPER(SoDetail.Status) NOT IN ('CLOSED','CANCEL')
		AND SoDetail.MrponHold=0 
		AND SoDetail.Uniq_Key<>' '
		AND LP.Mrp_Code = @mrp_code
		AND Make_Buy =0 and lp.part_sourc<>'BUY'
		AND ((SoMain.SoApproval=1 AND is_rma=0) OR  Is_rma=1)  
END