


-- =============================================
-- Author:		<Debbie> 
-- Create date: <02/27/2012>
-- Description:	<compiles details for the Sales Taxy Only Invoice form>
-- Reports:     <used on staxinvo.rpt>
-- Modified:	11/02/2012 DRP:  needed to change the SOREPS from varchar(50) to varchar(max)
--				10/30/15 DRP:  changed the Bill To and ship To address so that the address info was all in one field. 
--				03/03/2016 VL: Added FC code
--				04/08/2016 VL: Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/18/2017 VL: Added functional currency code
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptInvoiceSalesTax] 
--declare
	@lcInvNo char(10) = ''
	,@userId uniqueidentifier = NULL

as
BEGIN

-- 03/03/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	-- 07/16/18 VL changed custname from char(35) to char(50)
	declare @tresults table	(invoiceno char(10),packlistno char(10),CUSTNO char(10), CUSTNAME char(50),SONO char(10),PONO char(10),INVDATE smalldatetime,shipdate smalldatetime,ORDERDATE smalldatetime
							,TERMS char(15),INV_FOOT text,TotalTaxExt numeric(12,2),SHIPTO char(35),ShiptoAddress text,pkfootnote text,BillTo Char(35),BillToAddress text
							,FOB char(15),SHIPVIA char(15),BILLACOUNT char(20),WAYBILL char(20),IsRMA varchar(3),Soreps varchar(max),INFOOTNOTE text)
							--,ShipAdd1 char(35),ShipAdd2 char(35),ShipAdd3 char(35),ShipAdd4 char(35),BillAdd1 char(35),BillAdd2 char(35),BillAdd3 char(35),BillAdd4 char(35)--10/30/15 DRP:  Removed from the above

	SET @lcInvNo=dbo.PADL(@lcInvNo,10,'0')
	;
	with	
	Invoice as (	select	plmain.INVOICENO,plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,PLMAIN.SONO,SOMAIN.PONO,plmain.invdate,plmain.shipdate,SOMAIN.ORDERDATE
							,PLMAIN.TERMS,PLMAIN.INV_FOOT,plmain.tottaxe as TotalTaxExt
							--,s.SHIPTO,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
							--,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
							--,case when s.address2 <> '' then s.country else '' end as ShipAdd4,s.PKFOOTNOTE
							--,b.SHIPTO as BillTo,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
							--,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
							--,case when b.address2 <> '' then b.country else '' end as BillAdd4	--10/30/15 DRP:  replaced the address info into one field format below. 
							,s.SHIPTO
							,rtrim(S.Address1)+case when S.address2<> '' then char(13)+char(10)+rtrim(S.address2) else '' end+
								CASE WHEN S.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(S.City)+',  '+rtrim(S.State)+'      '+RTRIM(S.zip)  ELSE '' END +
								CASE WHEN S.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(S.Country) ELSE '' end+
								case when S.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(S.PHONE) else '' end+
								case when S.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(S.FAX) else '' end  as ShipToAddress,s.PKFOOTNOTE
							,b.SHIPTO as BillTo
							,rtrim(B.Address1)+case when B.address2<> '' then char(13)+char(10)+rtrim(B.address2) else '' end+
								CASE WHEN B.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(B.City)+',  '+rtrim(B.State)+'      '+RTRIM(B.zip)  ELSE '' END +
								CASE WHEN B.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(B.Country) ELSE '' end+
								case when B.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(B.PHONE) else '' end+
								case when B.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(B.FAX) else '' end  as BillToAddress
							,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA,dbo.FnSoRep(plmain.sono) as Soreps ,B.INFOOTNOTE		
					from	PLMAIN
							inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
							LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO
							left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
							left outer join CCONTACT on plmain.attention = ccontact.cid
							inner join SHIPBILL as S on plmain.LINKADD = s.LINKADD
							left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD and plmain.CUSTNO = b.CUSTNO				
							left outer join SOPRSREP on PLDETAIL.UNIQUELN = soprsrep.UNIQUELN
					where	plmain.INVOICENO =@lcInvNo
							and PRINTED = 1
							and IS_REL_GL = 0
	
			) 

	INSERT @tResults
	select * from Invoice

	Select * from @tResults
	END
