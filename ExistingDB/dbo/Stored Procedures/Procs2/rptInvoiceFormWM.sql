-- =============================================    
-- Author:  <Debbie>       
-- Create date: <02/20/2012>      
-- Description: <compiles details for the Invoice form>      
-- Reports:     <used on invoform.rpt>      
-- Modified: 03/21/2012 DRP:  I previously had the PoNo field set to 10 characters.  It should have been set to 20 characters.      
-- 03/21/2012 DRP:      
-- 04/13/2012 DRP: found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired.       
-- 04/18/2012 DRP: Modifications where made so that the printing of the invoice was no longer creating AR records, etc. . .       
-- 10/22/2012 DRP: Changed the link to the ShipBill table that gathers the ShipTo information from an inner join to left outer join.       
-- 11/02/2012 DRP:  needed to change the SOREPS from varchar(50) to varchar(max)      
-- 02/08/2013 DRP:  User was experiencing truncated issue with one of their invoice.  Upon investigation found that the ShipAdd3 was the field that was being truncated.       
--   As a precaution I went through and updated all of the ShipAdd and BillAdd fields from whatever character it had before to char(40) and that addressed the issue.      
-- 04/19/2013 DRP:  it was requested that we add the sales order balance at the time of the shipment to the invoice forms.       
-- 04/24/2013 DRP:  upon request the users would like the option to display the serial numbers on the invoice similar as we do for the packing list.  The parameter will be added to the CR itself.       
-- 08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.      
-- 10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the invoice.        
-- 01/15/2014 DRP:  added the @userid parameter for WebManex      
-- 03/12/2014 DRP:  increased the Line_no char(7) to Line_no char(10)      
-- 04/08/2014 DRP:  Needed to change [CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint)] to [CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0))] for users that had extremely large Serial Numbers entered into the system.       
-- 02/13/2015 DRP:  Serial numbers we causing overflow of the Invoice on screen and I need to add a space after the comma to get the SN to break properly.       
-- 03/30/2015 DRP:  Added the uniqueln to the results.  in one particular user situation they could add the same line item Number multiple times and even for the same uniq_key.  In order to break them out on the report properly I needed to added the uniqueln to make the grouping unique.       
-- 04/21/2015 DRP:  created the Cloud version of the procedure.  Added the @lcPageLbl Parameter      
-- 04/22/2015 VL:   Added 'FirstinBatch' parameter default 1, if it's 1, delete last batch, will insert into 'PrevStat' at the end of this SP to save new last batch      
-- 10/08/15 DRP:  Changed  <<PRICE numeric(12,2)>> to be <<PRICE numeric(14,5)>> otherwise it was rounding to the neares two decimal places.       
-- 07/06/15 DRP:  Changed the address fields to use one field      
-- 02/10/16 VL:  Added FC code      
-- 04/01/16 VL:  Added address3 and 4      
-- 04/08/16 VL:  Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement      
-- 08/15/16 DRP:  Added the /*CUSTOMER LIST*/      
--  it was also requested by a user to have the ability to list out the individual prices breaks or combined the prices breaks into one line and have an parameter option to select how the wish for the Invoice to be printed.       
--  upon discussion with Yelena we decided that we would sum all of the prices breaks into one total and then divide it by the main qty shipped.        
--  added ,CombinedPrice numeric(14,5),CombinedExtPrice numeric(12,2) to the @tresults, then this is later used to determine what will be displyed into the <<Price>> and <<Extended>> fields in the end results of the procedure.          
-- 08/30/16 DRP: Within the section @lcCombinePrice = 'Yes' we needed to change the Where statement, because it was filtering out Misc Items from the results.       
-- 10/28/16 DRP:   Made modifications to work with the Func Currency Values.         
-- 02/03/2017 DRP:  The code that I used to find the PTaxId and STaxID back on 04/12/2016 was not correct.  Needed to change the STaxId to pull TaxType = 'E' not 'S' and I needed to change the @lcSono to be <<dbo.padl(@lcSoNo,10,'0')>> for the TaxId section      
-- 02/27/17 DRP:   per request added is_invpost to the results so that I could use that to display "Unreleased" on the Invoice if user elects to print it before it has been posted to the GL.      
-- 03/17/17 DRP:   found that I was incorrectly linking the Invoice Ship To back to the SOMAIN when I should have been linking it to the plmain.linkadd.      
--- 03/28/17 YS changed length of the part_no column from 25 to 35      
-- 04/19/17 DRP:  found that the Non-Foreign System section of code did not have PTaxId and STaxId in the results.      
-- 04/21/17 DRP:  in the situation where the Ship Qty was zero it would cause an issue within the Code I implemented in order to combine prices on the invoice form.       
--06/27/17 DRP:  NOTE:  when combining Pricing information, in the scenario that Misc Items (RecordType = "O") that happen to have more than one pricing item we will random pick the pDesc that we display for the item.  If this comes up later as an issue we can then dig further into possibly using comma separators      
--It was brought to our attention that if the user selects to combine pricing on an invoice that contain Misc Line item from the Sales Order that it would incorrectly display 0.00 value and or drop the Misc item from the results all together.  Changes needed to be made when combining the pricing information       
-- 01/10/18 VL: Suntronics could not print PK, found out shipped qty is about 17500, the serial number code (remove zero, make start-end) caused the issue, so changed to use temp table instead of CTE cursor to solve the issue      
-- tried to use table variables at first, but could not add index to speed up due to some customers are still in SQL 2012, once added index, the same invoice run from 45 seconds to 4 seconds      
-- 05/21/18 VL: found the changes added in 01/10/18 for FC, didn't insert into @tresultsFC, was insert to @tresults directly      
-- 07/16/18 VL changed custname from char(35) to char(50)      
-- 01/16/19 YS added changes missing from the manex_func DB dated 05/21/18       
-- 01/23/2019 Nilesh Sa:  Added a parameter   
-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql    
-- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
-- 06/06/20 Satyawan H: Check to show invoices with 0 balance
-- 08/10/20 Satywawn H: remove zero balance invoice parameter
-- 08/12/20 VL added invoice footnote from wmNotes
  -- 11/19/20 YS modified shipto/billto to 50 char
-- =============================================    
CREATE PROCEDURE [dbo].[rptInvoiceFormWM]       
	--declare       
	 @lcInvNo char(10) = ''      
	,@lcPageLbl varchar(max) = 'ALL'      
	,@userId uniqueidentifier= null  
	,@firstinBatch bit = 1      
	,@lcCurrDisplay char (40) = 'Functional & Transactional Currency' --Functional Currency Only or Functional & Transactional Currency --01/23/2019 Nilesh Sa:  Added a parameter   
	,@lcCombinePrice char(3) = 'No' --'Yes':  if any price breaks exist it will add all of the prices together and then divide it by the Main ship Qty and display that value.  'No': it will display the price breaks out individually.       
	--,@showZeroAmtInv bit = 0  
