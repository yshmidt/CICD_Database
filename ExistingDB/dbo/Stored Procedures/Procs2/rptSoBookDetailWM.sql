
-- =============================================
-- Author:		<Debbie>
-- Create date: <10/27/2010>
-- Description:	<Compiles the Sales Order Booking Detail information>
-- Reports Used On:  <sobkdt.rpt>
-- Modified:	01/29/2015 DRP:  Created the WM version otherwise I would mess up the CR version on the desktop.  When originally created for CR version I was incorrectly only using the parameter within the report designer.  I should have been placing the parameter within this procedure for the Date Range. 
--				04/01/2015 DRP:  needed to increase the Part_no char(30) to be Char(45) in the declared @t table due to the fact that I am pulling in sodetail.sodet_desc if the uniq_key is blank. 
--				04/22/2015 DRP:  The Date Range filter was not being applied within the procedure. 
--				10/01/15 DRP:  Requested that we actually show the true Order date instead of just the Month/Year (aka October 2015).  also needed to change orderdate char(15) to be orderdate smalldatetime
--				02/15/2016 VL:	 Added FC code
--				04/08/2016 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptSoBookDetailWM]
--declare
	@lcSort char(20) = 'Product'		--Product or Month
	,@lcDateStart smalldatetime = null
	,@lcDateEnd smalldatetime = null
	,@lcCustNo  varchar(max) = 'All'
	,@userId uniqueidentifier = null
	
AS
BEGIN

/*CUSTOMER LIST*/
	DECLARE  @tCustomer as tCustomer
			DECLARE @Customer TABLE (custno char(10))
		-- get list of Customers for @userid with access
		INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		IF @lcCustno is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select Custno from @tCustomer)
		ELSE

		IF  @lccustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT Custno FROM @tCustomer
		END	


/*SELECT STATEMENT SECTION*/

-- 02/15/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN

	-- 07/16/18 VL changed custname from char(35) to char(50)
	declare @t1 as table (custname char(50),sono char(10),orderdate smalldatetime,pono char(20),uniqueln char(10),line_no char (10),part_no char(45),revision char(8),part_class char(8),part_type char(8)
						,descriptio char (50), Ord_qty Numeric(20,2),balance Numeric(20,2),price numeric(14,5),flat bit,ordAmt numeric(12,2),BackAmt numeric(12,2),is_rma bit)

	insert into @t1
			select	t1.custname, t1.sono,t1.ORDERDATE	--,t1.sono,datename(yyyy,t1.orderdate)+' '+ datename(mm,t1.orderdate) as orderdate	--10/01/15 DRP:  was replaced by just the order date. 
					, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class
					,t1.part_type, t1.descriptio,CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty
					,CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,t1.price, t1.flat, t1.ordAmt, t1.BackAmt, t1.is_rma

	from(		
	SELECT     TOP (100) PERCENT dbo.CUSTOMER.CUSTNAME, dbo.SOMAIN.SONO, dbo.SOMAIN.ORDERDATE, dbo.SOMAIN.PONO, dbo.SODETAIL.UNIQUELN, 
						  dbo.SODETAIL.LINE_NO, CASE WHEN dbo.inventor.part_no IS NULL THEN dbo.sodetail.Sodet_Desc ELSE CAST(dbo.INVENTOR.part_no AS CHAR(45)) 
						  END AS PART_NO, CASE WHEN dbo.INVENTOR.REVISION IS NULL THEN CAST(' ' AS CHAR(8)) ELSE dbo.INVENTOR.REVISION END AS REVISION, 
						  dbo.INVENTOR.PART_CLASS, dbo.INVENTOR.PART_TYPE, CASE WHEN dbo.inventor.part_no IS NULL THEN CAST('' AS char(45)) 
						  ELSE isnull(dbo.soprices.descriptio,'') END AS DESCRIPTIO, dbo.SODETAIL.ORD_QTY, dbo.SODETAIL.BALANCE, isnull(dbo.SOPRICES.PRICE,0.00) as price, isnull(dbo.SOPRICES.FLAT,0) as flat, 
						  CASE WHEN SOPRICES.FLAT = 1 THEN isnull(CAST(SOPRICES.PRICE AS numeric(12, 2)),0.00) ELSE isnull(CAST(SOPRICES.QUANTITY * SOPRICES.PRICE AS numeric(12,2)),0.00) END AS OrdAmt, 
						  isnull(CASE WHEN RecordType = 'P' THEN CASE WHEN Flat = 1 THEN Price ELSE Balance * Price END ELSE CASE WHEN Flat = 1 THEN CASE WHEN Balance
						   <> Ord_Qty THEN 0 ELSE Price END ELSE (CASE WHEN Quantity - Shippedqty > 0 THEN (Quantity - Shippedqty) ELSE 0 END) 
						  * Price END END,0.00) AS BackAmt
						  , dbo.SOMAIN.IS_RMA
	FROM         dbo.INVENTOR RIGHT OUTER JOIN
						  dbo.SODETAIL LEFT OUTER JOIN
						  dbo.SOPRICES ON dbo.SODETAIL.SONO = dbo.SOPRICES.SONO AND dbo.SODETAIL.UNIQUELN = dbo.SOPRICES.UNIQUELN ON 
						  dbo.INVENTOR.UNIQ_KEY = dbo.SODETAIL.UNIQ_KEY RIGHT OUTER JOIN
						  dbo.CUSTOMER INNER JOIN
						  dbo.SOMAIN ON dbo.CUSTOMER.CUSTNO = dbo.SOMAIN.CUSTNO ON dbo.SODETAIL.SONO = dbo.SOMAIN.SONO
                      
	where		dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SOMAIN.ORD_TYPE <> 'Cancel'
				and 1 = case when somain.CUSTNO in (select CUSTNO from @customer) then 1 else 0 end   
				and datediff(day,ORDERDATE,@lcDateStart)<=0 and datediff(day,ORDERDATE,@lcDateEnd)>=0		--04/22/2015 DRP:  Added this filter.

			
		)t1

     
	if (@lcSort = 'Product')
		Begin
			select * from @t1 order by custname,part_no,revision,orderdate,sono,line_no
		End

	else if (@lcSort = 'Month')
		Begin
			select * from @t1 order by custname,orderdate,part_no,revision,sono,line_no
		End
	END
