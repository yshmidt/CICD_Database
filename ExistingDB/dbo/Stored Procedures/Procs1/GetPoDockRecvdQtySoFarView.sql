-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <10/25/10>
-- Description:	<get received qty so far>
-- =============================================
CREATE PROCEDURE dbo.GetPoDockRecvdQtySoFarView
	-- Add the parameters for the stored procedure here
	@pcUniqLnNo char(10)=' ',
	@pcDock_uniq char(10)=' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Poitems.Recv_qty,Poitems.Acpt_qty,
		( SELECT SUM(Qty_rec) 
			FROM PODOCK 
			WHERE PODOCK.UNIQLNNO = Poitems.Uniqlnno 
			AND PoDock.Dock_Uniq <> @pcDock_uniq ) AS TotalRecQty
	FROM Poitems 
	WHERE Poitems.Uniqlnno =@pcUniqlnno
END