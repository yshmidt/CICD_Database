-- =============================================
-- Author:Satish B
-- Create date: 08/23/2017
-- Description : Get Confirm To and Remmit To address
-- Modified : 11/07/2017 : Satish B : Change join of pomain from R_LINK to C_LINK
-- Modified : 11/07/2017 : Satish B : Change join of pomain from C_LINK to R_LINK
-- exec GetConfirmRemmitAddress 'T00000000001768'
-- =============================================
CREATE PROCEDURE GetConfirmRemmitAddress
	@poNumber char(15) =''
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 --Remmit To address
	 SELECT shipBill.SHIPTO As RConfirmTo 
	     ,shipBill.ADDRESS1 AS RAddress1
		 ,shipBill.ADDRESS2 AS RAddress2
		 ,shipBill.address3	AS RAddress3
		 ,shipBill.address4	AS RAddress4
		 ,shipBill.PHONE AS RPhone
		 ,shipBill.E_MAIL As REmail
		 ,shipBill.CITY AS RCity
		 ,shipBill.STATE AS RState
		 ,shipBill.ZIP AS RPostalCode
		 ,shipBill.COUNTRY AS RCountry
	 INTO #tempAddress
	 FROM SHIPBILL shipBill
	 --11/07/2017 : Satish B : Change join of pomain from R_LINK to C_LINK
		INNER JOIN POMAIN pomain ON pomain.C_LINK=shipBill.LINKADD
     WHERE pomain.PONUM=@poNumber

	 --Confirm To address
	  SELECT shipBill.SHIPTO As CConfirmTo 
	     ,shipBill.ADDRESS1 AS CAddress1
		 ,shipBill.ADDRESS2 AS CAddress2
		 ,shipBill.address3	AS CAddress3
		 ,shipBill.address4	AS CAddress4
		 ,shipBill.PHONE AS CPhone
		 ,shipBill.E_MAIL As CEmail
		 ,shipBill.CITY AS CCity
		 ,shipBill.STATE AS CState
		 ,shipBill.ZIP AS CPostalCode
		 ,shipBill.COUNTRY AS CCountry
		 , t.*
	 FROM SHIPBILL shipBill
	 --11/07/2017 : Satish B : Change join of pomain from C_LINK to R_LINK
		INNER JOIN POMAIN pomain ON pomain.R_LINK=shipBill.LINKADD
		,#tempAddress t
     WHERE pomain.PONUM=@poNumber
END

 
