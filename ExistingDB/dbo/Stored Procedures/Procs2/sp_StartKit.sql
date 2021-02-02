-- =============================================
-- Author:		Vicky Lu
-- Create date: 2014/09/05
-- Description:	Here are the code that when a KIT is first started need to have, created for API call to use
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[sp_StartKit] @lcWono AS char(10) = ' ', @lcUserId char(8) = ' '
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRANSACTION
	
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @ZKitReq1 TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(9,2), ShortQty numeric(9,2),
		Used_inKit char(1), Part_Sourc char(8), Part_no char(35), Revision char(8), Descript char(45), Part_class char(8), 
		Part_type char(8), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), CustPartNo char(35), SerialYes bit)

-- Invalid Wono 
IF NOT EXISTS(SELECT 1 FROM Woentry WHERE WONO = @lcWono)
BEGIN
	RAISERROR('Can not find this work order in the system.  This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN	
END 

-- Woentry status is cancel or closed
IF EXISTS(SELECT 1 FROM WOENTRY WHERE WONO = @lcWono AND (OPENCLOS = 'Closed' OR OPENCLOS = 'Cancel'))
BEGIN
	RAISERROR('The work order does not have OPEN status.  This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN	
END 

-- Kit has been started
IF EXISTS(SELECT 1 FROM KAMAIN WHERE WONO = @lcWono AND LINESHORT = 0)
BEGIN
	RAISERROR('The KIT has been in process.  This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN	
END 
		
INSERT @ZKitReq1 EXEC [KitBomInfoView] @lcWono;

-- Insert Kamain
INSERT INTO KAMAIN (WONO, DEPT_ID, UNIQ_KEY, INITIALS, ENTRYDATE, KASEQNUM, BOMPARENT, SHORTQTY, QTY, sourceDev) 
	SELECT @lcWono AS Wono, Dept_id, Uniq_key, @lcUserId, GETDATE(), dbo.fn_GenerateUniqueNumber(), Bomparent, ShortQty, Qty, 'I' AS SourceDev
		FROM @ZKitReq1

-- Insert Kadetail
INSERT INTO Kadetail (Kaseqnum, ShReason, ShortQty, ShQualify, ShortBal, AuditDate, AuditBy, UniqueRec, Wono)
	SELECT Kaseqnum, 'KIT MODULE' AS ShReason, ShortQty, 'ADD' AS ShQualify, ShortQty, GETDATE() AS AuditDate, @lcUserId AS AuditBy, dbo.fn_GenerateUniqueNumber(), @lcWono
		FROM Kamain
		WHERE Wono = @lcWono
		AND LineShort = 0

-- the next update are commented out, it should be updated by kamain insert trigger
--UPDATE Woentry SET	Kitstatus = 'KIT PROCSS',
--					Start_date = GETDATE(),
--					KitStartInit = @lcUserId
--		WHERE Wono = @lcWono
--EXEC sp_UpdOneWOChkLst @lcWono, 'KIT IN PROCESS', @lcUserId



IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	