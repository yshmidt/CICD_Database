-- =============================================
-- Author: David Sharp
-- Create date: 11/16/2012
-- Description: imports the XML file of parts to SQL table
-- =============================================
CREATE PROCEDURE [dbo].[importBOMUploadXMLParts]
-- Add the parameters for the stored procedure here
@importId uniqueidentifier,
@userId uniqueidentifier,
@x xml
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
	/* Get user initials for the header */
	DECLARE @userInit varchar(5)
	SELECT @userInit = Initials FROM aspnet_Profile WHERE userId = @userId
	
	DECLARE @skipped varchar(20)='i00skipped',@white varchar(20)='i00white',@fade varchar(20)='i02fade',@blue varchar(20)='i03blue',@orange varchar(20)='i04orange',
		@sys varchar(20)='00system',@none varchar(20)='00none'	
	
	/* Declare import table variables */
	/**************************************/
	/* I used a temp table instead of a table variable specifically so I can use NEWSEQUENTIALID and force the items in order */
	/**************************************/
	CREATE TABLE #importBOMTemp (rowId uniqueidentifier DEFAULT NEWSEQUENTIALID() PRIMARY KEY,itemno varchar(MAX),used varchar(MAX),partSource varchar(MAX),
		qty varchar(MAX),custPartNo varchar(MAX),crev varchar(MAX),descript varchar(MAX),u_of_m varchar(MAX),partClass varchar(MAX),partType varchar(MAX),
		warehouse varchar(MAX),partNo varchar(MAX),rev varchar(MAX),workCenter varchar(MAX),standardCost varchar(MAX),bomNote varchar(MAX),invNote varchar(MAX),
		holderId uniqueidentifier)
	/*The table variable is a temporary holder to allow for all xml records to be loaded (including AVL and ref Desg)*/
	DECLARE @holderTable TABLE (iRowId uniqueidentifier DEFAULT NEWSEQUENTIALID(),itemno varchar(MAX),used varchar(MAX),partSource varchar(MAX),
		qty varchar(MAX),custPartNo varchar(MAX),crev varchar(MAX),descript varchar(MAX),u_of_m varchar(MAX),partClass varchar(MAX),partType varchar(MAX),
		warehouse varchar(MAX),partNo varchar(MAX),rev varchar(MAX),workCenter varchar(MAX),standardCost varchar(MAX),bomNote varchar(MAX),invNote varchar(MAX))
	/* Set class and validation for easier update if we change methods later */

	/* Parse BOM records and insert into table variable */
	INSERT INTO @holderTable(itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
			workCenter,standardCost,bomNote,invNote)
		SELECT x.importBom.query('itemno').value('.','VARCHAR(MAX)'),
				UPPER(x.importBom.query('used').value('.', 'VARCHAR(MAX)')),
				UPPER(x.importBom.query('partSource').value('.', 'VARCHAR(MAX)')),
				x.importBom.query('qty').value('.', 'VARCHAR(MAX)'),
				x.importBom.query('custPartNo').value('.', 'VARCHAR(MAX)'),
				x.importBom.query('crev').value('.', 'VARCHAR(MAX)'),
				x.importBom.query('descript').value('.', 'VARCHAR(MAX)'),
				UPPER(x.importBom.query('u_of_m').value('.', 'VARCHAR(MAX)')),
				UPPER(x.importBom.query('partClass').value('.', 'VARCHAR(MAX)')),
				UPPER(x.importBom.query('partType').value('.', 'VARCHAR(MAX)')),
				x.importBom.query('warehouse').value('.', 'VARCHAR(MAX)'),
				x.importBom.query('partNo').value('.', 'VARCHAR(MAX)'),
				x.importBom.query('rev').value('.', 'VARCHAR(MAX)'),
				UPPER(x.importBom.query('workCenter').value('.', 'VARCHAR(MAX)')),
				x.importBom.query('standardCost').value('.', 'VARCHAR(MAX)'),
				x.importBom.query('bomNote').value('.', 'VARCHAR(MAX)'),
				x.importBom.query('invNote').value('.', 'VARCHAR(MAX)')
			FROM(SELECT @x) AS T(x)
				CROSS APPLY x.nodes('/Root/Row') AS X(importBom)
	/* Create a unique list of parts filtering out duplicate rows for multiple AVLS and ref desg*/
	INSERT INTO #importBOMTemp (itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
			workCenter,standardCost,bomNote,invNote,holderId)
		SELECT DISTINCT itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
			workCenter,standardCost,bomNote,invNote,iRowId
			FROM @holderTable
			GROUP BY itemno,used,partSource,qty,custPartNo,crev,descript,u_of_m,partClass,partType,warehouse,partNo,rev,
			workCenter,standardCost,bomNote,invNote,iRowId
			ORDER BY iRowId
	
	/* Unpivot the temp table and insert into importBOMFields */
	INSERT INTO importBOMFields (fkImportId,fkFieldDefId,rowId,original,adjusted)
		SELECT @importId,fd.fieldDefId,u.rowId,u.adjusted,u.adjusted
			FROM(
				SELECT rowId,[itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],
					[standardCost],[workCenter],[partno],[rev],[bomNote],[invNote]
					FROM #importBOMTemp)p
				UNPIVOT
				(adjusted FOR fieldName IN
					([itemno],[used],[partSource],[partClass],[partType],[qty],[custPartNo],[cRev],[descript],[u_of_m],[warehouse],[standardCost],[workCenter],[partno],[rev],[bomNote],[invNote])
					) AS u
				INNER JOIN importBOMFieldDefinitions fd ON fd.fieldName = u.fieldName
	/* Update import fields with the default value if none were provided */
	UPDATE i
		SET i.adjusted=fd.[default],i.[status]=@blue,i.[message]='Default Value',i.[validation]=@sys
		FROM importBOMFieldDefinitions fd INNER JOIN importBOMFields i ON i.fkFieldDefId=fd.fieldDefId WHERE i.adjusted='' AND fd.[default]<>'' AND i.fkImportId=@importId
	
	DROP TABLE #importBOMTemp
END