AS      
BEGIN      
      
	/*CUSTOMER LIST*/  --08/15/16 DRP:  Added      
	DECLARE  @tCustomer as tCustomer      
	--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it.       
	-- get list of customers for @userid with access      
	INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;      
	--SELECT * FROM @tCustomer       
      
	/*PAGE LIST*/      
	---- SET NOCOUNT ON added to prevent extra result sets from      
	---- interfering with SELECT statements.      
	SET NOCOUNT ON;      
	DECLARE  @tPageDesc AS TABLE (PAGENO numeric(1,0), PAGEDESC CHAR (25),PKINPGNMUK char(10))      
	declare @tPageD as Table (PKINPGNMUK CHAR(10))      
	insert into @tPageDesc select pageno,rtrim(pagedesc),PKINPGNMUK from PKINPGNM where type = 'I' and PAGEDESC <> ' '      
      
 --SELECT * FROM @tPageDesc      
      
 IF @lcPageLbl is not null and @lcPageLbl <>'' and @lcPageLbl<>'All'      
  insert into @tPageD select * from dbo.[fn_simpleVarcharlistToTable](@lcPageLbl,',')      
   where CAST (id as CHAR(10)) in (select PKINPGNMUK from @tPageDesc)      
 ELSE      
 --- empty or null customer or part number means no selection were made      
 IF  @lcPageLbl='All'       
 BEGIN      
  INSERT INTO @tPageD SELECT PKINPGNMUK FROM @tPageDesc      
      
 END       
      
 --select * from @tPageD      
      
 -- 04/22/15 VL added to delete all invoice last batch if @firstinBatch = 1      
 IF @firstinBatch = 1      
 BEGIN      
  DELETE FROM PrevStat WHERE FIELDTYPE = 'INVOICE'      
 END      
      
 -- 01/10/18 VL create temp tables to replace the CTE cursor, found if the PK has lots of serial numbers, the remove zero and start-end SN code used too much resource and got hang, temp tables with indexes really speed up      
 CREATE TABLE #PLSerial (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10))      
 CREATE TABLE #startingPoints (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10), rownum int)      
 CREATE TABLE #EndingPoints (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10), rownum int)      
 CREATE TABLE #StartEndSerialno (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10), rownum int, start_range numeric(30,0), end_range numeric(30,0))      
 CREATE TABLE #FinalSerialno (Serialno varchar(MAX), Packlistno char(10), Uniqueln char(10))      
 CREATE NONCLUSTERED INDEX Packlistno ON #PLSerial (Packlistno)      
 CREATE NONCLUSTERED INDEX Uniqueln ON #PLSerial (Uniqueln)      
 CREATE NONCLUSTERED INDEX Packlistno ON #startingPoints (Packlistno)      
 CREATE NONCLUSTERED INDEX Uniqueln ON #startingPoints (Uniqueln)      
 CREATE NONCLUSTERED INDEX Packlistno ON #EndingPoints (Packlistno)      
 CREATE NONCLUSTERED INDEX Uniqueln ON #EndingPoints (Uniqueln)      
 CREATE NONCLUSTERED INDEX Packlistno ON #StartEndSerialno (Packlistno)      
 CREATE NONCLUSTERED INDEX Uniqueln ON #StartEndSerialno (Uniqueln)      
 CREATE NONCLUSTERED INDEX Packlistno ON #FinalSerialno (Packlistno)      
 CREATE NONCLUSTERED INDEX Uniqueln ON #FinalSerialno (Uniqueln)      
      
  declare @lcPacklistno char(10) = '', @llPrint_invo bit, @lcDisc_gl_no char(13)      
--08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.      
  -- 07/16/18 VL changed custname from char(35) to char(50)      
  -- 08/12/20 VL added invoice footnote from wmNotes
  -- 11/19/20 YS modified shipto/billto to 50 char
  declare @tresults table (invoiceno char(10),packlistno char(10),CUSTNO char(10), CUSTNAME char(50),SONO char(10),PONO char(20),INVDATE smalldatetime,shipdate smalldatetime,ORDERDATE smalldatetime      
        ,TERMS char(15),INV_FOOT text,Line_no char (10) /*03/12/2014 DRP:  ,Line_No char(7)*/       
        --- 03/28/17 YS changed length of the part_no column from 25 to 35       
        ,sortby char(7),Uniq_key char(10),PartNO char(35),Rev char(8),Descript char(50),CustPartNo char(35),CustRev char(8),CDescript char(50)      
        ,UOFMEAS char(4),SHIPPEDQTY numeric (12,2),NOTE text,PLPRICELNK char(10),pDesc char(50),QUANTITY numeric (12,2),PRICE numeric(14,5),EXTENDED numeric(12,2)      
        ,TAXABLE char(1),FLAT char(1),RecordType char(1),TotalExt numeric(12,2),dsctamt numeric(12,2),TotalTaxExt numeric(12,2),FreightAmt numeric(12,2),FreightTaxAmt numeric(12,2)      
        ,PTax numeric(12,2),STax numeric(12,2),InvTotal numeric(12,2),Attn varchar(200),FOREIGNTAX Char(1),SHIPTO char(50),ShipToAddress Text      
        --,ShipAdd1 char(40),ShipAdd2 char(40),ShipAdd3 char(40),ShipAdd4 char(40) --07/06/15 DRP:  replaced with the single ShipToAddress      
        ,pkfootnote text,BillTo Char(50),BillToAddress Text      
        --,BillAdd1 char(40),BillAdd2 char(40),BillAdd3 char(40),BillAdd4 char(40) --07/06/15 DRP:  replaced with the single BillToAddress       
        ,FOB char(15),SHIPVIA char(15)      
        ,BILLACOUNT char(20),WAYBILL char(20),IsRMA varchar(3),Soreps varchar(max),INFOOTNOTE text,print_invo bit,SoBalance numeric(9,2),SerialNo varchar (max),uniqueln char(10)      
        ,PTaxId char(8), STaxId char(8)      
        ,CombinedPrice numeric(14,5),CombinedExtPrice numeric(12,2)  --08/15/16 DRP:  added to combine all prices breaks into one value.       
        ,is_invpost bit  --02/27/17 DRP:  added for Unrelease on form      
        ,nRec numeric(3) --06/27/17 DRP:  Added   
  ,InvoiceType CHAR(20) -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
     ,pltype CHAR(20)   
		-- 08/12/20 VL added invoice footnote from wmNotes
		,InvFootNote TEXT
	 
        )      
      
 --02/10/16 VL created with FC fields, tried not to touch original code      
  -- 04/01/16 VL remove ShipAdd1 char(40),ShipAdd2 char(40),ShipAdd3 char(40),ShipAdd4 char(40),BillAdd1 char(40),BillAdd2 char(40),BillAdd3 char(40),BillAdd4 char(40), and use one field ShipToaddress, BillToAddress Text to save all address line like PO form      
  -- 04/01/16 VL added TCurrency and FCurrency      
  -- 04/08/16 VL added PTaxId char(8) and STaxId char(8)      
  -- 07/16/18 VL changed custname from char(35) to char(50) 
  -- 08/12/20 VL added invoice footnote from wmNotes
  declare @tresultsFC table (invoiceno char(10),packlistno char(10),CUSTNO char(10), CUSTNAME char(50),SONO char(10),PONO char(20),INVDATE smalldatetime,shipdate smalldatetime,ORDERDATE smalldatetime      
        ,TERMS char(15),INV_FOOT text,Line_no char (10) /*03/12/2014 DRP:  ,Line_No char(7)*/        
        --- 03/28/17 YS changed length of the part_no column from 25 to 35      
        ,sortby char(7),Uniq_key char(10),PartNO char(35),Rev char(8),Descript char(50),CustPartNo char(35),CustRev char(8),CDescript char(50)      
        ,UOFMEAS char(4),SHIPPEDQTY numeric (12,2),NOTE text,PLPRICELNK char(10),pDesc char(50),QUANTITY numeric (12,2),PRICE numeric(14,5),EXTENDED numeric(12,2)      
        ,TAXABLE char(1),FLAT char(1),RecordType char(1),TotalExt numeric(12,2),dsctamt numeric(12,2),TotalTaxExt numeric(12,2),FreightAmt numeric(12,2),FreightTaxAmt numeric(12,2)      
        ,PTax numeric(12,2),STax numeric(12,2),InvTotal numeric(12,2),Attn varchar(200),FOREIGNTAX Char(1),SHIPTO char(40),ShipToAddress Text      
        --,ShipAdd1 char(40),ShipAdd2 char(40),ShipAdd3 char(40),ShipAdd4 char(40) --07/06/15 DRP:  replaced with the single ShipToAddress      
        ,pkfootnote text,BillTo Char(40),BillToAddress Text      
        --,BillAdd1 char(40),BillAdd2 char(40),BillAdd3 char(40),BillAdd4 char(40) --07/06/15 DRP:  replaced with the single BillToAddress       
        ,FOB char(15),SHIPVIA char(15)      
        ,BILLACOUNT char(20),WAYBILL char(20),IsRMA varchar(3),Soreps varchar(max),INFOOTNOTE text,print_invo bit,SoBalance numeric(9,2),SerialNo varchar (max),uniqueln char(10)      
        ,CombinedPrice numeric(14,5),CombinedExtPrice numeric(12,2)  --08/15/16 DRP:  added to combine all prices breaks into one value.       
        ,PRICEFC numeric(14,5),EXTENDEDFC numeric(12,2),TotalExtFC numeric(12,2),dsctamtFC numeric(12,2),TotalTaxExtFC numeric(12,2)      
        ,FreightAmtFC numeric(12,2),FreightTaxAmtFC numeric(12,2), PTaxFC numeric(12,2),STaxFC numeric(12,2),InvTotalFC numeric(12,2)      
         ,TSymbol CHAR(10), FSymbol CHAR(10),PSymbol CHAR(10), PTaxId char(8), STaxId char(8)      
         ,PRICEPR numeric(14,5),EXTENDEDPR numeric(12,2),TotalExtPR numeric(12,2),dsctamtPR numeric(12,2),TotalTaxExtPR numeric(12,2)      
        ,FREIGHTAMTPR numeric(12,2),FreightTaxAmtPR numeric(12,2),PTAXPR numeric(12,2),STAXPR numeric(12,2),INVTOTALPR numeric(12,2)      
        ,CombinedPriceFC numeric(14,5),CombinedExtPriceFC numeric(12,2),CombinedPricePR numeric(14,5),CombinedExtPricePR numeric(12,2)        
        ,is_invpost bit  --02/27/17 DRP:  added for Unrelease on form      
        ,nRec numeric(3) --06/27/17 DRP:  Added   
  ,InvoiceType CHAR(20) -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
     ,pltype CHAR(20)  
	 	-- 08/12/20 VL added invoice footnote from wmNotes
		,InvFootNote TEXT

        )      
      
  SET @lcInvNo=dbo.PADL(@lcInvNo,10,'0')      
  SELECT @lcPacklistno = Packlistno, @llPrint_invo = Print_invo       
   FROM PLMAIN       
   WHERE INVOICENO = @lcInvNo      
  SELECT @lcDisc_gl_no = Disc_gl_no FROM ARSETUP      
      
