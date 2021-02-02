CREATE PROCEDURE dbo.GetWhTotalsByUniq_Key
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Uniq_Key, SUM(Qty_oh) AS TotOh
	FROM Invtmfgr, Warehous
	WHERE Invtmfgr.UniqWh = Warehous.UniqWh 
	AND Warehouse <> 'WIP' 
	AND Netable = 1
	AND Instore = 0
	AND Invtmfgr.Is_deleted = 0
	GROUP BY Uniq_Key 
	ORDER BY Uniq_Key

END