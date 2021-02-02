-- =============================================
-- Author:		David Sharp
-- Create date: 12/19/2012
-- Description:	calculate days late for all orders in a date range
-- =============================================
CREATE PROCEDURE dbo.rptDaysLateDateRange 
	-- Add the parameters for the stored procedure here
	@startdate smalldatetime, 
	@endDate smalldatetime,
	@custno varchar(10) = '%',
	@sono varchar(10) = '%'	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	DECLARE @OnTime TABLE (sono varchar(10),soLine varchar(10),Uniqueln varchar(10),DueQty int,dueDate smalldatetime,shipDate smalldatetime,shipQty int DEFAULT 0,daysLate int,balQty int)
	DECLARE @UniqList TABLE (uniqln varchar(10))

	INSERT INTO @UniqList
	SELECT d.uniqueln FROM PLDETAIL d INNER JOIN PLMAIN pm ON d.PACKLISTNO=pm.PACKLISTNO
		INNER JOIN SOMAIN s ON pm.SONO=s.SONO
		WHERE pm.SHIPDATE BETWEEN @startDate AND @endDate
			AND s.CUSTNO LIKE @custno
			AND s.SONO LIKE @sono

	DECLARE @uniqln1 varchar(10),@toQty int, @dueDate smalldatetime,@bQty int, @so varchar(10),@ln varchar(10)
	DECLARE @uniqln2 varchar(10),@shipQty int, @shipDate smalldatetime

	DECLARE ot_cursor CURSOR LOCAL FAST_FORWARD
	FOR
	SELECT s.SONO,s.LINE_NO,d.UNIQUELN,d.ACT_SHP_QT,d.SHIP_DTS,d.ACT_SHP_QT
		FROM DUE_DTS d INNER JOIN SODETAIL s ON d.UNIQUELN = s.UNIQUELN
		WHERE d.UNIQUELN IN (SELECT UNIQLN FROM @UniqList)
		ORDER BY d.UNIQUELN,d.SHIP_DTS 
	OPEN ot_cursor;
	FETCH NEXT FROM ot_cursor INTO @so,@ln,@uniqln1,@toQty,@dueDate,@bQty

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE s_cursor CURSOR LOCAL FAST_FORWARD
		FOR
		SELECT Uniqueln,shippedqty,m.shipdate
			FROM PLDETAIL p INNER JOIN PLMAIN m ON p.PACKLISTNO=m.PACKLISTNO
			WHERE uniqueln = @uniqln1
			ORDER BY 3
		OPEN s_cursor ;
		FETCH NEXT FROM s_cursor INTO @uniqln2,@shipQty,@shipDate
 		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO @OnTime(sono,soLine,Uniqueln,DueQty,dueDate,shipDate,shipQty,daysLate,balQty)
			SELECT @so,@ln,@uniqln1,@toQty,@dueDate,@shipDate,CASE WHEN @bQty>@shipQty THEN @shipQty ELSE @bQty END,DATEDIFF(d,@dueDate,@shipDate),CASE WHEN @bQty>@shipQty THEN @bQty-@shipQty ELSE 0 END
			SET @bQty=@bQty-@shipQty
			IF @bQty < 0 
			BEGIN
				SET @shipQty = -@bQty 
				FETCH NEXT FROM ot_cursor INTO @so,@ln,@uniqln1,@toQty,@dueDate,@bQty
			END
			ELSE 
			IF @bQty =0
			BEGIN
				BREAK
			END
			ELSE
			BEGIN
				SET @shipQty = @bQty
				FETCH NEXT FROM s_cursor INTO @uniqln2,@shipQty,@shipDate
			END
		END
		CLOSE s_cursor
		DEALLOCATE s_cursor
		FETCH NEXT FROM ot_cursor INTO @so,@ln,@uniqln1,@toQty,@dueDate,@bQty
	END
	CLOSE ot_cursor
	DEALLOCATE ot_cursor

	SELECT * FROM @OnTime 
		WHERE shipDate BETWEEN @startdate AND @endDate
		ORDER BY Uniqueln,dueDate 

--SELECT SUM(shipQty*daysLate)/CASE WHEN SUM(shipQty) = 0 THEN 1 ELSE SUM(shipQty) END wAve, Uniqueln,sum(shipQty) FROM @OnTime GROUP BY Uniqueln order by Uniqueln
END