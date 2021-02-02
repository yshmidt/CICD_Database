-- =============================================
-- Author:		SalesInfo4UniqKeyView
-- Create date: 06/04/2012
-- Description:	Used in mRP to show detail information
--- Modified : 03/12/14 YS added is_RMA to indicate that this is an RMA
-- =============================================
CREATE PROCEDURE [dbo].[SalesInfo4UniqKeyView]
	-- Add the parameters for the stored procedure here
	@lcSono char(10)='',@lcUniq_key char(10)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --- 03/12/14 YS added is_RMA to indicate that this is an RMA
	SELECT CustName,Balance,Sodetail.LINE_NO,Somain.Sono  ,somain.IS_RMA 
	FROM SoMain INNER JOIN Customer on Somain.CUstno=Customer.Custno
			INNER JOIN SoDetail on Somain.Sono=Sodetail.Sono
				WHERE SoMain.SoNo = @lcSono
				AND SoDetail.Uniq_Key=@lcUniq_key 
END