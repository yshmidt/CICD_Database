-- =============================================
-- Author: David Sharp
-- Create date: 5/1/2012
-- Description: check Customer Part Number
-- 05/15/13 YS change back to use @itable variable based on UD table importBom
-- 10/31/13 DS Skip if no customer assigned and filter empty values prior to update
-- =============================================
CREATE PROCEDURE [dbo].[importBOMVldtnCheckCustNumAll]
-- Add the parameters for the stored procedure here
@importId uniqueIdentifier
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- Insert statements for procedure here
/* validate check to see if the provided manex number exists, or if exactly one match is found and can be populated. */
DECLARE @rowId uniqueidentifier,@rCount int,@custno varchar(10),@partId uniqueidentifier,@cpartId uniqueidentifier,@cRevId uniqueidentifier
,@uniq_key varchar(10),@providedpn varchar(max),@cpartno varchar(max),@rev uniqueidentifier

/* Declare status values to make it easier to update if we change the method in the future */
DECLARE @white varchar(50)='i00white',@green varchar(50)='i01green',@blue varchar(50)='i03blue',@orange varchar(50)='i04orange',@red varchar(50)='i05red',
@sys varchar(50)='01system'

/* Get field Def Ids */
SELECT @partId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'partNo'
SELECT @rev = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'rev'
SELECT @cpartId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'custPartNo'
SELECT @cRevId = fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'crev'
SELECT @custno = custno FROM importBOMHeader WHERE importId = @importId

-- 10/31/13 DS Skip procedure if customer has not been assigned
IF @custno<>'000000000~' AND @custno <>''
BEGIN
/* Get the customer part number|rev for all items on the bom */
-- 11/18/12 YS changed the code to allow dynamic structure of the import fields
--DECLARE @iCustPartsTbl importBOM
 -- Insert statements for procedure here
	-- code to produce dynamic structure
	-- 05/15/13 YS change back to use @itable variable based on UD table importBom
	
	
	DECLARE  @iTable importBom
	--INSERT INTO ##GlobalT EXEC sp_getImportBOMItems @importId
	INSERT INTO @iTable
	EXEC [dbo].[sp_getImportBOMItems] @importId
	
	DECLARE  @oTable importBom
	--INSERT INTO ##GlobalT EXEC sp_getImportBOMItems @importId
	INSERT INTO @oTable
	EXEC [dbo].[sp_getImportBOMItems] @importId,0,null,1
	
	----DECLARE @SQL as nvarchar(max),@Structure as varchar(max)
	------ build dynamic structure
	----SELECT @Structure =
	----STUFF(
	----(
 ----    select  ',' +  F.FIELDNAME  + ' varchar(max) ' 
 ----   from importBOMFieldDefinitions F  
 ----   ORDER BY FIELDNAME 
 ----   for xml path('')
	----),
	----1,1,'')
	
	------ now create global temp table
	------ catch 22 
	----/*- I thought I can create a unique name for my table,
	----	but then any time I need to use the table I would need to use dynamic SQL. 
	----	Cannot use table varibale or local temp table becuase to build dynamic 
	----	structure of the table I have to use dynamic sql and 
	----	both; local temp table and table variable  will go out of scope
	----	after  exec sp_executesql @SQL	command
	----	So now I will use a name check if exists and drop it. Might create a problem 
	----	Will try to overcome the issues as they come.
	----*/ 
	
	----IF OBJECT_ID('TempDB..##GlobalT') IS NOT NULL
	----	DROP TABLE ##GlobalT;
	----SELECT @SQL = N'
	----create table ##GlobalT (importId uniqueidentifier,rowId uniqueidentifier,uniq_key char(10),'+@Structure+')'
	----exec sp_executesql @SQL		
	-- temp table ##GlobalT with the structure based on the importBOMFieldDefinitions is created 
	-- now insert return from the sp_getImportBOMItems into the global temp table
	----INSERT INTO ##GlobalT EXEC sp_getImportBOMItems @importId
	-- now use ##GlobalT in place of @iCustPartsTbl
	---INSERT INTO @iCustPartsTbl
	---SELECT * FROM [dbo].[fn_getImportBOMItems] (@importId)
