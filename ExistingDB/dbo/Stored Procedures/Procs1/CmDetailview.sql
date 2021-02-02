CREATE PROCEDURE [dbo].[CmDetailview]
	-- Add the parameters for the stored procedure here
@gcCmUnique AS Char(10) = ' '

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select Cmemono, PacklistNo, Uniqueln, UofMeas, CmQty, Is_restock,
	RestockQty,ScrapQty, ShippedQty, CmDescr, Note, S_N_Print, BegSerNo,
	EndSerno, CertDone,Inv_link, WoNoFlag, CmPricelnk, WoNo, Pluniqlnk, CmUnique,lAdjustLine
	FROM CmDetail
	where CmDetail.CmUnique = @gcCmUnique
END
