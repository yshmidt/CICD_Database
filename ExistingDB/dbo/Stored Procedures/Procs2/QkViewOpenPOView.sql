
-- =============================================
-- Modified:	05/29/2015 DRP:  added the /*SUPPLIER LIST*/ to the procedure. 
-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
-- =============================================
CREATE PROCEDURE [dbo].[QkViewOpenPOView]


--declare
@userid uniqueidentifier = null


AS
BEGIN

/*SUPPLIER LIST*/	--05/29/2015 DRP:   Added
-- 12/03/13 YS get list of approved suppliers for this user
DECLARE  @tSupplier tSupplier
-- get list of Suppliers for @userid with access
INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All' ;




SET NOCOUNT ON;

SELECT Ponum, Podate, Supname, Conum, 
	-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
	--ISNULL(Buyerini.BuyName,SPACE(20)) AS BuyName
	ISNULL(aspnet_Users.UserName, SPACE(20)) AS BuyName
	, FinalName 
	FROM Supinfo, 
	-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
	--Pomain LEFT OUTER JOIN BuyerIni 
	--ON Pomain.Buyer = BuyerIni.Ini 
	Pomain LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
	WHERE Pomain.UniqSupno = Supinfo.UniqSupno 
	AND (Postatus = 'OPEN' 
	OR Postatus = 'EDITING') 
	and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupplier) THEN 1 ELSE 0  END		--05/29/2015 DRP:  Added
   
END