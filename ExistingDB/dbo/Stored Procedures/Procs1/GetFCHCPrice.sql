-- =============================================
-- Author: Rajendra K
-- Create date: <8/19/2016>
-- Description:	Get FC price from Transactional price and vice versa
-- =============================================
CREATE PROCEDURE [dbo].[GetFCHCPrice]
(
@ContractHeaderUniq CHAR(10) = '',
@SupplierUniq CHAR(10) ='',
@SupplierName VARCHAR(250) ='',
@Price NUMERIC(13,5),
@IsFC BIT
)
AS
BEGIN
  DECLARE @FCUsedUniq CHAR(10),@FCUsedHistKey CHAR(10),@ReturnPrice NUMERIC(13,5)=0
	   --Get @FCUsedUniq & @FCUsedHistKey 
	   IF (@ContractHeaderUniq IS NULL OR @SupplierUniq ='')
	   BEGIN
			IF(@SupplierUniq IS NULL OR @SupplierUniq ='')
			BEGIN
				--Get @FCUsedUniq from @SupplierName
				SET @FCUsedUniq = (SELECT Fcused_Uniq FROM SUPINFO WHERE SUPNAME = @SupplierName)
			END
	        ELSE
			BEGIN
				--Get @FCUsedUniq from @SupplierUniq
				SET @FCUsedUniq = (SELECT Fcused_Uniq FROM SUPINFO WHERE UNIQSUPNO = @SupplierUniq)
			END
				--Get @FCUsedUniq from @FCUsedUniq
				SET @FCUsedHistKey = (SELECT CAST(dbo.getLatestExchangeRate(@FCUsedUniq) AS Char(10)))
	   END
	   ELSE
       BEGIN
			--Get @FCUsedUniq & @FCUsedHistKey from @ContractHeaderUniq
			SELECT @FCUsedUniq = Fcused_Uniq,@FCUsedHistKey = Fchist_Key FROM ContractHeader WHERE ContractH_unique = @ContractHeaderUniq
	   END

	   IF(@IsFC = 1)
	   BEGIN
			--Get FC price from transactional price
	   		SET @ReturnPrice =dbo.fn_Convert4FCHC('F', @FCUsedUniq, @Price, dbo.fn_GetFunctionalCurrency(), @FCUsedHistKey)
	   END
	   ELSE
	   BEGIN
	   		--Get transactional price from FC  price 
	   		SET @ReturnPrice = dbo.fn_Convert4FCHC('H', @FCUsedUniq, @Price , dbo.fn_GetFunctionalCurrency(), @FCUsedHistKey)
	   END
  SELECT @ReturnPrice
END