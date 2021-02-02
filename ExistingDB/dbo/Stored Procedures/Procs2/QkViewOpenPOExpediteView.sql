
-- =============================================
-- Author:			??
-- Create date:		??
-- Description:		Quickview for Open PO expedited View
-- Modification:
-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
-- =============================================
CREATE PROCEDURE [dbo].[QkViewOpenPOExpediteView] @ltReq_Date as smalldatetime 
AS
BEGIN

SET NOCOUNT ON;


SELECT Req_Date, Supname, Poitems.Ponum, 
		CASE WHEN Poitems.UNIQ_KEY = '' THEN 
			CASE WHEN Poitems.PART_NO = '' THEN LEFT(Poitems.DESCRIPT,25) ELSE Poitems.Part_No END
			ELSE Inventor.PART_NO END AS Part_no, 
			CASE WHEN Poitems.UNIQ_KEY = '' THEN Poitems.Revision ELSE Inventor.Revision END AS Revision, 
		-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
		--ISNULL(Buyerini.Buyname, SPACE(20)) AS BuyName
		ISNULL(aspnet_Users.UserName, SPACE(20)) AS BuyName
		, Poitems.Ord_qty, Poitems.Ord_qty - Poitems.Acpt_qty AS Balance
	FROM Poitschd, Supinfo, Poitems LEFT OUTER JOIN Inventor ON Poitems.UNIQ_KEY = INVENTOR.Uniq_key, 
		-- 12/11/20 now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
		--Pomain LEFT OUTER JOIN BuyerIni 
		--ON Pomain.Buyer = BuyerIni.Ini 
		POMAIN LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
	WHERE Req_date <= @ltReq_Date
	AND Poitschd.Uniqlnno = Poitems.Uniqlnno 
	AND Poitems.Ponum = Pomain.Ponum 
	AND Pomain.UniqSupno = Supinfo.UniqSupno 
	AND (Pomain.Postatus = 'OPEN'
	OR Postatus = 'EDITING') 
	AND Poitschd.Balance > 0 
	AND Poitems.lCancel = 0
	ORDER BY 1,3,2

END	