-- 02/10/16 VL added for FC installed or not      
DECLARE @lFCInstalled bit      
-- 04/08/16 VL changed to get FC installed from function      
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()      
      
--04/13/2016 DRP:  added PTaxId char(8) and STaxId char(8)      
--02/03/2017 DRP:  needed to change from <<TaxType = 'S'>> to be <<TaxType = 'E'>>, I also need to change <<sono = @lcSoNo>> to be <<sono = dbo.padl(@lcSoNo,10,'0')>>      
DECLARE @PTaxID char(8), @STaxID char(8)      
SELECT @PTaxId = ISNULL((SELECT TOP 1 Tax_id FROM PLPRICESTAX WHERE Packlistno = @lcPacklistno AND TaxType = 'P' ORDER BY Tax_id), SPACE(8))      
SELECT @STaxId = ISNULL((SELECT TOP 1 Tax_id FROM PLPRICESTAX WHERE Packlistno = @lcPacklistno AND TaxType = 'E' ORDER BY Tax_id), SPACE(8))      
      
/******FC NOT INSTALLED******/      
BEGIN      
IF @lFCInstalled = 0       
-- FC not installed       
 BEGIN      
/*--04/24/2013 DRP:  BEGIN:  added the serial number information to the invoice as an option to display if desired */      
  -- 01/10/18 VL changed to use temp table      
  --;      
  --with      
  --this section will go through and compile any Serialno information      
  --PLSerial AS      
  --   (      
  INSERT INTO #PLSerial      
 /*04/08/2014 drp: SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) as iSerialno,ps.packlistno,PS.UNIQUELN  */      
     SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0)) as iSerialno,ps.packlistno,PS.UNIQUELN         
     FROM packlser PS       
     where PS.PACKLISTNO = @lcPackListNo      
     AND PATINDEX('%[^0-9]%',PS.serialno)=0       
     -- 01/10/18 VL changed to use temp table      
     --)      
     --,startingPoints as      
     --(      
     INSERT INTO #startingPoints      
     select A.*, ROW_NUMBER() OVER(PARTITION BY A.packlistno,uniqueln ORDER BY iSerialno) AS rownum      
     FROM #PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM #PLSerial AS B WHERE B.iSerialno=A.iSerialno-1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN )      
     -- 01/10/18 VL changed to use temp table      
     --)      
    --SELECT * FROM StartingPoints        
      --,      
   --EndingPoints AS      
   --(      
   INSERT INTO #EndingPoints      
   select A.*, ROW_NUMBER() OVER(PARTITION BY packlistno,uniqueln ORDER BY iSerialno) AS rownum      
   FROM #PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM #PLSerial AS B WHERE B.iSerialno=A.iSerialno+1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN)       
   -- 01/10/18 VL changed to use temp table      
   --)      
   --SELECT * FROM EndingPoints      
   --,      
   --StartEndSerialno AS       
   --(      
   INSERT INTO #StartEndSerialno      
   SELECT S.*,S.iSerialno AS start_range, E.iSerialno AS end_range      
   FROM #StartingPoints AS S      
   JOIN #EndingPoints AS E      
   ON E.rownum = S.rownum and E.PACKLISTNO = S.PACKLISTNO and E.UNIQUELN =S.UNIQUELN       
   -- 01/10/18 VL changed to use temp table      
   --)      
   --,FinalSerialno AS      
   --(      
   INSERT INTO #FinalSerialno      
   SELECT CASE WHEN A.start_range=A.End_range      
     THEN CAST(RTRIM(CONVERT(char(30),A.start_range))  as varchar(MAX)) ELSE      
     CAST(RTRIM(CONVERT(char(30),A.start_range))+'-'+RTRIM(CONVERT(char(30),A.End_range)) as varchar(MAX)) END as Serialno,      
     packlistno,uniqueln      
   FROM #StartEndSerialno  A      
   UNION       
   SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as varchar(max)) as Serialno,PS.packlistno,PS.UNIQUELN        
    from PACKLSER ps       
    where ps.PACKLISTNO = @lcPackListNo      
    and (PS.Serialno LIKE '%[a-z]%' OR PATINDEX('%[^0-9A-Za-z]%',Ps.serialno)<>0)       
   --)      
   --select * from FinalSerialno      