ELSE
-- FC Installed
	BEGIN
	-- 07/16/18 VL changed custname from char(35) to char(50)
	declare @t2 as table (custname char(50),sono char(10),orderdate smalldatetime,pono char(20),uniqueln char(10),line_no char (10),part_no char(45),revision char(8),part_class char(8),part_type char(8)
					,descriptio char (50), Ord_qty Numeric(20,2),balance Numeric(20,2),price numeric(14,5),flat bit,ordAmt numeric(12,2),BackAmt numeric(12,2),is_rma bit
					,priceFC numeric(14,5),ordAmtFC numeric(12,2),BackAmtFC numeric(12,2), Fcused_uniq char(10), Currency char(3))

	insert into @t2
			select	t2.custname, t2.sono,t2.ORDERDATE	--,t2.sono,datename(yyyy,t2.orderdate)+' '+ datename(mm,t2.orderdate) as orderdate	--10/01/15 DRP:  was replaced by just the order date. 
					, t2.pono, t2.uniqueln, t2.line_no, t2.part_no, t2.revision, t2.part_class
					,t2.part_type, t2.descriptio,CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty
					,CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,t2.price, t2.flat, t2.ordAmt, t2.BackAmt, t2.is_rma
					,t2.priceFC,t2.ordAmtFC, t2.BackAmtFC, Fcused_uniq, Currency

	from(		
	SELECT     TOP (100) PERCENT dbo.CUSTOMER.CUSTNAME, dbo.SOMAIN.SONO, dbo.SOMAIN.ORDERDATE, dbo.SOMAIN.PONO, dbo.SODETAIL.UNIQUELN, 
						  dbo.SODETAIL.LINE_NO, CASE WHEN dbo.inventor.part_no IS NULL THEN dbo.sodetail.Sodet_Desc ELSE CAST(dbo.INVENTOR.part_no AS CHAR(45)) 
						  END AS PART_NO, CASE WHEN dbo.INVENTOR.REVISION IS NULL THEN CAST(' ' AS CHAR(8)) ELSE dbo.INVENTOR.REVISION END AS REVISION, 
						  dbo.INVENTOR.PART_CLASS, dbo.INVENTOR.PART_TYPE, CASE WHEN dbo.inventor.part_no IS NULL THEN CAST('' AS char(45)) 
						  ELSE isnull(dbo.soprices.descriptio,'') END AS DESCRIPTIO, dbo.SODETAIL.ORD_QTY, dbo.SODETAIL.BALANCE, isnull(dbo.SOPRICES.PRICE,0.00) as price, isnull(dbo.SOPRICES.FLAT,0) as flat, 
						  CASE WHEN SOPRICES.FLAT = 1 THEN isnull(CAST(SOPRICES.PRICE AS numeric(12, 2)),0.00) ELSE isnull(CAST(SOPRICES.QUANTITY * SOPRICES.PRICE AS numeric(12,2)),0.00) END AS OrdAmt, 
						  isnull(CASE WHEN RecordType = 'P' THEN CASE WHEN Flat = 1 THEN Price ELSE Balance * Price END ELSE CASE WHEN Flat = 1 THEN CASE WHEN Balance
						   <> Ord_Qty THEN 0 ELSE Price END ELSE (CASE WHEN Quantity - Shippedqty > 0 THEN (Quantity - Shippedqty) ELSE 0 END) 
						  * Price END END,0.00) AS BackAmt
						  , dbo.SOMAIN.IS_RMA
						  , isnull(dbo.SOPRICES.PRICEFC,0.00) as priceFC
						  ,CASE WHEN SOPRICES.FLAT = 1 THEN isnull(CAST(SOPRICES.PRICEFC AS numeric(12, 2)),0.00) ELSE isnull(CAST(SOPRICES.QUANTITY * SOPRICES.PRICEFC AS numeric(12,2)),0.00) END AS OrdAmtFC, 
						  isnull(CASE WHEN RecordType = 'P' THEN CASE WHEN Flat = 1 THEN PriceFC ELSE Balance * PriceFC END ELSE CASE WHEN Flat = 1 THEN CASE WHEN Balance
						   <> Ord_Qty THEN 0 ELSE PriceFC END ELSE (CASE WHEN Quantity - Shippedqty > 0 THEN (Quantity - Shippedqty) ELSE 0 END) 
						  * PriceFC END END,0.00) AS BackAmtFC, dbo.Somain.Fcused_uniq AS Fcused_uniq, Fcused.Symbol AS Currency
						  FROM         dbo.INVENTOR RIGHT OUTER JOIN
						  dbo.SODETAIL LEFT OUTER JOIN
						  dbo.SOPRICES ON dbo.SODETAIL.SONO = dbo.SOPRICES.SONO AND dbo.SODETAIL.UNIQUELN = dbo.SOPRICES.UNIQUELN ON 
						  dbo.INVENTOR.UNIQ_KEY = dbo.SODETAIL.UNIQ_KEY RIGHT OUTER JOIN
						  dbo.CUSTOMER INNER JOIN
						  dbo.SOMAIN ON dbo.CUSTOMER.CUSTNO = dbo.SOMAIN.CUSTNO ON dbo.SODETAIL.SONO = dbo.SOMAIN.SONO INNER JOIN
						  dbo.Fcused ON dbo.Somain.FCUSED_UNIQ = dbo.FcUsed.FcUsed_Uniq
                      
	where		dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SOMAIN.ORD_TYPE <> 'Cancel'
				and 1 = case when somain.CUSTNO in (select CUSTNO from @customer) then 1 else 0 end   
				and datediff(day,ORDERDATE,@lcDateStart)<=0 and datediff(day,ORDERDATE,@lcDateEnd)>=0		--04/22/2015 DRP:  Added this filter.

			
		)t2

     
	if (@lcSort = 'Product')
		Begin
			select * from @t2 order by Currency,custname,part_no,revision,orderdate,sono,line_no
		End

	else if (@lcSort = 'Month')
		Begin
			select * from @t2 order by Currency,custname,orderdate,part_no,revision,sono,line_no
		End
	END--End of FC installed
END -- Enf of if FC Installed
END