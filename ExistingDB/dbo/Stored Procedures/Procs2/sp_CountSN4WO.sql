-- =============================================
-- Author:		Vicky Lu
-- Create date: 2014/08/25
-- Description:	Rocket kept getting Dept_qty.curr_qty did not match invtser SN count for some work centers.  Most of them are invtser, transfer are matched, but
-- Dept_qty didn't get udated.  This code will be called at the end of save rouine to re-calculate SN count and update dept_qty.curr_qty
-- =============================================
CREATE PROCEDURE [dbo].[sp_CountSN4WO] @lcWono AS char(10) = ' '
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		

DECLARE @SerialYes bit, @SerialStrtNo numeric(4,0)

SELECT @SerialYes = Inventor.SerialYes 
	FROM Woentry, Inventor
	WHERE Woentry.Uniq_key = Inventor.Uniq_key
	AND Woentry.Wono = @lcWono

-- Only go through if @SerialYes = 1
IF @SerialYes = 1
BEGIN	
	SELECT @SerialStrtNo = Dept_Qty.Number
		FROM Dept_qty
		WHERE WONO = @lcWono
		AND SerialStrt = 1
	SELECT @SerialStrtNo = ISNULL(@SerialStrtNo,1)

	-- Get all work centers except 'FGI' that will be different
	;WITH ZInvtSerCNT AS (
		SELECT COUNT(*) AS Cnt, Id_Value 
			FROM INVTSER
			WHERE WONO = @lcWono
			AND ID_KEY = 'DEPTKEY'
			GROUP BY ID_VALUE),
	ZUpdQty AS (
		SELECT Wono, Curr_qty, ISNULL(Cnt,0) AS SNCnt, Deptkey	
			FROM dept_qty LEFT OUTER JOIN ZInvtSerCNT
			ON Dept_qty.DEPTKEY = ZInvtSerCNT.Id_Value
			WHERE Dept_qty.DEPT_ID <> 'FGI'
			AND Dept_qty.Wono = @lcWono
			AND Dept_qty.Number > @SerialStrtNo
			AND Curr_qty<>ISNULL(Cnt,0))
	
	UPDATE Dept_qty SET Curr_qty = ZUpdQty.SNCnt
		FROM ZUpdQty
		WHERE Dept_qty.Wono = ZUpdQty.Wono
		AND Dept_qty.Deptkey = ZUpdQty.Deptkey

	-- Now update Dept_qty for 'FGI'
	;WITH ZInvtSerCNTFGI AS (
		SELECT COUNT(*) AS Cnt
			FROM INVTSER
			WHERE WONO = @lcWono
			AND ID_KEY <> 'DEPTKEY')

	UPDATE Dept_qty SET Curr_qty = ZInvtSerCNTFGI.Cnt
		FROM ZInvtSerCNTFGI
		WHERE Dept_qty.Wono = @lcWono
		AND Dept_qty.Dept_id = 'FGI'



END
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in updating SFT/serial number records. This operation will be cancelled.',11,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	