--04/24/2013 DRP:  END:      
      
  --04/13/2012 DRP: found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired.       
  --     added the sortby field below to address this situation.       
  --08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.      
  -- 01/10/18 VL changed to insert @tResults directly      
  --,      
  --Invoice as (       
  INSERT INTO @tresults      
  -- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql     
  SELECT plmain.INVOICENO,plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,PLMAIN.SONO,isnull(SOMAIN.PONO,plmain.pono) as pono,plmain.invdate,plmain.shipdate,SOMAIN.ORDERDATE        
      ,PLMAIN.TERMS,PLMAIN.INV_FOOT,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No      
   ,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby      
      --- 03/28/17 YS changed length of the part_no column from 25 to 35      
      ,isnull(sodetail.uniq_key,space(10))as Uniq_key,isnull(inventor.PART_NO,SPACE(35)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev      
      ,ISNULL(cast(inventor.descript as CHAR(50)),CAST(pldetail.cdescr as CHAR(50))) as Descript      
      --- 03/28/17 YS changed length of the part_no column from 25 to 35      
      ,ISNULL(i2.custpartno,SPACE(35)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (50)),cast (pldetail.cdescr as CHAR(50))) as CDescript      
      ,PLDETAIL.UOFMEAS,pldetail.SHIPPEDQTY,pldetail.NOTE,plp.PLPRICELNK,plp.DESCRIPT AS pDesc,plp.QUANTITY,plp.PRICE,plp.EXTENDED      
      ,CASE WHEN plp.TAXABLE = 1 then CAST('Y' as CHAR(1)) else CAST('' as CHAR(1)) end as Taxable,plp.FLAT,plp.RECORDTYPE,plmain.TOTEXTEN AS TotalExt,plmain.dsctamt      
      ,plmain.tottaxe as TotalTaxExt,plmain.FREIGHTAMT,plmain.TOTTAXF as FreightTaxAmt,plmain.PTAX,plmain.STAX,plmain.INVTOTAL      
      ,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn      
      ,cast (S.FOREIGNTAX as char(1))as FOREIGNTAX      
      ,s.SHIPTO      
      ,rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+      
      -- 04/01/16 VL added address3 and 4      
      case when s.address3<> '' then char(13)+char(10)+rtrim(s.ADDRESS3) else '' end+      
      case when s.address4<> '' then char(13)+char(10)+rtrim(s.address4) else '' end+      
       CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +      
       CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end+      
       case when s.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(s.PHONE) else '' end+      
       case when s.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(s.FAX) else '' end  as ShipToAddress      
      --,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2 --07/06/15 DRP:  replaced with the single ShipToAddress      
      --,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3      
      --,case when s.address2 <> '' then s.country else '' end as ShipAdd4      
      ,s.PKFOOTNOTE      
      ,b.SHIPTO as BillTo      
      ,rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+      
      -- 04/01/16 VL added address3 and 4      
      case when b.address3<> '' then char(13)+char(10)+rtrim(b.ADDRESS3) else '' end+      
      case when b.address4<> '' then char(13)+char(10)+rtrim(b.address4) else '' end+      
  CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +      
  CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end+      
  case when b.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(b.PHONE) else '' end+      
  case when b.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(b.FAX) else '' end  as BillToAddress      
      --,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2 --07/06/15 DRP:  replaced with the single ShipToAddress      
      --,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3      
      --,case when b.address2 <> '' then b.country else '' end as BillAdd4      
      ,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT      
      ,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA      
      ,isnull(dbo.FnSoRep(plmain.sono),'') as Soreps ,B.INFOOTNOTE,PRINT_INVO,pldetail.SOBALANCE      
   --04/23/2013 DRP:  added serianl number field      
      --,CAST(stuff((select','+ps.Serialno from FinalSerialno PS      
      --       where PS.PACKLISTNO = PLMAIN.PACKLISTNO      
      --         AND PS.UNIQUELN = PLDETAIL.UNIQUELN      
      --       ORDER BY SERIALNO FOR XML PATH ('')),1,1,'') AS VARCHAR (MAX)) AS Serialno --02/13/2015 DRP:  Replaced with the below      
      ,CAST(stuff((select', '+ps.Serialno from #FinalSerialno PS      
             where PS.PACKLISTNO = PLMAIN.PACKLISTNO      
               AND PS.UNIQUELN = PLDETAIL.UNIQUELN      
             ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS Serialno      
      ,pldetail.uniqueln        
      ,@PTaxId AS PTaxId, @STaxId AS STaxID          
      ,cast(0.00 as numeric (14,5)) as CombinedPrice,cast(0.00 as numeric (12,2)) as CombinedExtPrice  --08/15/16 DRP:  Added      
      ,plmain.is_invpost --02/27/17 DRP:  Added      
      ,row_number() OVER (partition by sodetail.Uniqueln order by plp.recordtype desc) as nRec --06/27/17 DRP:  Added      
      ,ISNULL(PLMAIN.InvoiceType,'') as InvoiceType -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
   ,ISNULL(PLMAIN.pltype,'') as pltype  
	   -- 08/12/20 VL added invoice footnote from wmNotes
	  ,InvFootNote.Note AS InvFootNote   
      from PLMAIN      
      inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO      
      LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO      
      left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO      
      left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN      
      left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY      
   --10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the invoice.           
      --left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ      
      left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO      
      left outer join CCONTACT on plmain.attention = ccontact.cid      
      --left outer join SHIPBILL as S on somain.custno = s.custno and sodetail.slinkadd = s.linkadd --10/28/16 DRP: changed --03/17/17 DRP:  replaced with the below      
      left outer join SHIPBILL as S on plmain.custno = s.custno and plmain.LINKADD = s.linkadd --03/17/17 DRP: needed to link to the plmain.linkadd instead of the sodetail      
      left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD and plmain.CUSTNO = b.CUSTNO          
      left outer join PLPRICES as plp on PLDETAIL.UNIQUELN = PLP.UNIQUELN and pldetail.PACKLISTNO = plp.PACKLISTNO      
      left outer join SOPRSREP on PLDETAIL.UNIQUELN = soprsrep.UNIQUELN    
	  -- 08/12/20 VL added invoice footnote from wmNotes
		OUTER APPLY (SELECT TOP 1 r.* 
		FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'PLMAIN_INVFN' AND w.RecordId = Plmain.Invoiceno
		ORDER BY r.CreatedDate DESC) InvFootNote
		
      where plmain.INVOICENO =@lcInvNo      
        and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno) --08/15/16 DRP:  added      
        --AND ((@showZeroAmtInv=0 AND plmain.INVTOTAL > 0) OR (@showZeroAmtInv=1 AND 1=1)) 
		-- 06/06/20 Satyawan H: Check to show invoices with 0 balance  
		-- 08/10/20 Satywawn H: remove zero balance invoice parameter
    --)       
      
  -- 01/10/18 VL comment out       
  --INSERT into @tResults      
  --select * from Invoice       
      
  --select * from @tresults end end      
      
      
      
  --08/15/16 DRP:  added both the zcnt and zcombP to help me calculate the combined Pricing information.       
  /*06/27/17 removal beginning      
  ; with zcnt as (      
      select uniqueln, count (*) n       
      from @tresults       
      group by uniqueln      
      )      
      --select * from zcnt      
  ,      
   zcombP as(      
     select  A.uniqueln,case when x.n = 1 then A.price else      
       case when x.n <> 1 and  RECORDTYPE = 'P' then Sum(Extended) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end end as CPrice --04/21/17 DRP:  changed from <<(partition by A.uniqueln)/Quantity>> to be <<(partition by A.uniqueln)/nullif 
  
  
   
(Quantity,0)>>      
     from @tresults A      
       inner join zcnt as X on a.uniqueln = x.uniqueln      
      
     )      
 --select * from zcombP      
      
      
  update @tresults set CombinedPrice = P.FinalP,CombinedExtPrice = QUANTITY*P.FinalP from (select uniqueln,sum(CPrice) as FinalP from zcombP  group by uniqueln)P,@tresults M where M.uniqueln = P.uniqueln and M.recordtype = 'P'      
  --select * from @tresults      
  06/27/17 Removal End*/      
      
  --06/27/17 DRP:  Below replaces the above section that was removed.       
 ;with zcombP as (      
     select A.uniqueln,A.Uniq_key,price,extended,recordtype,quantity ,pdesc,   
  row_number() OVER (partition by Uniqueln order by recordtype desc) as nRec from @tresults A      
     ) --06/27/17 DRP:  Added      
       
 update @tresults set CombinedPrice = P.cprice,CombinedExtPrice = QUANTITY*P.cprice       
 from @tresults M       
   inner join (select A.uniqueln,A.Uniq_key,pdesc       
        ,case when nrec=1 then Sum(Extended) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end as cprice      
      from zcombP a) P  on M.uniqueln = P.uniqueln       
 where M.nrec=1      
      
--08/15/16 DRP:  added the If section to determine how to show the results based on if the user wants to combine the Pricing into one line item or not.       
  if @lcCombinePrice = 'No'      
   begin      
    select invoiceno  
 -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
     ,CASE WHEN TRIM(A.InvoiceType) = 'Manual' AND TRIM(A.plType) = '' THEN '' ELSE packlistno END AS packlistno  
  ,A.CUSTNO, CUSTNAME,SONO,PONO,INVDATE,shipdate,ORDERDATE      
        ,TERMS,INV_FOOT ,Line_no ,sortby ,Uniq_key ,PartNO ,Rev ,Descript ,CustPartNo ,CustRev ,CDescript       
        ,UOFMEAS ,SHIPPEDQTY ,NOTE ,PLPRICELNK ,pDesc ,QUANTITY ,PRICE ,EXTENDED       
        ,TAXABLE ,FLAT ,A.RecordType ,TotalExt ,dsctamt ,TotalTaxExt ,FreightAmt ,FreightTaxAmt       
        ,PTax ,STax ,InvTotal ,Attn ,A.FOREIGNTAX ,A.SHIPTO ,ShipToAddress       
        ,A.pkfootnote ,BillTo ,BillToAddress,A.FOB ,A.SHIPVIA       
        ,A.BILLACOUNT ,WAYBILL ,IsRMA ,Soreps ,A.INFOOTNOTE ,print_invo ,SoBalance ,SerialNo ,uniqueln       
        ,w.pkinpgnmuk,w.PAGEDESC,w.PAGENO      
        ,is_invpost --02/27/17 DRP:  Added      
        , PTaxId , STaxId --04/19/17 DRP:  Added      
		-- 08/12/20 VL added invoice footnote from wmNotes
	   ,InvFootNote            
    from @tresults A  
      cross apply (SELECT D.PKINPGNMUK,T.PAGEDESC,T.PAGENO FROM  @tPageD D,@tPageDesc T  WHERE D.PKINPGNMUK = T.PKINPGNMUK) W    
            
    order by pageno,line_no       
   End      
  Else if @lcCombinePrice = 'Yes'      
   Begin      
      
   select invoiceno  
   -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
        ,CASE WHEN TRIM(A.InvoiceType) = 'Manual' AND TRIM(A.plType) = '' THEN '' ELSE packlistno END AS packlistno  
  ,A.CUSTNO, CUSTNAME,SONO,PONO,INVDATE,shipdate,ORDERDATE      
        ,TERMS,INV_FOOT ,Line_no ,sortby ,Uniq_key ,PartNO ,Rev ,Descript ,CustPartNo ,CustRev ,CDescript       
        ,UOFMEAS ,SHIPPEDQTY ,NOTE ,PLPRICELNK ,pDesc ,QUANTITY ,CombinedPrice as PRICE , CombinedExtPrice as EXTENDED       
        ,TAXABLE ,FLAT ,A.RecordType ,TotalExt ,dsctamt ,TotalTaxExt ,FreightAmt ,FreightTaxAmt       
        ,PTax ,STax ,InvTotal ,Attn ,A.FOREIGNTAX ,A.SHIPTO ,ShipToAddress       
        ,A.pkfootnote ,BillTo ,BillToAddress,A.FOB ,A.SHIPVIA       
        ,A.BILLACOUNT ,WAYBILL ,IsRMA ,Soreps ,A.INFOOTNOTE ,print_invo ,SoBalance ,SerialNo ,uniqueln       
        ,w.pkinpgnmuk,w.PAGEDESC,w.PAGENO         
        ,is_invpost --02/27/17 DRP:  Added      
        , PTaxId , STaxId --04/19/17 DRP:  Added     
		-- 08/12/20 VL added invoice footnote from wmNotes
	   ,InvFootNote		
   from @tresults A      
     cross apply  (SELECT D.PKINPGNMUK,T.PAGEDESC,T.PAGENO FROM  @tPageD D,@tPageDesc T  WHERE D.PKINPGNMUK = T.PKINPGNMUK) W       
   where A.nRec = 1      
     --where 1 = case when left(uniqueln,1) = '*' then 1 when RecordType = 'P' then 1 else 0 end --06/27/17 DRP:  replaced with the above A.nRec = 1      
     --RecordType = 'P' --08/30/16 DRP:  Replaced with the above      
   order by pageno,line_no       
      
      
   End      
      
      
  -- 04/18/2012 DRP: added the below code to just indicate if the invoice has been printed       
  UPDATE PLMAIN SET  is_InPrint = 1 WHERE PLMAIN.INVOICENO =@lcInvNo      
      
  -- 04/22/15 VL added to update PrevStat to save last batch      
  INSERT INTO PrevStat (FIELDTYPE, FIELDKEY) VALUES ('INVOICE', @lcInvNo)      
      
  -- 04/18/2012 DRP:  removed the below code that created AR records upon invoice printing.      
  --IF @llPrint_invo = 0      
  --BEGIN      
  -- -- Re-calculate invoice total      
  -- EXEC sp_Invoice_Total @lcPacklistno      
  -- UPDATE PLMAIN SET  is_invpost = 1, print_invo = 1, inv_dupl = 1, DISC_GL_NO = @lcDisc_gl_no, INV_INIT = @lcUser_id WHERE PLMAIN.INVOICENO =@lcInvNo       
  -- EXEC sp_InvoicePost @lcpacklistno                                    
  --END            
 END      
ELSE      
        
/******FC INSTALLED******/        
 BEGIN      
 --SELECT INVOICENO FROM PLMAIN WHERE PLMAIN.INVOICENO =@lcInvNo      
  -- 01/10/18 VL changed to use temp table      
  --;      
  --with      
  --this section will go through and compile any Serialno information      
  --PLSerial AS      
  --   (      
  INSERT INTO #PLSerial      
 /*04/08/2014 drp: SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) as iSerialno,ps.packlistno,PS.UNIQUELN  */      
     SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0)) as iSerialno,ps.packlistno,PS.UNIQUELN         
     FROM packlser PS       
     where PS.PACKLISTNO = @lcPackListNo      
     AND PATINDEX('%[^0-9]%',PS.serialno)=0       
     -- 01/10/18 VL changed to use temp table      
     --)      
     --,startingPoints as      
     --(      
     INSERT INTO #startingPoints      
     select A.*, ROW_NUMBER() OVER(PARTITION BY A.packlistno,uniqueln ORDER BY iSerialno) AS rownum      
     FROM #PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM #PLSerial AS B WHERE B.iSerialno=A.iSerialno-1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN )      
     -- 01/10/18 VL changed to use temp table      
     --)      
    --SELECT * FROM StartingPoints        
      --,      
   --EndingPoints AS      
   --(      
   INSERT INTO #EndingPoints      
   select A.*, ROW_NUMBER() OVER(PARTITION BY packlistno,uniqueln ORDER BY iSerialno) AS rownum      
   FROM #PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM #PLSerial AS B WHERE B.iSerialno=A.iSerialno+1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN)       
   -- 01/10/18 VL changed to use temp table      
   --)      
   --SELECT * FROM EndingPoints      
   --,      
   --StartEndSerialno AS       
   --(      
   INSERT INTO #StartEndSerialno      
   SELECT S.*,S.iSerialno AS start_range, E.iSerialno AS end_range      
   FROM #StartingPoints AS S      
   JOIN #EndingPoints AS E      
   ON E.rownum = S.rownum and E.PACKLISTNO = S.PACKLISTNO and E.UNIQUELN =S.UNIQUELN       
   -- 01/10/18 VL changed to use temp table      
   --)      
   --,FinalSerialno AS      
   --(      
   INSERT INTO #FinalSerialno      
   SELECT CASE WHEN A.start_range=A.End_range      
     THEN CAST(RTRIM(CONVERT(char(30),A.start_range))  as varchar(MAX)) ELSE      
     CAST(RTRIM(CONVERT(char(30),A.start_range))+'-'+RTRIM(CONVERT(char(30),A.End_range)) as varchar(MAX)) END as Serialno,      
     packlistno,uniqueln      
   FROM #StartEndSerialno  A      
   UNION       
   SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as varchar(max)) as Serialno,PS.packlistno,PS.UNIQUELN        
    from PACKLSER ps       
    where ps.PACKLISTNO = @lcPackListNo      
    and (PS.Serialno LIKE '%[a-z]%' OR PATINDEX('%[^0-9A-Za-z]%',Ps.serialno)<>0)       
   --)      
   --select * from FinalSerialno      