--05/15/13 YS use @iTable instead of ##GlobalT 
/* If uniq_key, custPartNo, AND custRev all match, the mark as EXACT match */
--UPDATE i
--	SET i.[status]=@white,i.[message]='Exact Match - UNIQ_KEY',i.[validation]=@sys
--	FROM INVENTOR inv
--	INNER JOIN @oTable o ON  inv.INT_UNIQ=o.uniq_key
--	INNER JOIN @iTable c ON  c.rowId=o.rowId/*AND inv.CUSTPARTNO=c.custpartno AND inv.CUSTREV=c.crev*/
--	INNER JOIN importBOMFields i ON i.rowId=c.rowId AND ((i.fkFieldDefId=@cpartId  OR i.fkFieldDefId=@cRevId )
--	WHERE /*i.fkFieldDefId=@cpartId OR i.fkFieldDefId=@cRevId AND*/ i.[status]<>@green
/* Check for different customer part number under a selected internal part number.  If different replace the customer part number.*/
--UPDATE i
--SET i.adjusted=inv.CUSTPARTNO, i.[status]=@orange,i.[message]='PN - Customer Part Num changed to match existing',i.[validation]=@sys
--FROM INVENTOR inv
--INNER JOIN @iTable c ON inv.PART_NO=c.partno AND inv.REVISION=c.rev
--	INNER JOIN @oTable o ON o.rowId=c.rowId and o.custPartNo<>''
--INNER JOIN importBOMFields i ON i.rowId=c.rowId
--WHERE rtrim(ltrim(inv.CUSTPARTNO))<>rtrim(ltrim(o.custpartno)) AND i.fkFieldDefId=@cpartId  AND i.[status]<>@green  AND inv.CUSTNO=@custno
--UPDATE i
--SET i.adjusted=inv.CUSTREV, i.[status]=@orange,i.[message]='PN - Customer Part Num changed to match existing',i.[validation]=@sys
--FROM INVENTOR inv
--INNER JOIN @iTable c ON inv.PART_NO=c.partno AND inv.REVISION=c.rev
--	INNER JOIN @oTable o ON o.rowId=c.rowId and o.custPartNo<>''
--INNER JOIN importBOMFields i ON i.rowId=c.rowId
--WHERE rtrim(ltrim(inv.CUSTPARTNO))<>rtrim(ltrim(o.custpartno)) AND i.fkFieldDefId=@cRevId AND i.[status]<>@green  AND inv.CUSTNO=@custno

/* If uniq_key OR partNo matches, but NOT customer part number */
-- 10/31/13 DS Skip if no customer assigned and filter empty values prior to update
UPDATE i
	SET i.adjusted=inv.CUSTPARTNO,i.[status]=@orange,i.[message]='KEY - Customer Part Num changed to match existing',i.[validation]=@sys
	FROM INVENTOR inv
	INNER JOIN @iTable c ON inv.INT_UNIQ=c.uniq_key
	INNER JOIN @oTable o ON o.rowId=c.rowId and o.custPartNo<>''
	INNER JOIN importBOMFields i ON i.rowId=c.rowId and i.[status]<>@green AND i.fkFieldDefId=@cpartId
	WHERE inv.CUSTPARTNO<>o.custpartno AND inv.CUSTNO=@custno AND c.uniq_key<>''
	--WHERE rtrim(ltrim(inv.CUSTPARTNO))<>rtrim(ltrim(o.custpartno)) AND i.fkFieldDefId=@cpartId AND i.[status]<>@green AND inv.CUSTNO=@custno
UPDATE i
	SET i.adjusted=inv.CUSTREV,i.[status]=@orange,i.[message]='KEY - Customer Part Num changed to match existing',i.[validation]=@sys
	FROM INVENTOR inv
	INNER JOIN @iTable c ON inv.INT_UNIQ=c.uniq_key
	INNER JOIN @oTable o ON o.rowId=c.rowId and o.custPartNo<>''
	INNER JOIN importBOMFields i ON i.rowId=c.rowId AND i.[status]<>@green AND i.fkFieldDefId=@cRevId
	WHERE rtrim(ltrim(inv.CUSTPARTNO))<>rtrim(ltrim(o.custpartno)) AND inv.CUSTNO=@custno AND c.uniq_key<>''

/* If partNo, rev, custPartNo, AND custRev all match, the mark as EXACT match */
UPDATE i
	SET i.[status]=@white,i.[message]='Exact Match - PN REV',i.[validation]=@sys
	FROM INVENTOR inv
	INNER JOIN @oTable o ON  inv.CUSTPARTNO=o.custpartno AND inv.CUSTREV=o.crev
	INNER JOIN @iTable c ON  inv.PART_NO=c.partno AND c.rowId=o.rowId AND inv.REVISION=c.rev
	INNER JOIN importBOMFields i ON i.rowId=c.rowId AND ((i.fkFieldDefId=@cpartId OR i.fkFieldDefId=@cRevId))
	WHERE i.[status]<>@green AND o.custPartNo<>''

/* If custPartNo not provided, but a custPartNo is tied to the selected partNo (by uniq_key or parno|rev), then populate the custPartNo */
UPDATE i
	SET i.adjusted=inv.CUSTPARTNO,i.[status]=@blue,i.[message]='KEY - existing CPN tied to ManEx number',i.[validation]=@sys
	FROM INVENTOR inv
	INNER JOIN @iTable c ON inv.INT_UNIQ=c.uniq_key
	INNER JOIN @oTable o ON o.rowId=c.rowId
	INNER JOIN importBOMFields i ON i.rowId=c.rowId
	WHERE o.custpartno='' AND inv.CUSTPARTNO<>'' AND i.fkFieldDefId=@cpartId AND i.[status]<>@green AND inv.CUSTNO=@custno AND c.uniq_key<>''
UPDATE i
	SET i.adjusted=inv.CUSTREV,i.[status]=@blue,i.[message]='KEY - existing CPN tied to ManEx number',i.[validation]=@sys
	FROM INVENTOR inv
	INNER JOIN @iTable c ON inv.INT_UNIQ=c.uniq_key
	INNER JOIN @oTable o ON o.rowId=c.rowId
	INNER JOIN importBOMFields i ON i.rowId=c.rowId
	WHERE o.custpartno='' AND inv.CUSTPARTNO<>'' AND i.fkFieldDefId=@cRevId AND i.[status]<>@green AND inv.CUSTNO=@custno AND c.uniq_key<>''

--UPDATE i
--	SET i.adjusted=inv.CUSTPARTNO,i.[status]=@blue,i.[message]='PN - existing CPN tied to ManEx number',i.[validation]=@sys
--	FROM INVENTOR inv
--	INNER JOIN @iTable c ON inv.part_no=c.partno AND inv.revision=c.rev
--	INNER JOIN @oTable o ON o.rowId=c.rowId
--	INNER JOIN importBOMFields i ON i.rowId=c.rowId
--	WHERE o.custpartno='' AND inv.CUSTPARTNO<>'' AND i.fkFieldDefId=@cpartId AND i.[status]<>@green AND inv.CUSTNO=@custno
--UPDATE i
--	SET i.adjusted=inv.CUSTREV,i.[status]=@blue,i.[message]='PN - existing CPN tied to ManEx number',i.[validation]=@sys
--	FROM INVENTOR inv
--	INNER JOIN @iTable c ON inv.part_no=c.partno AND inv.revision=c.rev
--	INNER JOIN @oTable o ON o.rowId=c.rowId
--	INNER JOIN importBOMFields i ON i.rowId=c.rowId
--	WHERE o.custpartno='' AND inv.CUSTPARTNO<>'' AND i.fkFieldDefId=@cRevId AND i.[status]<>@green AND inv.CUSTNO=@custno
------TO BE DELETED JUST FOR TEST
---- SELECT * FROM importBOMFields where fkImportId=@importId and [message]='existing CPN tied to ManEx number'
------JUST FOR TEST
/*TODO: FIX non-issue parts getting flagged
DESCRIPTION: Some parts do match, but are flagged as not matching. It isn't every part and I can't tell what causes some to be flagged, but it doesn't prevent import
It just unecessarily flags some parts
*/

------TO BE DELETED JUST FOR TEST
---- SELECT * FROM importBOMFields where fkImportId=@importId and [message]='KEY - Part tied to a different customer part no'
------JUST FOR TEST
/*TODO: FIX non-issue parts getting flagged
DESCRIPTION: Some parts do match, but are flagged as not matching. It isn't every part and I can't tell what causes some to be flagged, but it doesn't prevent import
It just unecessarily flags some parts
*/
/* Check for provided customer part number under a different internal part number.  If EXISTS replace the internal part number.*/
--UPDATE i
--SET i.uniq_key=inv.INT_UNIQ,i.adjusted = inv.part_no,i.[status]=@orange,i.[message]='Cust Part tied to a different ManEx part no',i.[validation]=@sys
--FROM INVENTOR inv
--LEFT OUTER JOIN @iTable c ON inv.CUSTPARTNO=c.custpartno AND inv.CUSTREV=c.crev
--INNER JOIN importBOMFields i ON i.rowId=c.rowId
--WHERE rtrim(ltrim(inv.PART_NO))<>rtrim(ltrim(c.partno)) OR inv.REVISION<>c.rev AND i.fkFieldDefId=@partId AND i.[status]<>@green  AND inv.CUSTNO=@custno
--UPDATE i
--SET i.uniq_key=inv.INT_UNIQ,i.adjusted = inv.REVISION,i.[status]=@orange,i.[message]='Cust Part tied to a different ManEx part no',i.[validation]=@sys
--FROM INVENTOR inv
--LEFT OUTER JOIN @iTable c ON inv.CUSTPARTNO=c.custpartno AND inv.CUSTREV=c.crev
--INNER JOIN importBOMFields i ON i.rowId=c.rowId
--WHERE rtrim(ltrim(inv.PART_NO))<>rtrim(ltrim(c.partno)) OR inv.REVISION<>c.rev AND i.fkFieldDefId=@rev AND i.[status]<>@green  AND inv.CUSTNO=@custno
END
END