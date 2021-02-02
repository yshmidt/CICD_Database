
-- =============================================
-- Author:			??
-- Create date:		??
-- Description:		Quickview for Open PO by Buyer View
-- Modification:
-- 12/11/20 VL now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
-- 12/22/20 VL found this quickview has parameter, but cube didn't have parameter set up to use, need to change @lcBuyer data typpe to use
-- =============================================
CREATE PROCEDURE [dbo].[QkViewOpenPObyBuyerView] @lcBuyer uniqueidentifier
 , @userId uniqueidentifier=null 
AS
BEGIN

SET NOCOUNT ON;

SELECT Ponum, Podate, Supname, Conum, 
	-- 12/11/20 VL now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
	--ISNULL(Buyerini.BuyName,SPACE(20)) AS BuyName
	ISNULL(aspnet_Users.UserName, SPACE(20)) AS BuyName
	, FinalName 
	FROM Supinfo, Pomain 
	-- 12/11/20 VL now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
	--LEFT OUTER JOIN BuyerIni 
	--ON Pomain.Buyer = BuyerIni.Ini 
	LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
	WHERE Pomain.UniqSupno = Supinfo.UniqSupno 
	AND (Postatus = 'OPEN' 
	OR Postatus = 'EDITING') 
	-- 12/22/20 VL changed to use AspnetBuyer
	--AND BUYER = @lcBuyer
	AND AspnetBuyer = @lcBuyer
      
END