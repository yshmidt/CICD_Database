-- =============================================
-- Author:		Vicky Lu
-- Create date: 2013/07/19
-- Description:	Try to capture all errors before ECO update starts.  Created this sp because now we allow user to update partially 
--				completed wo, need to update kit.
--				Here are the list that can not update WO
--				1). component is serialized and/or lot coded that already issued to old product WO, and the WO already has complete qty
--				2). if the kit has WO-WIP that's allocated to other work order, user can ot update WO
--				3). If issued parts are in use by physical inventory or cycle count
-- Modification:
-- 07/19/13 VL added code to update if the WO has partial completion, need to issue only woentry.complete calculated component req qty and issue all extra into new work order
-- 05/29/14 VL changed the (1.) criteria, now allow user to change WO to new revision if no qty is moved to FGI (Woentry.Complete = 0)
--			   even the WO has SN/LOT part issued.
-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
-- 04/22/16 VL I think if the invt_res is created for the same work order, it should be ok, so I will filter out if the invt_res.wono is the same work order
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[chkECOUpdateView] @gUniqEcNo AS char(10) = ' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;	

DECLARE @lReturn bit, @lXxWonosys bit
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZFailedTB TABLE (Wono char(10), Part_no char(35), Revision char(8), FailedReason varchar(100), IssuedWo char(10), 
		IssuedPrj char(10), NewWono char(10))

SET @lReturn = 1
SELECT @lXxWonosys = XxWonoSys FROM Micssys

-- 1. Check if checked EcWo records now has SN/Lot coded compoents issued
IF @lReturn = 1
	BEGIN
	INSERT INTO @ZFailedTB (Wono, Part_no, Revision, FailedReason) 
		-- 03/09/15 VL Changed to LEFT OUTER JOIN for parttype, otherwise empty inventor.part_type won't be selected
		--SELECT Woentry.Wono, PART_NO, Revision, 'Serialized and/or lot coded components are already issued.' AS FailedReason
		--FROM Woentry, Kamain, INVENTOR, Parttype 
		--WHERE Kamain.WONO IN 
		--	(SELECT Wono 
		--		FROM ECWO
		--		WHERE UNIQECNO = @gUniqEcNo
		--		AND CHANGE = 1)
		--AND Woentry.WONO = Kamain.WONO
		--AND Kamain.Uniq_key = Inventor.UNIQ_KEY
		--AND Inventor.PART_CLASS = Parttype.PART_CLASS
		--AND Inventor.PART_TYPE = Parttype.PART_TYPE
		--AND ACT_QTY <> 0
		--AND (Inventor.SERIALYES = 1
		--OR Parttype.LOTDETAIL = 1)
		--AND Woentry.COMPLETE <> 0
		SELECT Woentry.Wono, PART_NO, Revision, 'Serialized and/or lot coded components are already issued.' AS FailedReason
		FROM Woentry, Kamain, INVENTOR LEFT OUTER JOIN Parttype 
		ON Inventor.PART_CLASS = Parttype.PART_CLASS
		AND Inventor.PART_TYPE = Parttype.PART_TYPE
		WHERE Kamain.WONO IN 
			(SELECT Wono 
				FROM ECWO
				WHERE UNIQECNO = @gUniqEcNo
				AND CHANGE = 1)
		AND Woentry.WONO = Kamain.WONO
		AND Kamain.Uniq_key = Inventor.UNIQ_KEY
		AND ACT_QTY <> 0
		AND (Inventor.SERIALYES = 1
		OR Parttype.LOTDETAIL = 1)
		AND Woentry.COMPLETE <> 0

END

IF @@ROWCOUNT > 0
	BEGIN
	SET @lReturn = 0
END

-- 2. check if the WO-WIP of this WO has been allocated by other WO
IF @lReturn = 1
BEGIN
	;WITH ZGetAllocatedtoWOWIP AS
	(
	-- 04/22/16 VL I think if the invt_res is created for the same work order, it should be ok, so I will filter out if the invt_res.wono is the same work order
	SELECT Invt_res.UNIQ_KEY, Invt_res.Wono, Invt_res.FK_PRJUNIQUE, SUBSTRING(Location,3,10) AS IssuedWo
		FROM Invt_res, Invtmfgr
		WHERE Invt_res.W_key = Invtmfgr.W_key
		AND LEFT(Invtmfgr.Location,2) = 'WO' 
		AND SUBSTRING(Location,3,10) IN 
			(SELECT Wono 
				FROM ECWO
				WHERE UNIQECNO = @gUniqEcNo
				AND CHANGE = 1)
		-- {04/22/16 VL added
		AND Invt_res.Wono NOT IN (SELECT Wono 
				FROM ECWO
				WHERE UNIQECNO = @gUniqEcNo
				AND CHANGE = 1)
		-- 04/22/16 VL End}
		AND Invtres_no NOT IN 
			(SELECT Refinvtres
				FROM Invt_res)
		AND qtyAlloc > 0
	)
	INSERT INTO @ZFailedTB (Wono, Part_no, Revision, FailedReason, IssuedWo, IssuedPrj) 
	SELECT Wono, Part_no, Revision, 'WO-WIP location parts are allocated by other WO/PRJ, the parts need to be unallocated first.' AS FailedReason, IssuedWo,
	CASE WHEN PJCTMAIN.PRJNUMBER IS NULL THEN SPACE(10) ELSE PJCTMAIN.PRJNUMBER END AS IssuedPrj
		FROM Inventor, ZGetAllocatedtoWOWIP LEFT OUTER JOIN PjctMain
		ON ZGetAllocatedtoWOWIP.Fk_PrjUnique = Pjctmain.Prjunique
		WHERE Inventor.Uniq_key = ZGetAllocatedtoWOWIP.Uniq_key

	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END
END

-- 3. If the parts are used in PI or CC
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Wono, Part_no, Revision, FailedReason) 
	SELECT DISTINCT Kamain.Wono, Inventor.Part_no, Inventor.Revision, 'Parts are used in physical inventory or cycle count.' AS FailedReason
		FROM Kamain,Kalocate,Invtmfgr,Inventor
		WHERE Kamain.Wono IN 
			(SELECT Wono 
				FROM ECWO
				WHERE UNIQECNO = @gUniqEcNo
				AND CHANGE = 1)
		AND Kamain.Kaseqnum = Kalocate.Kaseqnum
		AND Kamain.Uniq_key = Inventor.Uniq_key
		AND Kalocate.W_key = Invtmfgr.W_key
		AND Invtmfgr.CountFlag <> SPACE(1)

	IF @@ROWCOUNT > 0
		BEGIN
		SET @lReturn = 0
	END		
END

-- 4. If Wono number is set to manual, need to check if new wono is unique
IF @lReturn = 1 AND @lXxWonosys = 0
BEGIN
	INSERT INTO @ZFailedTB (Wono, NewWono, FailedReason) 
	SELECT Wono, NewWono, 'New work order numbers already exist in system.' AS FailedReason
		FROM EcWo
		WHERE UniqEcno = @gUniqEcNo
		AND Balance <> 0
		AND IS_SnLotIssued = 0
		AND Change = 1 
		AND NewWono IN 
			(SELECT Wono 
				FROM WOENTRY)
		
		
END
SELECT * FROM @ZFailedTB

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in checking ECO WO Update. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END		