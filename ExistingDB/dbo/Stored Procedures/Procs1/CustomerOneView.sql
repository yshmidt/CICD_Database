
-- 06/19/20 VL now the default bill to and ship too are saved in different tables
-- 06/29/20 VL added ISNULL() for B.LinkAdd in case user didn't set up default bill to address

CREATE PROC [dbo].[CustomerOneView] @lcCustno AS char(10) = ''
AS
-- 06/19/20 VL now the default bill to and ship too are saved in different tables
 --SELECT *, ISNULL(City,SPACE(20)) AS City
 --	FROM Customer LEFT OUTER JOIN Shipbill 
	--ON Customer.Slinkadd = Shipbill.Linkadd
	--WHERE Customer.Custno = @lcCustno

 SELECT Customer.Custno, Custname, Customer.Phone, Customer.Fax, TERRITORY, Terms, CREDLIMIT, Profile, custnote, Acctstatus, DIVISION, SREPS, CREDITOK, RESL_NO, AR_CALDATE,
	AR_CALTIME, AR_CALBY, AR_CALNOTE, AR_HIGHBAL, CREDITNOTE, ACCT_DATE, SAVEINIT, OUT_MARGIN, TL_MARGIN, MAT_MARGIN, LAB_MARGIN, MIN_ORDAMT, SCRAP_FACT, COMMITEM, CUSTSPEC,
	LABOR, MATERIAL, SPLIT1, SPLIT2, SPLITAMT, SPLITPERC, TOOLING, SIC_CODE, SIC_DESC, DELIVTIME, STATUS, SERIFLAG, OVERHEAD, IS_EDITED, SALEDSCTID, CUSTPFX, ACTTAXABLE,
	INACTDT, INACTINIT, Customer.modifiedDate, Customer.Fcused_Uniq, Customer.IsSynchronizedFlag, Customer.isQBSync, internal, CustCode, LastStmtSent, LastStmtSentUserId, WebSite,
	-- 06/29/20 VL added ISNULL() for B.LinkAdd in case user didn't set up default bill to address
	ISNULL(B.Linkadd, SPACE(10)) as Blinkadd, CASE WHEN ISNULL(slinkAdd.ShipConfirmToAddress,'') = '' THEN ''  ELSE slinkAdd.ShipConfirmToAddress END AS SlinkAdd,
	-- 06/29/20 VL added ISNULL() for all the fields in Slinkadd in case user didn't select default address
	--slinkAdd.*, 
	ISNULL(slinkAdd.LINKADD, SPACE(10)) AS Linkadd, ISNULL(slinkAdd.Shipto, SPACE(50)) AS Shipto, ISNULL(slinkAdd.Address1, SPACE(50)) AS Address1,
	ISNULL(slinkAdd.ADDRESS2, SPACE(50)) AS Address2, ISNULL(slinkAdd.State, SPACE(50)) AS State, ISNULL(slinkAdd.Zip, SPACE(20)) AS Zip, ISNULL(slinkAdd.Country, SPACE(50)) AS Country,
	ISNULL(slinkAdd.Phone, SPACE(20)) AS Phone, ISNULL(slinkAdd.Fax, SPACE(19)) AS Fax, ISNULL(slinkAdd.E_MAIL, SPACE(200)) AS E_mail, ISNULL(slinkAdd.TRANSDAY, 0) AS TransDay,
	ISNULL(slinkAdd.FOB, SPACE(15)) AS FOB, ISNULL(slinkAdd.SHIPCHARGE, SPACE(15)) AS ShipCharge, ISNULL(slinkAdd.ShipVia, SPACE(15)) AS Shipvia,
	ISNULL(slinkAdd.ATTENTION, SPACE(30)) AS Attention, ISNULL(slinkAdd.BILLACOUNT, SPACE(20)) AS BillAcount, ISNULL(slinkAdd.SHIPTIME, SPACE(8)) AS ShipTime,
	ISNULL(slinkAdd.address3, SPACE(50)) AS Address3, ISNULL(slinkAdd.address4, SPACE(50)) AS Address4, ISNULl(slinkAdd.Fcused_Uniq, SPACE(10)) AS Fcused_Uniq,
	ISNULL(slinkAdd.useDefaultTax,0) AS useDefaultTax,

	ISNULL(slinkAdd.City,SPACE(20)) AS City
 	FROM Customer LEFT OUTER JOIN Shipbill B ON Customer.Custno = B.Custno AND B.RECORDTYPE = 'B' AND IsDefaultAddress = 1
	OUTER APPLY 
		     (
		   		  SELECT a.ShipConfirmToAddress, SH.* from shipbill s JOIN  AddressLinkTable a ON s.LINKADD=a.BillRemitAddess
				  LEFT OUTER JOIN Shipbill SH ON a.ShipConfirmToAddress = SH.LINKADD
		   		  WHERE s.RECORDTYPE='B' AND s.IsDefaultAddress=1 AND a.IsDefaultAddress=1 AND s.CUSTNO= Customer.CustNo
		   	 ) AS slinkAdd
	WHERE Customer.Custno = @lcCustno