--04/24/2013 DRP:  END:      
      
  --04/13/2012 DRP: found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired.       
  --     added the sortby field below to address this situation.       
  --08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.      
  -- 01/10/18 VL changed to insert @tResults directly      
  --,      
  --Invoice as (       
  -- 05/21/18 VL should insert to @tresultsFC, not @tresults      
  INSERT INTO @tresultsFC      
  -- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql    
    select plmain.INVOICENO,plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,PLMAIN.SONO,isnull(SOMAIN.PONO,plmain.pono) as pono,plmain.invdate,plmain.shipdate,SOMAIN.ORDERDATE        
      ,PLMAIN.TERMS,PLMAIN.INV_FOOT,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No      
      ,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby      
      --- 03/28/17 YS changed length of the part_no column from 25 to 35      
      ,isnull(sodetail.uniq_key,space(10))as Uniq_key,isnull(inventor.PART_NO,SPACE(35)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev      
      ,ISNULL(cast(inventor.descript as CHAR(50)),CAST(pldetail.cdescr as CHAR(50))) as Descript      
      --- 03/28/17 YS changed length of the part_no column from 25 to 35      
      ,ISNULL(i2.custpartno,SPACE(35)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (50)),cast (pldetail.cdescr as CHAR(50))) as CDescript      
      ,PLDETAIL.UOFMEAS,pldetail.SHIPPEDQTY,pldetail.NOTE,plp.PLPRICELNK,plp.DESCRIPT AS pDesc,plp.QUANTITY,plp.PRICE,plp.EXTENDED      
      ,case when plp.TAXABLE = 1 then CAST('Y' as CHAR(1)) else CAST('' as CHAR(1)) end as Taxable,plp.FLAT,plp.RECORDTYPE,plmain.TOTEXTEN AS TotalExt,plmain.dsctamt      
      ,plmain.tottaxe as TotalTaxExt,plmain.FREIGHTAMT,plmain.TOTTAXF as FreightTaxAmt,plmain.PTAX,plmain.STAX,plmain.INVTOTAL      
      ,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn      
      ,cast (S.FOREIGNTAX as char(1))as FOREIGNTAX      
      ,s.SHIPTO      
      ,rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+      
      -- 04/01/16 VL added address3 and 4      
      case when s.address3<> '' then char(13)+char(10)+rtrim(s.ADDRESS3) else '' end+      
      case when s.address4<> '' then char(13)+char(10)+rtrim(s.address4) else '' end+      
       CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +      
       CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end+      
       case when s.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(s.PHONE) else '' end+      
       case when s.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(s.FAX) else '' end  as ShipToAddress      
      --,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2 --07/06/15 DRP:  replaced with the single ShipToAddress      
      --,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3      
      --,case when s.address2 <> '' then s.country else '' end as ShipAdd4      
      ,s.PKFOOTNOTE      
      ,b.SHIPTO as BillTo      
      ,rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+      
      -- 04/01/16 VL added address3 and 4      
      case when b.address3<> '' then char(13)+char(10)+rtrim(b.ADDRESS3) else '' end+      
      case when b.address4<> '' then char(13)+char(10)+rtrim(b.address4) else '' end+      
       CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +      
       CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end+      
       case when b.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(b.PHONE) else '' end+      
       case when b.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(b.FAX) else '' end  as BillToAddress      
      --,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2 --07/06/15 DRP:  replaced with the single ShipToAddress      
      --,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3      
      --,case when b.address2 <> '' then b.country else '' end as BillAdd4      
      ,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT      
      ,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA      
      ,isnull(dbo.FnSoRep(plmain.sono),'') as Soreps ,B.INFOOTNOTE,PRINT_INVO,pldetail.SOBALANCE      
--04/23/2013 DRP:  added serianl number field      
      --,CAST(stuff((select','+ps.Serialno from FinalSerialno PS      
      --       where PS.PACKLISTNO = PLMAIN.PACKLISTNO      
      --         AND PS.UNIQUELN = PLDETAIL.UNIQUELN      
      --       ORDER BY SERIALNO FOR XML PATH ('')),1,1,'') AS VARCHAR (MAX)) AS Serialno --02/13/2015 DRP:  Replaced with the below      
      ,CAST(stuff((select', '+ps.Serialno from #FinalSerialno PS      
             where PS.PACKLISTNO = PLMAIN.PACKLISTNO      
               AND PS.UNIQUELN = PLDETAIL.UNIQUELN      
ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS Serialno      
      ,pldetail.uniqueln            
      ,cast(0.00 as numeric (14,5)) as CombinedPrice,cast(0.00 as numeric (12,2)) as CombinedExtPrice  --08/15/16 DRP:  Added      
      ,plp.PRICEFC,plp.EXTENDEDFC,plmain.TOTEXTENFC AS TotalExtFC,plmain.dsctamtFC,plmain.tottaxeFC as TotalTaxExtFC,plmain.FREIGHTAMTFC,plmain.TOTTAXFFC as FreightTaxAmtFC,plmain.PTAXFC,plmain.STAXFC,plmain.INVTOTALFC      
      ,TF.Symbol AS TSymbol, FF.Symbol AS FSymbol, PF.Symbol AS PSymbol,@PTaxId AS PTaxId, @STaxId AS STaxID      
      ,plp.PRICEPR,plp.EXTENDEDPR,plmain.TOTEXTENPR AS TotalExtPR,plmain.dsctamtPR      
      ,plmain.tottaxePR as TotalTaxExtPR,plmain.FREIGHTAMTPR,plmain.TOTTAXFPR as FreightTaxAmtPR,plmain.PTAXPR,plmain.STAXPR,plmain.INVTOTALPR      
      ,cast(0.00 as numeric (14,5)) as CombinedPricefC,cast(0.00 as numeric (12,2)) as CombinedExtPriceFC      
      ,cast(0.00 as numeric (14,5)) as CombinedPricePR,cast(0.00 as numeric (12,2)) as CombinedExtPricePR       
      ,is_invpost --02/27/17 DRP:  Added       
      ,row_number() OVER (partition by sodetail.Uniqueln order by plp.recordtype desc) as nRec --06/27/17 DRP:  Added          
      ,ISNULL(PLMAIN.InvoiceType,'') as InvoiceType -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
   ,ISNULL(PLMAIN.pltype,'') as pltype    
	  -- 08/12/20 VL added invoice footnote from wmNotes
	  ,InvFootNote.Note AS InvFootNote   
      from PLMAIN inner join       
      -- 10/28/16  DRP added Fcused 3 times to get 3 currencies      
         dbo.Fcused TF ON PLMAIN.Fcused_uniq = TF.Fcused_uniq INNER JOIN      
         dbo.Fcused FF ON PLMAIN.FUNCFCUSED_UNIQ = FF.Fcused_uniq INNER JOIN      
         dbo.Fcused PF ON PLMAIN.PRFcused_uniq = PF.Fcused_uniq       
      inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO      
      LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO      
      left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO      
      left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN      
      left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY      
--10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the invoice.           
      --left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ      
      left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO      
      left outer join CCONTACT on plmain.attention = ccontact.cid      
      --left outer join SHIPBILL as S on somain.custno = s.custno and sodetail.slinkadd = s.linkadd --10/28/16 DRP: changed --03/17/17 DRP:  replaced with the below.       
      left outer join SHIPBILL as S on plmain.CUSTNO = s.CUSTNO and plmain.LINKADD = s.LINKADD --03/17/17 DRP: --03/17/17 DRP: needed to link to the plmain.linkadd instead of the sodetail      
      left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD and plmain.CUSTNO = b.CUSTNO          
      left outer join PLPRICES as plp on PLDETAIL.UNIQUELN = PLP.UNIQUELN and pldetail.PACKLISTNO = plp.PACKLISTNO      
      left outer join SOPRSREP on PLDETAIL.UNIQUELN = soprsrep.UNIQUELN        
	  -- 08/12/20 VL added invoice footnote from wmNotes
		OUTER APPLY (SELECT TOP 1 r.* 
		FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'PLMAIN_INVFN' AND w.RecordId = Plmain.Invoiceno
		ORDER BY r.CreatedDate DESC) InvFootNote
            
      where plmain.INVOICENO =@lcInvNo      
        and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno) --08/15/16 DRP:  added      
        --AND ((@showZeroAmtInv=0 AND plmain.INVTOTAL > 0) OR (@showZeroAmtInv=1 AND 1=1)) 
		-- 06/06/20 Satyawan H: Check to show invoices with 0 balance  
        -- 08/10/20 Satywawn H: remove zero balance invoice parameter
    --)       
      
      
  -- 01/10/18 VL comment out      
  --INSERT @tResultsFC      
  --select * from Invoice      
      
  --select * from @tresultsFc end end      
      
  --08/15/16 DRP:  added both the zcnt and zcombP to help me calculate the combined Pricing information.      
  /*06/27/17 removal beginning       
  ; with zcnt as (      
      select uniqueln, count (*) n       
      from @tresultsFC       
      group by uniqueln      
      )      
      --select * from zcnt      
  ,      
   zcombP as(      
     select  A.uniqueln,case when x.n = 1 then A.price else case when x.n <> 1 and  RECORDTYPE = 'P' then Sum(Extended) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end end as CPrice --04/21/17 DRP:  changed from <<(partition by A.uniqueln 
 
  
)/Quantity>> to be <<(partition by A.uniqueln)/nullif(Quantity,0)>>      
       ,case when x.n = 1 then A.PRICEFC else case when x.n <> 1 and  RECORDTYPE = 'P' then Sum(ExtendedFC) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end end as CPriceFC      
       ,case when x.n = 1 then A.PRICEPR else case when x.n <> 1 and  RECORDTYPE = 'P' then Sum(ExtendedPR) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end end as CPricePR      
     from @tresultsFC A      
       inner join zcnt as X on a.uniqueln = x.uniqueln      
      
     )      
 --select * from zcombP      
 --end end      
      
  update @tresultsFC set CombinedPrice = P.FinalP,CombinedExtPrice = QUANTITY*P.FinalP      
        ,CombinedPriceFC = P.FinalPFC,CombinedExtPriceFC = QUANTITY*P.FinalPFC      
        ,CombinedPricePR = P.FinalPPR,CombinedExtPricePR = QUANTITY*P.FinalPPR       
  from (select uniqueln,sum(CPrice) as FinalP,sum(CPriceFC) as FinalPFC,sum(CPricePR) as FinalPPR from zcombP  group by uniqueln)P,@tresultsFC M where M.uniqueln = P.uniqueln and M.recordtype = 'P'      
  --select * from @tresultsFC      
  06/27/17 Removal End*/      
      
 --06/27/17 DRP:  Below replaces the above section that was removed.       
 ;with zcombP as (      
     select A.uniqueln,A.Uniq_key,price,extended,priceFC,extendedFC,pricePR,extendedPR,recordtype,quantity ,pdesc, row_number() OVER (partition by Uniqueln order by recordtype desc) as nRec from @tresultsFC A      
     )       
       
 update @tresultsFC set CombinedPrice = P.cprice,CombinedExtPrice = QUANTITY * P.cprice,CombinedPriceFC = P.cpriceFC,CombinedExtPriceFC = QUANTITY*P.cpriceFC,CombinedPricePR = P.cpricePR,CombinedExtPricePR = QUANTITY*P.cpricePR       
 from @tresultsFC M       
   inner join (select A.uniqueln,A.Uniq_key,pdesc       
        ,case when nrec=1 then Sum(Extended) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end as cprice      
        ,case when nrec=1 then Sum(ExtendedFC) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end as cpriceFC      
        ,case when nrec=1 then Sum(ExtendedPR) over (partition by A.uniqueln)/nullif(Quantity,0) else 0.00 end as cpricePR      
      from zcombP a) P  on M.uniqueln = P.uniqueln       
 where M.nrec=1      
        
--08/15/16 DRP:  added the If section to determine how to show the results based on if the user wants to combine the Pricing into one line item or not.       
  if @lcCombinePrice = 'No'      
   begin      
    select invoiceno  
 -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
     ,CASE WHEN TRIM(A.InvoiceType) = 'Manual' AND TRIM(A.plType) = '' THEN '' ELSE packlistno END AS packlistno  
     ,a.CUSTNO, CUSTNAME,SONO,PONO,INVDATE,shipdate,ORDERDATE      
        ,TERMS,INV_FOOT ,Line_no ,sortby ,Uniq_key ,PartNO ,Rev ,Descript ,CustPartNo ,CustRev ,CDescript       
        ,UOFMEAS ,SHIPPEDQTY ,NOTE ,PLPRICELNK ,pDesc ,QUANTITY ,PRICE ,EXTENDED       
        ,TAXABLE ,FLAT ,A.RecordType ,TotalExt ,dsctamt ,TotalTaxExt ,FreightAmt ,FreightTaxAmt       
        ,PTax ,STax ,InvTotal ,Attn ,A.FOREIGNTAX ,A.SHIPTO ,A.ShipToAddress       
        ,A.pkfootnote ,BillTo ,BillToAddress,A.FOB ,A.SHIPVIA       
        ,A.BILLACOUNT ,WAYBILL ,IsRMA ,Soreps ,A.INFOOTNOTE ,print_invo ,SoBalance ,SerialNo ,uniqueln      
        ,PRICEFC,EXTENDEDFC,TotalExtFC,dsctamtFC,TotalTaxExtFC,FREIGHTAMTFC,FreightTaxAmtFC,PTAXFC,STAXFC,INVTOTALFC       
        ,TSymbol,FSymbol,PSymbol,PTaxId,STaxID       
        ,PRICEPR,EXTENDEDPR,TotalExtPR,dsctamtPR,TotalTaxExtPR,FREIGHTAMTPR,FreightTaxAmtPR,PTAXPR,STAXPR,INVTOTALPR      
        ,is_invpost --02/27/17 DRP:  Added      
      
      ,w.pkinpgnmuk,w.PAGEDESC,w.PAGENO     
	   -- 08/12/20 VL added invoice footnote from wmNotes
	   ,InvFootNote	  
    from @tresultsFC A      
      cross apply  (SELECT D.PKINPGNMUK,T.PAGEDESC,T.PAGENO FROM  @tPageD D,@tPageDesc T  WHERE D.PKINPGNMUK = T.PKINPGNMUK) W      
            
    order by pageno,line_no       
   End      
  Else if @lcCombinePrice = 'Yes'      
   Begin      
      
   select invoiceno  
   -- 04/16/2020 Shivshankar P : Get InvoiceType and PlType from PLMAIN table to identify Manual Invoice without PL  
        ,CASE WHEN TRIM(A.InvoiceType) = 'Manual' AND TRIM(A.plType) = '' THEN '' ELSE packlistno END AS packlistno  
        ,A.CUSTNO, CUSTNAME,SONO,PONO,INVDATE,shipdate,ORDERDATE      
        ,TERMS,INV_FOOT ,Line_no ,sortby ,Uniq_key ,PartNO ,Rev ,Descript ,CustPartNo ,CustRev ,CDescript       
        ,UOFMEAS ,SHIPPEDQTY ,NOTE ,PLPRICELNK ,pDesc ,QUANTITY ,CombinedPrice as PRICE , CombinedExtPrice as EXTENDED     
        ,TAXABLE ,FLAT ,A.RecordType ,TotalExt ,dsctamt ,TotalTaxExt ,FreightAmt ,FreightTaxAmt       
        ,PTax ,STax ,InvTotal ,Attn ,A.FOREIGNTAX ,A.SHIPTO ,ShipToAddress       
        ,A.pkfootnote ,BillTo ,BillToAddress,A.FOB ,A.SHIPVIA       
        ,A.BILLACOUNT ,WAYBILL ,IsRMA ,Soreps ,A.INFOOTNOTE ,print_invo ,SoBalance ,SerialNo ,uniqueln      
        ,TotalExtFC,dsctamtFC,TotalTaxExtFC,FREIGHTAMTFC,FreightTaxAmtFC,PTAXFC,STAXFC,INVTOTALFC       
        ,CombinedPriceFC as PRICEFC , CombinedExtPriceFC as EXTENDEDFC      
        ,TSymbol,FSymbol,PSymbol,PTaxId,STaxID       
        ,TotalExtPR,dsctamtPR,TotalTaxExtPR,FREIGHTAMTPR,FreightTaxAmtPR,PTAXPR,STAXPR,INVTOTALPR      
        ,CombinedPricePR as PRICEPR , CombinedExtPricePR as EXTENDEDPR      
        ,w.pkinpgnmuk,w.PAGEDESC,w.PAGENO      
        ,is_invpost --02/27/17 DRP:  Added      
	   -- 08/12/20 VL added invoice footnote from wmNotes
	   ,InvFootNote		
   from @tresultsFC A      
     cross apply  (SELECT D.PKINPGNMUK,T.PAGEDESC,T.PAGENO FROM  @tPageD D,@tPageDesc T  WHERE D.PKINPGNMUK = T.PKINPGNMUK) W       
   where A.nRec = 1      
     --where 1 = case when left(uniqueln,1) = '*' then 1 when RecordType = 'P' then 1 else 0 end --06/27/17 DRP:  replaced with the above A.nRec = 1      
     --RecordType = 'P' --08/30/16 DRP:  Replaced with the above      
   order by pageno,line_no       
      
      
   End      
  
  -- 04/18/2012 DRP: added the below code to just indicate if the invoice has been printed       
  UPDATE PLMAIN SET  is_InPrint = 1 WHERE PLMAIN.INVOICENO =@lcInvNo      
      
  -- 04/22/15 VL added to update PrevStat to save last batch      
  INSERT INTO PrevStat (FIELDTYPE, FIELDKEY) VALUES ('INVOICE', @lcInvNo)      
 END      
END      
      
	-- 01/10/18 VL added code to drop temp tables      
	IF OBJECT_ID('tempdb..#PLSerial') IS NOT NULL      
	 DROP TABLE #PLSerial       
	IF OBJECT_ID('tempdb..#startingPoints') IS NOT NULL      
	 DROP TABLE #startingPoints       
	IF OBJECT_ID('tempdb..#EndingPoints') IS NOT NULL      
	 DROP TABLE #EndingPoints       
	IF OBJECT_ID('tempdb..#StartEndSerialno') IS NOT NULL      
	 DROP TABLE #StartEndSerialno       
	IF OBJECT_ID('tempdb..#FinalSerialno') IS NOT NULL      
	 DROP TABLE #FinalSerialno      
      
END