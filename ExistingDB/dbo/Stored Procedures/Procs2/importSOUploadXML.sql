-- =============================================
-- Author: David Sharp
-- Create date: 9/28/2012
-- Description: imports the XML file to SQL table
--- 04/14/15 YS change "location" column length to 256
-- =============================================
CREATE PROCEDURE [dbo].[importSOUploadXML]
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
/* Get System Setting for SO numbering */
DECLARE @lastSONO varchar(10), @sonoAuto bit = 0,@nextSONO varchar(10)
SELECT @sonoAuto=CAST([XXSONOSYS] as bit),@lastSONO=[LASTSONO] FROM MICSSYS
IF @sonoAuto=1 SET @nextSONO = RIGHT('0000000000'+CAST(CAST(@lastSONO AS int)+1 AS varchar(10)),10)
/* Declare import table variables */
/**************************************/
--- 04/14/15 YS change "location" column length to 256
DECLARE @SOIMPORT TABLE([sono] varchar(10),[custno] varchar(10),[attentionnm] varchar(max),[pono] varchar(10),[contactnm] varchar(max),[part_no] varchar(45),
[revision] varchar(8),[line_no] varchar(8),[partmfgr] varchar(10),[mfgr_pt_no] varchar(max),[warehouse] varchar(10),[location] varchar(256),[price] decimal(18,5),
[taxable] varchar(1),[saletyeid] varchar(10),[qty] decimal(18,5),[due_dts] smalldatetime)
DECLARE @SOMAIN TABLE([sono] varchar(10),[custno] varchar(10),[attentionnm] varchar(max),[pono] varchar(10),[contactnm] varchar(max))
--- 04/14/15 YS change "location" column length to 256
DECLARE @SODETAIL TABLE ([sono] varchar(10),[line_no] varchar(8),[part_no] varchar(45),[revision] varchar(8),[partmfgr] varchar(10),[mfgr_pt_no] varchar(max),[warehouse] varchar(10),[location] varchar(256),[price] decimal(18,5),
[taxable] varchar(1),[saletyeid] varchar(10),[qty] int,[due_dts] smalldatetime)
/* Parse records and insert into table variable */
INSERT INTO @SOIMPORT(sono,custno,attentionnm,pono,contactnm,part_no,revision,line_no,partmfgr,mfgr_pt_no,warehouse,location,
price,taxable,saletyeid,qty,due_dts)
SELECT UPPER(x.importFile.query('SONO').value('.', 'VARCHAR(10)')),
UPPER(x.importFile.query('CUSTNO').value('.', 'VARCHAR(10)')),
UPPER(x.importFile.query('ATTENTION').value('.', 'VARCHAR(MAX)')),
UPPER(x.importFile.query('PONO').value('.', 'VARCHAR(10)')),
UPPER(x.importFile.query('CONTACT').value('.', 'VARCHAR(MAX)')),
UPPER(x.importFile.query('PARTNO').value('.', 'VARCHAR(MAX)')),
UPPER(x.importFile.query('REVISION').value('.', 'VARCHAR(8)')),
UPPER(x.importFile.query('LINENO').value('.', 'VARCHAR(8)')),
UPPER(x.importFile.query('PARTMFGR').value('.', 'VARCHAR(10)')),
UPPER(x.importFile.query('MFGR_PT_NO').value('.', 'VARCHAR(45)')),
UPPER(x.importFile.query('WAREHOUSE').value('.', 'VARCHAR(10)')),
UPPER(x.importFile.query('LOCATION').value('.', 'VARCHAR(256)')),
x.importFile.query('PRICE').value('.', 'DECIMAL(18,5)'),
UPPER(x.importFile.query('TAXABLE').value('.', 'VARCHAR(1)')),
UPPER(x.importFile.query('SALETYPEID').value('.', 'VARCHAR(10)')),
x.importFile.query('QTY').value('.', 'DECIMAL(18,5)'),
x.importFile.query('DUE_DTS').value('.', 'SMALLDATETIME')
FROM(SELECT @x) AS T(x)
CROSS APPLY x.nodes('/Root/Row') AS X(importFile)
/* Verify that only 1 SO is getting loaded at a time */
DECLARE @sonoCount int = 0, @sono varchar(10)
SELECT @sonoCount=COUNT(SONO),@sono=MAX(SONO) FROM (SELECT DISTINCT SONO FROM @SOIMPORT)a
IF @sonoCount>1
BEGIN
SELECT 405 as code,'Import must contain only 1 SO Number' msg
RETURN
END
IF @sonoCount=0 AND @sonoAuto =0
BEGIN
SELECT 404 as code, 'Import must contain at least 1 SO Number' msg
RETURN
END
/* If SO manually numbered, replace nextSONO with value from import */
IF @sonoAuto=0 SELECT @nextSONO=SONO FROM @SOIMPORT
/* Create SO record in SOMAIN */
--INSERT INTO SOMAIN (BLINKADD,SLINKADD,SONO,CUSTNO,ORDERDATE,PONO,SONOTE,ORD_TYPE)
SELECT c.BLINKADD,c.SLINKADD,@nextSONO,si.custno,GETDATE(),si.pono,'Imported','Open' FROM @SOIMPORT si INNER JOIN CUSTOMER c ON si.custno=c.CUSTNO
/* Create Detail record in SODETAIL */
--INSERT INTO SODETAIL (SONO,UNIQUELN,LINE_NO,UNIQ_KEY,UOFMEAS,ORD_QTY,SHIPPEDQTY,BALANCE,STATUS,MRPONHOLD)
SELECT si.sono,dbo.fn_GenerateUniqueNumber(),si.line_no,i.uniq_key,i.u_of_meas,si.qty,0,si.qty,'Open',1
FROM @SOIMPORT si INNER JOIN INVENTOR i ON si.part_no = i.PART_NO AND si.revision = i.REVISION
WHERE i.CUSTPARTNO = ''
/* Create Pricing record in SOPRICES */
/* Create Shipping record(s) in {} */
/* Return any records not loaded */
SELECT 0 code,'Success' msg
END