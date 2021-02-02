-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/04/09
-- Description:	Level Make or Phantom parts for Cost Roll
-- =============================================
CREATE PROCEDURE [dbo].[sp_CostRollLeveling] @cUserId AS char(8) = ''

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @tCostLevel TABLE (Uniq_key char(10), Mrp_Code numeric(2,0))
DECLARE @lnMaxMrp_Code numeric(2,0), @lcUniq_Field char(10), @lInLevel bit, @cLevelBy char(8), @dLevelTime smalldatetime,
		@lcString char(200)

BEGIN TRANSACTION
BEGIN TRY

SELECT @lInLevel = lInLevel, @cLevelBy = CLEVELBY, @dLevelTime = DLEVELTIME
	FROM InvtSetup

IF @@ROWCOUNT > 0 AND @lInLevel = 1
BEGIN
	SET @lcString = 'User ' + LTRIM(RTRIM(@cLevelBy)) + ' is updating tables starting at ' + LTRIM(RTRIM(CAST(@dLevelTime AS char))) +
			'.  Please update later.  This operation will be cancelled.'		
	RAISERROR(@lcString,1,1)
END;

-- Get all Make or Phantom parts with MRP_code	
WITH ZCostLevel as 
 (
	SELECT Uniq_Key, 1 AS Mrp_Code, Make_BUY, Status, BOM_Status 
		FROM Inventor 
		WHERE (Part_Sourc = 'MAKE' 
		OR Part_Sourc = 'PHANTOM')
		AND Uniq_Key NOT IN 
			(SELECT Uniq_Key FROM Bom_Det)
UNION ALL
	SELECT B.Uniq_Key, L.Mrp_Code + 1, I.Make_buy, I.Status, I.BOM_Status 
		FROM ZCostLevel L INNER JOIN Bom_Det B ON L.Uniq_Key = B.BomParent 
		INNER JOIN Inventor I ON B.UNIQ_KEY = I.UNIQ_KEY
		WHERE (Part_Sourc = 'MAKE' 
		OR Part_Sourc = 'PHANTOM')
		AND L.MRP_CODE < 100
),
--  Filter out Make_Buy = 1 and Status<>'Active' and Bom_Status <> 'Active'
ZFilterOutMakeBuy_InactiveStatus AS	
(
SELECT DISTINCT * 
	FROM ZCostLevel 
	WHERE Make_Buy = 0
	AND Status = 'Active'
	AND Bom_Status = 'Active'
	
)

-- Final temp table for updating purpose
INSERT @tCostLevel (Uniq_key, Mrp_Code)
	SELECT DISTINCT Uniq_key, ISNULL(MAX(Mrp_Code),0) AS Mrp_Code
		FROM ZFilterOutMakeBuy_InactiveStatus
		GROUP BY Uniq_Key 

SELECT @lnMaxMrp_Code = ISNULL(MAX(Mrp_Code),0)
	FROM @tCostLevel	
	
UPDATE @tCostLevel
	SET Mrp_Code = ABS(@lnMaxMrp_Code + 1 - Mrp_Code)

-- Update InvtSetup.lInLevel to 1
UPDATE INVTSETUP	
	SET lInLevel = 1,
		cLevelBy = @cUserId,
		dLevelTime = GETDATE()
		
-- Update RollMake
SELECT @lcUniq_Field = Uniq_Field	
	FROM ROLLMAKE

IF @@ROWCOUNT = 0
BEGIN
	INSERT ROLLMAKE (UNIQ_FIELD) VALUES (dbo.fn_GenerateUniqueNumber())
END

UPDATE ROLLMAKE	
	SET RunDate =GETDATE(), 
		MaxLevel = @lnMaxMrp_Code, 
		CurLevel = 1

-- Update Mrp_code for Make and Phantom parts
UPDATE INVENTOR
	SET MRP_CODE = t.Mrp_Code
	FROM INVENTOR, @tCostLevel t
	WHERE Inventor.UNIQ_KEY = t.Uniq_key


-- Update InvtSetup.lInLevel to 0
-- 04/19/12 VL changed from updating dLevelTime from NULL to 0, it will set to 1900-01-01
UPDATE INVTSETUP	
	SET lInLevel = 0,
		cLevelBy = getdate(),
		dLevelTime = 0
		
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in cost roll leveling. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;

END
