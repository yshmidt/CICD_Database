CREATE PROCEDURE [dbo].[WoWcSQCView] @gWono AS char(10) = '', @gUniq_key AS char(10) = '', 
	@cDept_id AS char(4) = '', @cWOSelection char(10) = '', @cWCSelection char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

/*	fWOSelection will have "ONE","ALL","ALL1CLOSED","ALL5CLOSED" values
	fWCSelection will have "ONE","ALL" values"*/

DECLARE @ZShpFlSQCWo TABLE (Wono char(10), CompleteDt smalldatetime);
DECLARE @ZShpflSQCWc TABLE (Dept_id char(4));
DECLARE @ZQABARGR1 TABLE (DefQty numeric(4,0), Def_code char(10), Dept_id char(4));

/*--Prepare WO list*/
IF @cWOSelection = 'ONE'
BEGIN
	INSERT @ZShpFlSQCWo
		SELECT Wono, CompleteDt
			FROM Woentry
			WHERE Wono = @gWono
END

IF @cWOSelection = 'ALL'
BEGIN
	INSERT @ZShpFlSQCWo
		SELECT Wono, CompleteDt
			FROM Woentry
			WHERE Uniq_key = @gUniq_key 
			AND (OpenClos <> 'Cancel'
			AND OpenClos <> 'Closed'
			AND CHARINDEX (OpenClos,'Hold' ) = 0)
END 

IF @cWOSelection = 'ALL1CLOSED'
BEGIN
	INSERT @ZShpFlSQCWo
		SELECT Wono, CompleteDt
			FROM Woentry
			WHERE Uniq_key = @gUniq_key 
			AND (OpenClos <> 'Cancel'
			AND OpenClos <> 'Closed'
			AND CHARINDEX (OpenClos,'Hold' ) = 0)
	INSERT @ZShpFlSQCWo
		SELECT TOP 1 Wono, CompleteDt
			FROM Woentry
			WHERE Uniq_key = @gUniq_key
			AND OpenClos = 'Closed'
			ORDER BY CompleteDt DESC
END 

IF @cWOSelection = 'ALL5CLOSED'
BEGIN
	INSERT @ZShpFlSQCWo
		SELECT Wono, CompleteDt
			FROM Woentry
			WHERE Uniq_key = @gUniq_key 
			AND (OpenClos <> 'Cancel'
			AND OpenClos <> 'Closed'
			AND CHARINDEX (OpenClos,'Hold' ) = 0)
	INSERT @ZShpFlSQCWo
		SELECT TOP 5 Wono, CompleteDt
			FROM Woentry
			WHERE Uniq_key = @gUniq_key
			AND OpenClos = 'Closed'
			ORDER BY CompleteDt DESC
END 

/*--Prepare WC list*/
IF @cWCSelection = 'ONE'
BEGIN
	INSERT @ZShpflSQCWc
		SELECT Dept_id 
			FROM Depts
			WHERE Dept_id = @cDept_id
END
IF @cWCSelection = 'ALL'
BEGIN
	INSERT @ZShpflSQCWc
		SELECT Dept_id 
			FROM Depts
END

/*-- Start to generate data*/
INSERT @ZQABARGR1 
	SELECT LocQty AS DefQty,Def_code,ChgDept_id AS Dept_id
		FROM Qadef, QadefLoc
		WHERE Wono IN 
		(SELECT Wono FROM @ZShpflSQCWo)
		AND ChgDept_id IN 
		(SELECT Dept_id FROM @ZShpflSQCWc)
		AND LocQty<>0
		AND QadefLoc.LocSeqNo=Qadef.LocSeqNo
		ORDER BY DefQty DESC

SELECT SUM(Defqty) AS Qty,Def_code
	FROM @ZQABARGR1
	GROUP BY Def_code
	ORDER BY 1 DESC

END