/*
	05/14/14 DS/YS/NA Added ability to pass the serial number or serialuniq
	04/02/15 YS/DP/NL changed the search and default @lcSerialNo to null
	-- 09/09/15 YS make sure NULL or Empty values are covered in the WHERE 
*/
CREATE PROCEDURE [dbo].[QkViewSerialnoInfoView] @lcSerialUniq char(10) = NULL
--- 03/28/17 YS changed length of the part_no column from 25 to 35
 , @userId uniqueidentifier=null 
 , @lcSerialNo varchar(30) = NULL

AS
BEGIN

SET NOCOUNT ON;


--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZSerialno TABLE (Serialno char(30), Part_no char(35), Revision char(8), Part_class char(8), Part_type char(8), Descript char(45), 
	Wono char(10), WCname char(25), Sono char(10), Pono char(20), Packlistno char(10), ShipDate smalldatetime, ShipDay numeric (5,0), 
	Uniq_key char(10), Id_key char(10), Id_Value char(10))

DECLARE @lcId_key char(10), @lcWono char(10)
---04/02/15 YS/DP/NL changed the search and default @lcSerialNo to null
-- 09/09/15 YS make sure NULL or Empty values are covered in the WHERE 
INSERT @ZSerialno (Serialno, Part_no, Revision, Part_class, Part_type, Descript, Uniq_key, Wono, Id_Key, Id_Value, WCName, Sono, Pono, Packlistno, ShipDate, ShipDay)
	SELECT Serialno, Part_no, Revision, Part_class, Part_type, Descript, InvtSer.Uniq_key, Wono, Id_Key, Id_Value, SPACE(25) AS wCName, SPACE(10) as Sono, SPACE(10) AS Pono, SPACE(10) AS Packlistno, NULL AS ShipDate, 0 AS ShipDqy 
	FROM InvtSer, Inventor 
	WHERE InvtSer.Uniq_key = Inventor.Uniq_key
	AND (((@lcserialno is null or @lcserialno =' ') and @lcSerialUniq<>' ' and @lcSerialUniq IS NOT NULL and serialuniq=@lcSerialUniq) 
	OR ((@lcserialuniq=' ' or  @lcserialuniq is null ) and  @lcserialno <>' ' and @lcserialno is not null and serialno=dbo.padl(rtrim(@lcSerialno),30,'0')))
UPDATE @ZSerialno
	SET Sono = Somain.SONO,
		Pono = Somain.Pono
	FROM @ZSerialno ZSerialno, Somain
	WHERE ZSerialno.Sono = Somain.Sono

SELECT @lcId_key = Id_key, @lcWono = Wono
	FROM @ZSerialno

IF @lcId_key = 'DEPTKEY'	
BEGIN
	UPDATE @ZSerialno
		SET WCname = Depts.DEPT_NAME
		FROM @ZSerialno ZSerialno, Dept_qty, DEPTS
		WHERE Dept_qty.Dept_id = Depts.Dept_id
		AND Deptkey = ZSerialno.Id_value
END

IF @lcId_key = 'W_KEY' AND @lcWono <> ''
BEGIN
	UPDATE @ZSerialno
		SET WCname = 'Finished Goods Inventory '
END

UPDATE @ZSerialno
	SET Packlistno = Plmain.PACKLISTNO,
		ShipDate = Plmain.ShipDate,
		ShipDay = DATEDIFF(day, Plmain.ShipDate, GETDATE())
	FROM Plmain, PACKLSER
	WHERE Plmain.PACKLISTNO = Packlser.PACKLISTNO
	AND Packlser.SERIALUNIQ = @lcSerialUniq

SELECT * FROM @ZSerialno
	
END