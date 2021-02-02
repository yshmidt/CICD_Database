-- =============================================
-- Author:		Yelena Shmidt
-- Create date: May 25, 2020
--12/18/20 YS modified to find the correct schedule line for the rework work order created by RMA sales order
/* when rework work order is genenrated from RMA it is generated against the negative quantities line. And the schedule for this line is when the order is going to be shipped back
	If the user decides to ship the reworked order back the positive quantitiy line is added and the user will have scheduled the items to be shipped
	Both lines are connected through the ORIGINUQLN. Finding this second line (positive) and displaying the schedule for the positive line will solve the problem
*/
--01/19/21 YS added sd2.sono=sd1.sono, because ORIGINUQLN can be empty if we are workign with the stand alone rma
-- Description:	Get open schedule for the line item
-- =============================================
CREATE PROCEDURE [dbo].[getOustandingSOSchedule4uniqueln] 
	-- Add the parameters for the stored procedure here
	@uniqueln char(10) = NULL,
	@displayZeroBalance bit = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @uniqueln IS NOT NULL and @uniqueln<>''
	BEGIN
		SELECT sd.[status] lineStatus, d.ship_dts, d.due_dts,d.qty-d.ACT_SHP_QT as [Balance], d.qty,d.act_shp_qt,d.uniqueln 
			FROM due_dts d
			inner join sodetail sd on d.UNIQUELN=sd.UNIQUELN
			inner join somain so on sd.SONO=so.sono
			WHERE d.uniqueln = @uniqueln 
			and (sd.[STATUS] not in ('Cancel','Closed') )
			and ((@displayZeroBalance =0 and d.qty-d.ACT_SHP_QT>0) or @displayZeroBalance=1)
			and so.ORD_TYPE='Open' 
			---12/18/20 added a condition to skip RMA orders in the first part of the SQL and add UNION below for the RMA orders
			and so.IS_RMA=0
		--12/18/20 YS modified to find the correct schedule line for the rework work order created by RMA sales order
		/* when rework work order is genenrated from RMA it is generated against the negative quantities line. And the schedule for this line is when the order is going to be shipped back
			If the user decides to ship the reworked order back the positive quantitiy line is added and the user will have scheduled the items to be shipped
		Both lines are connected through the ORIGINUQLN. Finding this second line (positive) and displaying the schedule for the positive line will solve the problem
		*/
		--- added the UNION to have a different logic for the RMA orders
		UNION 	
		select RMA.[status] lineStatus, d.ship_dts, d.due_dts,d.qty-d.ACT_SHP_QT as [Balance], d.qty,d.act_shp_qt,d.uniqueln 
			FROM due_dts d
				CROSS APPLY (SELECT sd2.uniqueln,sd2.status from sodetail sd2
				--01/19/21 YS added sd2.sono=sd1.sono, because ORIGINUQLN can be empty if we are workign with the stand alone rma
							inner join sodetail sd1 on sd2.ORIGINUQLN=sd1.ORIGINUQLN and sd2.sono=sd1.sono
							inner join somain so on sd1.SONO=so.sono and so.IS_RMA=1
							WHERE sd1.uniqueln = @uniqueln  and sd2.UNIQUELN<>sd1.UNIQUELN
							and so.ORD_TYPE='Open'
							and sd2.[STATUS] not in ('Cancel','Closed')
							and d.UNIQUELN=sd2.UNIQUELN
							and ((@displayZeroBalance =0 and d.qty-d.ACT_SHP_QT>0) or @displayZeroBalance=1)
							) RMA 	;
	END
		 
END