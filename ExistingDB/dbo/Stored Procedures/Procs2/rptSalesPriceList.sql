-- =============================================
-- Author:		   Debbie
-- Create date:	   12/08/2014
-- Description:	   Created for the Sale Price Information report 
-- Reports:		   partlist, removed 'prtlst_c' because I accomplished the different types of report in one. 
-- Modifications:  01/06/2015 DRP:  Added @customerStatus Filter
--- 08/09/17 YS added currency symbol when FC is on
--- 08/09/17 YS if @lcUniq_key = 'All' no need to gather all uniq_key form inventor
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- 12/05/19 VL Changed to use new price tables for cube
-- =============================================
CREATE PROCEDURE [dbo].[rptSalesPriceList]

--DECLARE	
		@lcUniq_key VARCHAR(MAX) = 'All'
		,@lcRptType as char(30) = 'by Part Number'	--by Part Number or by Customer
		,@lcCustNo as varchar(max) = 'All'
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		, @userId uniqueidentifier= null
		
as
begin
---08/09/17 YS check for fc installed
	declare @FC_ON bit
	select @FC_ON=dbo.fn_IsFCInstalled()

			
/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END


/*PRODUCT LIST*/
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
		declare @tInvt as tUniq_key
			declare @Invt table(uniq_key char(10),[Part Number] varchar(34) ,part_no char(35),revision char(8))
		insert into @Invt SELECT Uniq_key,[PART Number],Part_no,Revision from View_InvtMake4SoPrice I where I.Custno IN (SELECT Custno from @tCustomer)
		--get list of Product the user is approved to view based off of the approve Customer listing
		if @lcUniq_key is not null and @lcUniq_key <>'' and @lcUniq_key<>'All'
			insert into @tInvt select * from dbo.[fn_simpleVarcharlistToTable](@lcUniq_key,',')

		---08/09/17 YS do not populate vallues in @tInvt if all parts are selected
		---ELSE

		--IF  @lcUniq_key='All'	
		--BEGIN
		--	INSERT INTO @tInvt SELECT Uniq_key FROM @Invt
		--END


		
/*SELECTION SECTION*/		

if (@lcRptType = 'by Part Number')
	Begin
		-- 12/05/19 VL changed to use new price tables for cube version
		-----08/09/17 YS added currency symbol
		--select	inventor.PART_NO,inventor.revision,inventor.part_class,inventor.PART_TYPE,inventor.DESCRIPT,Customer.CUSTNAME
		--		,ISNULL(FROMQTY,0000000) as FromQty,ISNULL(toQty,0000000) as ToQty,isnull(TOTALPRICE,000000.00000) as TotalPrice,
		--		isnull(f.Symbol,space(3)) as Currency
		--		,inventor.SALETYPEID,prichead.uniq_key
		--from	CUSTOMER
		--		inner join @customer on customer.CUSTNO=[@customer].custno
		--		inner join prichead on customer.CUSTNO = prichead.CATEGORY
		--		inner join PRICDETL on Prichead.Uniq_key + Prichead.Category = Pricdetl.Uniq_key + Pricdetl.Category
		--		left outer join FCUSED F on PRICHEAD.Fcused_uniq=f.FcUsed_Uniq 
		--		inner join INVENTOR on PRICHEAD.UNIQ_KEY = inventor.UNIQ_KEY
		-----08/09/17 YS update where
		--where	customer.STATUS = 'Active'
		-----08/09/17 YS move up to inner join
		--		--AND 1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		-----08/09/17 YS change the next and
		-----and 1 = case when inventor.uniq_key in (select uniq_key from @tInvt) then 1 else 0 end
		--and (@lcUniq_key='All' OR inventor.uniq_key in (select uniq_key from @tInvt) )
		--order by part_no,Revision,Custname,isnull(TOTALPRICE,000000.00000) Desc
		-- 12/05/19 VL start new code, no currency, saletype fields for now
		SELECT Part_no, Revision, Part_class, Part_type, Descript, Custname, FromQty, ToQty, pcb.Amount AS TotalPrice, PH.Uniq_key
			FROM priceheader PH INNER JOIN Inventor ON PH.Uniq_key = Inventor.Uniq_key
			INNER JOIN PriceCustomer pc ON pc.UniqPrHead = ph.UniqPrHead 
			INNER JOIN Customer ON pc.Custno = Customer.Custno	
			INNER JOIN @Customer ON Customer.Custno = [@Customer].Custno		
			INNER JOIN PriceCustbreak pcb ON pcb.UniqPrHead = ph.UniqPrHead AND pc.UniqPrCustId = pcb.UniqPrCustId      
			WHERE Customer.STATUS = 'Active'
			AND (@lcUniq_key='All' OR inventor.uniq_key in (select uniq_key from @tInvt) )
			ORDER BY  Part_no, Revision, Custname, pcb.Amount DESC

	End	
		
else if (@lcRptType = 'by Customer')
	Begin
		-- 12/05/19 VL changed to use new price tables for cube version
		-----08/09/17 YS added currency symbol
		--select	Customer.CUSTNAME,inventor.PART_NO,inventor.revision,inventor.part_class,inventor.PART_TYPE,inventor.DESCRIPT
		--		,ISNULL(FROMQTY,0000000) as FromQty,ISNULL(toQty,0000000) as ToQty,isnull(TOTALPRICE,000000.00000) as TotalPrice,
		--		isnull(f.Symbol,space(3)) as Currency
		--		,inventor.SALETYPEID,prichead.uniq_key
		--from	CUSTOMER
		--		inner join @customer on customer.CUSTNO=[@customer].custno
		--		inner join prichead on customer.CUSTNO = prichead.CATEGORY
		--		inner join PRICDETL on Prichead.Uniq_key + Prichead.Category = Pricdetl.Uniq_key + Pricdetl.Category
		--		left outer join FCUSED F on PRICHEAD.Fcused_uniq=f.FcUsed_Uniq 
		--		inner join INVENTOR on PRICHEAD.UNIQ_KEY = inventor.UNIQ_KEY
		-----08/09/17 YS update where
		--where	customer.STATUS = 'Active'
		--		---08/09/17 YS move up to inner join
		--		---AND 1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		--		---08/09/17 YS change the next and
		-----and 1 = case when inventor.uniq_key in (select uniq_key from @tInvt) then 1 else 0 end
		--and (@lcUniq_key='All' OR inventor.uniq_key in (select uniq_key from @tInvt) )
		--order by Custname,part_no,Revision,isnull(TOTALPRICE,000000.00000)Desc
		-- 12/05/19 VL start new code, no currency, saletype fields for now
		SELECT Part_no, Revision, Part_class, Part_type, Descript, Custname, FromQty, ToQty, pcb.Amount AS TotalPrice, PH.Uniq_key
			FROM priceheader PH INNER JOIN Inventor ON PH.Uniq_key = Inventor.Uniq_key
			INNER JOIN PriceCustomer pc ON pc.UniqPrHead = ph.UniqPrHead 
			INNER JOIN Customer ON pc.Custno = Customer.Custno	
			INNER JOIN @Customer ON Customer.Custno = [@Customer].Custno				
			INNER JOIN PriceCustbreak pcb ON pcb.UniqPrHead = ph.UniqPrHead AND pc.UniqPrCustId = pcb.UniqPrCustId      
			WHERE Customer.STATUS = 'Active'
			AND (@lcUniq_key='All' OR inventor.uniq_key in (select uniq_key from @tInvt) )
			ORDER BY Custname, Part_no, Revision, pcb.Amount DESC


	End

end