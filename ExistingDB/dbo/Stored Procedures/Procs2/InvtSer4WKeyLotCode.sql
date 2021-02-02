-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/19/2014 
-- Description:	Show available lserial numbers fro the w_key and lotcode if provided. Using in inventory handling issue and trnasfer
-- to show available serial numbers
-- Parameters
-- @w_key 
--- Lot code combo, use default if no lot code 
--  @lotCode char(15)=' ',
--	@ExpDate smalldatetime = NULL,
--	@Reference char(12)=' ',
--	@PoNum char(15)=' '
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[InvtSer4WKeyLotCode] 
	-- Add the parameters for the stored procedure here
	@w_key char(10)=' ',
	--02/09/18 YS changed size of the lotcode column to 25 char
	@lotCode nvarchar(25)=' ',
	@ExpDate smalldatetime = NULL,
	@Reference char(12)=' ',
	@PoNum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT SerialUniq, SerialNo 
		FROM Invtser
		WHERE Id_key = 'W_KEY'
		and Id_Value = @W_key
		and ISRESERVED =0 
		AND LotCode = @LotCode
		AND Reference = @Reference
		AND Ponum = @PoNum		
		and 1=CASE WHEN @ExpDate is null and ExpDate is null  then 1 
					WHEN ExpDate = @ExpDate THEN 1 ELSE 0 END
		ORDER BY Serialno
	
	
END	