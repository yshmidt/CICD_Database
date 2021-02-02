-- =============================================
-- Author:		Vicky Lu
-- Create date: 2010/08/02
-- Description:	Update SO Shipped Qty and SO Order Status
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdSoStatus] @lcSono AS char(10) = '', @lcOrd_Type char(10) OUT
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lnCount int, @lnTotalNo int, @lcUniqueln char(10), @lnOrd_qty numeric(9,2), 
		@lnShippedQty numeric(9,2), @lnBalance numeric(9,2), @lcUniquelnChk char(10);
		
DECLARE @ZSodetail TABLE (nrecno int identity, Uniqueln char(10), Ord_Qty numeric(9,2));

INSERT @ZSodetail SELECT Uniqueln, Ord_Qty FROM SODETAIL WHERE SONO = @lcSono
SET @lnTotalNo = @@ROWCOUNT;

-- Go through Sodetail to update ShippedQty, Balance, Status
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcUniqueln = Uniqueln, @lnOrd_qty = Ord_Qty 
			FROM @ZSodetail WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
			-- Consider if negative for RMA qty
			IF @lnOrd_qty > 0	
				BEGIN
				SELECT @lnShippedQty = ISNULL(SUM(ShippedQty),0) FROM Pldetail WHERE Uniqueln = @lcUniqueln 
				UPDATE SODETAIL 
					SET SHIPPEDQTY = CASE WHEN @lnShippedQty <= @lnOrd_qty THEN @lnShippedQty ELSE @lnOrd_qty END,
						BALANCE = Ord_Qty - CASE WHEN @lnShippedQty <= @lnOrd_qty THEN @lnShippedQty ELSE @lnOrd_qty END
					WHERE UNIQUELN = @lcUniqueln;
				END
			ELSE
				BEGIN
				SELECT @lnShippedQty = ISNULL(SUM(CmQty),0) FROM CmDetail WHERE Uniqueln = @lcUniqueln 
				UPDATE SODETAIL 
					SET SHIPPEDQTY = CASE WHEN @lnShippedQty <= ABS(@lnOrd_qty) THEN -@lnShippedQty ELSE @lnOrd_qty END,
						BALANCE = Ord_Qty - CASE WHEN @lnShippedQty <= ABS(@lnOrd_qty) THEN -@lnShippedQty ELSE @lnOrd_qty END 
					WHERE UNIQUELN = @lcUniqueln
			END
			
			
			UPDATE SODETAIL
				SET STATUS = CASE WHEN ORD_QTY = SHIPPEDQTY THEN 'Closed' 
							ELSE CASE WHEN Status = 'Closed' THEN 'Standard' ELSE Status END END
				WHERE UNIQUELN = @lcUniqueln
		
		END
	END
	

	/* Update Somain.Ord_Type*/
	SELECT @lcUniquelnChk = Uniqueln 
		FROM SODETAIL 
		WHERE Sono = @lcSono
		AND Status <> 'Closed'
		AND Status <> 'Cancel'

	IF @@ROWCOUNT = 0 OR @lcUniquelnChk = ''
		UPDATE SOMAIN SET Ord_Type = 'Closed' 
			WHERE SONO = @lcSono
	ELSE
		UPDATE SOMAIN SET Ord_Type = 'Open' 
			WHERE SONO = @lcSono

	SELECT @lcOrd_Type = Ord_Type 
		FROM SOMAIN 
		WHERE SONO = @lcSono


END



