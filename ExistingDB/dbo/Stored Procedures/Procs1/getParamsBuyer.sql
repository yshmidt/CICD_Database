-- =============================================
-- Author:		Vicky Lu
-- Create date: 12/19/2018
-- Description:	procedure to get list of Buer used for the report's parameters
-- Modificaion:	
-- 12/19/18 VL added if no record found in buyerini file but only exist in pomain, then just use the BUYER as buyname to show, also filter out if buyer=''
-- 12/22/20 VL Changed to get buyer from different field for cube version. 
 -- =============================================
CREATE PROCEDURE [dbo].[getParamsBuyer] 
	-- Add the parameters for the stored procedure here
	@paramFilter varchar(200) = NULL,		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier = null
	
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF (@top is not null)
		-- 12/22/20 VL now the buyer is not saved in Pomain.Buyer linked to Buyerini, it's saved in Pomain.AspnetBuyer linked to aspnet_Users
		SELECT DISTINCT top(@top) AspnetBuyer as Value, ISNULL(aspnet_Users.UserName, SPACE(20)) AS Text, 2 AS Seq
			FROM Pomain LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
			AND 1 = case when @paramFilter is null then 1 else case when 
			aspnet_Users.UserName like @paramFilter + '%' then 1 else 0 end end
			WHERE AspnetBuyer<>'00000000-0000-0000-0000-000000000000'
		-- 12/22/20 VL comment out 'All' for now
		--UNION ALL 
		--SELECT '00000000-0000-0000-0000-000000000000' AS Value, dbo.PADR('All',20,' ') AS Text, 1 AS Seq
		ORDER BY Seq, Value
	ELSE
		SELECT DISTINCT AspnetBuyer as Value, ISNULL(aspnet_Users.UserName, SPACE(20)) AS Text, 2 AS Seq 
			FROM Pomain LEFT OUTER JOIN aspnet_Users ON Pomain.AspnetBuyer = aspnet_Users.UserId
			AND 1 = case when @paramFilter is null then 1 else case when 
			aspnet_Users.UserName like @paramFilter + '%' then 1 else 0 end end
			WHERE AspnetBuyer<>'00000000-0000-0000-0000-000000000000'
		-- 12/22/20 VL comment out 'All' for now
		--UNION ALL 
		--SELECT '00000000-0000-0000-0000-000000000000' AS Value, dbo.PADR('All',20,' ') AS Text, 1 AS Seq
		ORDER BY Seq, Value
END