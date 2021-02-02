-- =============================================
-- Author:		<?>
-- Create date: <?>
-- Description:	<Qkview for Open PO Late Parts>
-- Modification:
-- 07/13/18 VL changed supname from char(30) to char(50)
-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
-- =============================================
CREATE PROCEDURE [dbo].[QkViewOpenPOLatePartsView]
@userid uniqueidentifier = null
AS
BEGIN

SET NOCOUNT ON;

-- 07/13/18 VL changed supname from char(30) to char(50)
SELECT Req_Date, LEFT(Supname,50) AS Supname, Poitems.Ponum, 
		CASE WHEN Poitems.UNIQ_KEY = '' THEN 
			CASE WHEN Poitems.PART_NO = '' THEN LEFT(Poitems.DESCRIPT,25) ELSE Poitems.Part_No END
			ELSE Inventor.PART_NO END AS Part_no, 
		CASE WHEN Poitems.UNIQ_KEY = '' THEN Poitems.Revision ELSE Inventor.Revision END AS Revision, 	
		DATEDIFF(day, Schd_Date, GETDATE()) AS Late,
		-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
		--ISNULL(Buyerini.Buyname, SPACE(20)) AS BuyName
		ISNULL(aspnet_Users.UserName, SPACE(20)) AS BuyName
		, Poitems.Ord_qty, 
		Poitems.Ord_qty - Poitems.Acpt_qty AS Balance, Schd_Date ,Poitschd.Balance AS LateQty
	FROM Poitschd, Supinfo, Poitems LEFT OUTER JOIN Inventor ON Poitems.UNIQ_KEY = INVENTOR.Uniq_key, 
		-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
		--Pomain LEFT OUTER JOIN BuyerIni 
		--ON Pomain.Buyer = BuyerIni.Ini 
		Pomain LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
	WHERE Schd_date < GETDATE() 
	AND Poitschd.Uniqlnno = Poitems.Uniqlnno 
	AND Poitems.Ponum = Pomain.Ponum 
	AND Pomain.UniqSupno = Supinfo.UniqSupno 
	AND (Pomain.Postatus = 'OPEN'
	OR Postatus = 'EDITING') 
	AND Poitschd.Balance > 0 
	AND Poitems.lCancel = 0
	ORDER BY 1,3,2

END	