ELSE
-- FC installed
	BEGIN
	-- 07/16/18 VL changed custname from char(35) to char(50)
	declare @tresultsFC table	(invoiceno char(10),packlistno char(10),CUSTNO char(10), CUSTNAME char(50),SONO char(10),PONO char(10),INVDATE smalldatetime,shipdate smalldatetime,ORDERDATE smalldatetime
							,TERMS char(15),INV_FOOT text,TotalTaxExt numeric(12,2),SHIPTO char(35),ShiptoAddress text,pkfootnote text,BillTo Char(35),BillToAddress text
							,FOB char(15),SHIPVIA char(15),BILLACOUNT char(20),WAYBILL char(20),IsRMA varchar(3),Soreps varchar(max),INFOOTNOTE text
							,TotalTaxExtFC numeric(12,2),TotalTaxExtPR numeric(12,2), TSymbol char(3), PSymbol char(3), FSymbol char(3))
							--,ShipAdd1 char(35),ShipAdd2 char(35),ShipAdd3 char(35),ShipAdd4 char(35),BillAdd1 char(35),BillAdd2 char(35),BillAdd3 char(35),BillAdd4 char(35)--10/30/15 DRP:  Removed from the above

	SET @lcInvNo=dbo.PADL(@lcInvNo,10,'0')
	;
	with	
	Invoice as (	select	plmain.INVOICENO,plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,PLMAIN.SONO,SOMAIN.PONO,plmain.invdate,plmain.shipdate,SOMAIN.ORDERDATE
							,PLMAIN.TERMS,PLMAIN.INV_FOOT,plmain.tottaxe as TotalTaxExt
							--,s.SHIPTO,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
							--,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
							--,case when s.address2 <> '' then s.country else '' end as ShipAdd4,s.PKFOOTNOTE
							--,b.SHIPTO as BillTo,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
							--,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
							--,case when b.address2 <> '' then b.country else '' end as BillAdd4	--10/30/15 DRP:  replaced the address info into one field format below. 
							,s.SHIPTO
							,rtrim(S.Address1)+case when S.address2<> '' then char(13)+char(10)+rtrim(S.address2) else '' end+
								CASE WHEN S.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(S.City)+',  '+rtrim(S.State)+'      '+RTRIM(S.zip)  ELSE '' END +
								CASE WHEN S.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(S.Country) ELSE '' end+
								case when S.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(S.PHONE) else '' end+
								case when S.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(S.FAX) else '' end  as ShipToAddress,s.PKFOOTNOTE
							,b.SHIPTO as BillTo
							,rtrim(B.Address1)+case when B.address2<> '' then char(13)+char(10)+rtrim(B.address2) else '' end+
								CASE WHEN B.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(B.City)+',  '+rtrim(B.State)+'      '+RTRIM(B.zip)  ELSE '' END +
								CASE WHEN B.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(B.Country) ELSE '' end+
								case when B.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(B.PHONE) else '' end+
								case when B.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(B.FAX) else '' end  as BillToAddress
							,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA,dbo.FnSoRep(plmain.sono) as Soreps ,B.INFOOTNOTE		
							,plmain.tottaxeFC as TotalTaxExtFC
							-- 01/18/17 VL added functional currency code
							,plmain.tottaxePR as TotalTaxExtPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
					from	PLMAIN
							-- 01/18/17 VL changed criteria to get 3 currencies
							INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
							INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
							INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq
							inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
							LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO
							left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
							left outer join CCONTACT on plmain.attention = ccontact.cid
							inner join SHIPBILL as S on plmain.LINKADD = s.LINKADD
							left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD and plmain.CUSTNO = b.CUSTNO				
							left outer join SOPRSREP on PLDETAIL.UNIQUELN = soprsrep.UNIQUELN
					where	plmain.INVOICENO =@lcInvNo
							and PRINTED = 1
							and IS_REL_GL = 0
	
			) 

	INSERT @tResultsFC
	select * from Invoice

	Select * from @tResultsFC
	END
END -- END of If FC installed

end