-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/16/2013
-- Description:	PaymentTypeview for picklist
-- =============================================
CREATE PROCEDURE [dbo].[PaymentTypeView]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [PaymentType]
      ,[PaymentTypeKey]
  FROM mnxPaymentType



END