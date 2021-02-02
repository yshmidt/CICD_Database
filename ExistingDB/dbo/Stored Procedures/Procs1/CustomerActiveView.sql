
-- 04/08/13 VL added Status field
-- 06/19/20 VL now the default bill to and ship too are saved in different tables
-- 06/29/20 VL added ISNULL() for B.LinkAdd in case user didn't set up default bill to address

CREATE PROC [dbo].[CustomerActiveView] AS 
-- 06/19/20 VL changed to get blinkadd and slinkadd from different tables for cube version
--SELECT CustName, Customer.Custno, Blinkadd, Slinkadd, ISNULL(City,SPACE(20)) AS City, Terms, Status
--	FROM Customer LEFT OUTER JOIN Shipbill 
--	ON Customer.Slinkadd = Shipbill.Linkadd
--	WHERE Status<>'Inactive'
--	AND Customer.Custno<>'000000000~'
--	ORDER BY 1

-- 06/29/20 VL added ISNULL() for B.LinkAdd in case user didn't set up default bill to address
SELECT CustName, Customer.Custno, ISNULL(B.Linkadd, SPACE(10)) as Blinkadd, CASE WHEN ISNULL(slinkAdd.ShipConfirmToAddress,'') = '' THEN ''  ELSE slinkAdd.ShipConfirmToAddress END AS SlinkAdd, 
	ISNULL(slinkAdd.City,SPACE(20)) AS City, Terms, Status
	FROM Customer LEFT OUTER JOIN Shipbill B ON Customer.Custno = B.Custno AND B.RECORDTYPE = 'B' AND IsDefaultAddress = 1
	OUTER APPLY 
		     (
		   		  SELECT a.ShipConfirmToAddress, SH.* from shipbill s JOIN  AddressLinkTable a ON s.LINKADD=a.BillRemitAddess
				  LEFT OUTER JOIN Shipbill SH ON a.ShipConfirmToAddress = SH.LINKADD
		   		  WHERE s.RECORDTYPE='B' AND s.IsDefaultAddress=1 AND a.IsDefaultAddress=1 AND s.CUSTNO= Customer.CustNo
		   	 ) AS slinkAdd
	WHERE Status<>'Inactive'
	AND Customer.Custno<>'000000000~'
	ORDER BY 1
