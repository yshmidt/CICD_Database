-- =============================================
-- Author:		Debbie
-- Create date: 09/08/2011
-- Description:	This Stored Procedure was created for the "Customer Reference Report"
-- Reports Using Stored Procedure:  icrpt15.rpt
-- Modified:	09/25/2012 DRP:  added the micssys.lic_name within the Stored Procedure and removed it from the Crystal Report
--				10/07/2014 DRP:  added inv_note from the Parent part per request from a customer.  
--								 also added the customer List to make sure that only approved customer for the user are displayed. 
--				01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtCustRef] 
--declare
 @customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
,@userid uniqueidentifier = null	
AS
BEGIN


/*10/07/2014 DRP:  added the customer list to make sure that the customers that are display are approved for the user*/
/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
/*10/07/2014 DRP:  Add End*/


SELECT	IPARENT.UNIQ_KEY as Parent_uniqkey, IPARENT.PART_NO, IPARENT.REVISION, iparent.PART_CLASS, iparent.PART_TYPE,iparent.PART_SOURC as Parent_sourc,IPARENT.DESCRIPT,IPARENT.STATUS AS PARENT_STATUS
		,ichild.uniq_key as Child_uniqkey,ICHILD.CUSTPARTNO, ICHILD.CUSTREV, ICHILD.PART_SOURC,ICHILD.INT_UNIQ, CUSTNAME, ICHILD.CUSTNO, ICHILD.STATUS AS CHILD_STATUS,iparent.inv_note,MICSSYS.LIC_NAME

FROM	INVENTOR AS IPARENT
		inner JOIN INVENTOR AS ICHILD ON IPARENT.UNIQ_KEY = ICHILD.INT_UNIQ
		INNER JOIN CUSTOMER ON ICHILD.CUSTNO = CUSTOMER.CUSTNO
		cross join MICSSYS
where	1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end

END