
-- =============================================
-- Author:		<Debbie>
-- Create date: <10/27/2010>
-- Description:	<Compiles the Sales Order Booking Detail information>
-- Reports Used On:  <sobkdt.rpt>
-- =============================================
CREATE PROCEDURE [dbo].[rptSoBookDetail]
	
AS
BEGIN
	select t1.custname, t1.sono, t1.orderdate, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,
CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,
CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance, 
t1.price, t1.flat, t1.ordAmt, t1.BackAmt, t1.is_rma

from(		
SELECT     TOP (100) PERCENT dbo.CUSTOMER.CUSTNAME, dbo.SOMAIN.SONO, dbo.SOMAIN.ORDERDATE, dbo.SOMAIN.PONO, dbo.SODETAIL.UNIQUELN, 
                      dbo.SODETAIL.LINE_NO, CASE WHEN dbo.inventor.part_no IS NULL THEN dbo.sodetail.Sodet_Desc ELSE CAST(dbo.INVENTOR.part_no AS CHAR(45)) 
                      END AS PART_NO, CASE WHEN dbo.INVENTOR.REVISION IS NULL THEN CAST(' ' AS CHAR(8)) ELSE dbo.INVENTOR.REVISION END AS REVISION, 
                      dbo.INVENTOR.PART_CLASS, dbo.INVENTOR.PART_TYPE, CASE WHEN dbo.inventor.part_no IS NULL THEN CAST('' AS char(45)) 
                      ELSE dbo.soprices.descriptio END AS DESCRIPTIO, dbo.SODETAIL.ORD_QTY, dbo.SODETAIL.BALANCE, dbo.SOPRICES.PRICE, dbo.SOPRICES.FLAT, 
                      CASE WHEN SOPRICES.FLAT = 1 THEN CAST(SOPRICES.PRICE AS numeric(12, 2)) ELSE CAST(SOPRICES.QUANTITY * SOPRICES.PRICE AS numeric(12,
                       2)) END AS OrdAmt, 
                      CASE WHEN RecordType = 'P' THEN CASE WHEN Flat = 1 THEN Price ELSE Balance * Price END ELSE CASE WHEN Flat = 1 THEN CASE WHEN Balance
                       <> Ord_Qty THEN 0 ELSE Price END ELSE (CASE WHEN Quantity - Shippedqty > 0 THEN (Quantity - Shippedqty) ELSE 0 END) 
                      * Price END END AS BackAmt, dbo.SOMAIN.IS_RMA
FROM         dbo.INVENTOR RIGHT OUTER JOIN
                      dbo.SODETAIL LEFT OUTER JOIN
                      dbo.SOPRICES ON dbo.SODETAIL.SONO = dbo.SOPRICES.SONO AND dbo.SODETAIL.UNIQUELN = dbo.SOPRICES.UNIQUELN ON 
                      dbo.INVENTOR.UNIQ_KEY = dbo.SODETAIL.UNIQ_KEY RIGHT OUTER JOIN
                      dbo.CUSTOMER INNER JOIN
                      dbo.SOMAIN ON dbo.CUSTOMER.CUSTNO = dbo.SOMAIN.CUSTNO ON dbo.SODETAIL.SONO = dbo.SOMAIN.SONO
                      
where		dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SOMAIN.ORD_TYPE <> 'Cancel'
                      
)t1
ORDER BY 1, 2, 3
END