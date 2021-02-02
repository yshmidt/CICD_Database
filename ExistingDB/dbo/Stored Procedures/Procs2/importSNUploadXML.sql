-- =============================================
-- Author: David Sharp
-- Create date: 9/27/2012
-- Description: imports the XML file to SQL table
-- =============================================
CREATE PROCEDURE [dbo].[importSNUploadXML]
-- Add the parameters for the stored procedure here
@userId uniqueidentifier,
@x xml
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/* Get user initials for the header */
	DECLARE @userInit varchar(5)
	SELECT @userInit = UPPER(Initials) FROM aspnet_Profile WHERE userId = @userId
	/* Declare import table variables */
	/**************************************/
	DECLARE @INVTSERTEMP TABLE([SERIALUNIQ] [varchar](10),[SERIALNO] [varchar](30),[WONO] [varchar](10))
	DECLARE @INVTSER TABLE([SERIALUNIQ] [varchar](10),[SERIALNO] [varchar](30),[UNIQ_KEY] [varchar](10),
		[ID_KEY] [varchar](10),[ID_VALUE] [varchar](10), [SAVEDTTM] [smalldatetime],[SAVEINIT] [varchar](8),
		[WONO] [varchar](10),[MSG] [varchar](50))

	/* Parse records and insert into table variable */
	INSERT INTO @INVTSERTEMP(SERIALUNIQ,SERIALNO,WONO)
		SELECT dbo.fn_GenerateUniqueNumber(),
				RIGHT('000000000000000000000000000000' + UPPER(x.importFile.query('SERIALNO').value('.', 'VARCHAR(30)')),30),
				RIGHT('0000000000' + UPPER(x.importFile.query('WONO').value('.', 'VARCHAR(10)')),10)
			FROM(SELECT @x) AS T(x)
				CROSS APPLY x.nodes('/Root/Row') AS X(importFile)
	
	/* 
		Create a list of SN to import with assembly info.
		If the WO is not serialized (or not provided in the sheet), it will not load any results
	*/
	INSERT INTO @INVTSER (SERIALUNIQ,SERIALNO,UNIQ_KEY,ID_KEY,ID_VALUE,SAVEDTTM,SAVEINIT,WONO)
		SELECT SERIALUNIQ,SERIALNO,w.UNIQ_KEY,'DEPTKEY',dq.DEPTKEY,GETDATE(),@userInit,it.WONO
			FROM @INVTSERTEMP it 
				INNER JOIN WOENTRY w ON w.WONO=it.WONO
				INNER JOIN DEPT_QTY dq ON dq.WONO = it.WONO
			WHERE dq.SERIALSTRT = 1
	
	/* Verify that only 1 WO is getting loaded at a time */
	DECLARE @wonoCount int = 0, @wono varchar(10)
	SELECT @wonoCount=COUNT(WONO),@wono=MAX(WONO) FROM (SELECT DISTINCT WONO FROM @INVTSER)a
	IF @wonoCount>1 
	BEGIN
		SELECT 405 as code,'Import must contain only 1 WO Number' msg
		RETURN 
	END
	ELSE IF @wonoCount=0 
	BEGIN
		SELECT 404 as code, 'WO must be serialized' msg
		RETURN 
	END
	
	/* Identify Existing SN */
	UPDATE i
		SET i.MSG = 'EXISTS'
		FROM @INVTSER i
		WHERE i.SERIALNO IN (SELECT ins.SERIALNO FROM INVTSER ins WHERE ins.WONO=i.WONO)
	
	/* Ensure that the total SN qty does not exceed the WO qty */
	DECLARE @bldQty int = 0, @existQty int=0, @snQty int=0, @topQty int = 0
	SELECT @bldQty = BLDQTY FROM WOENTRY WHERE WONO=@wono
	SELECT @existQty=COUNT(SERIALNO) FROM INVTSER WHERE WONO=@wono
	IF @bldQty !> @existQty
	BEGIN
		SELECT 413 code, 'All SN have been loaded' msg
		RETURN 
	END
	ELSE
	BEGIN
		SET @topQty = @bldQty-@existQty
		/* Insert new SN records */
		INSERT INTO INVTSER (SERIALUNIQ,SERIALNO,UNIQ_KEY,ID_KEY,ID_VALUE,SAVEDTTM,SAVEINIT,WONO)
		SELECT DISTINCT TOP (@topQty) MAX(i.SERIALUNIQ)SERIALUNIQ,i.SERIALNO,i.UNIQ_KEY,MAX(i.ID_KEY)ID_KEY,MAX(i.ID_VALUE)ID_VALUE,MAX(i.SAVEDTTM)SAVEDTTM,MAX(i.SAVEINIT)SAVEINIT,i.WONO 
			FROM @INVTSER i
			WHERE i.SERIALNO NOT IN (SELECT ins.SERIALNO FROM INVTSER ins WHERE ins.WONO=i.WONO)
			GROUP BY SERIALNO,UNIQ_KEY,WONO		
	END
	
	SELECT 0 code,'SUCCESS' msg
	
	/* 
		Return a list of SN included in the import, but not loaded through the import 
		1 - list of SN already loaded
		2 - list of SNin excess of WO build qty
	*/
	SELECT WONO,SERIALNO,MSG FROM @INVTSER i WHERE i.MSG='EXISTS'
	UNION ALL
	SELECT WONO,SERIALNO,'EXCESS' FROM @INVTSER i WHERE i.SERIALNO NOT IN (SELECT SERIALNO FROM INVTSER ins WHERE ins.WONO=i.WONO AND ins.SERIALNO=i.SERIALNO)
END