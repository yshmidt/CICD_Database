

-- =============================================
-- Author:		Debbie
-- Create date:	01/05/2012
-- Description:	This Stored Procedure was created for the "Project Back Order Status / SO Detail"
-- Reports:		prjsos.rpt, prjsosu.rpt
-- Modified:		11/13/15 DRP:  added the @userId, /*Customer LIst*/, @lcStatus, @lcRptType, etc. . . and other changes to get the report to work with the WebManex. 
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================

CREATE PROCEDURE [dbo].[rptProjBackOrder]
--declare
			@lcPrjNumber as varchar (max) = 'aLL'
			,@lcStatus as char (10) = 'All'		--All, Open, Closed or Cancelled	--11/06/15 DRP:  Added
			,@lcRptType char (10) = 'Detailed'	--Detailed or Summary
			,@userId uniqueidentifier= null
as			
begin


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	

/*PROJECT LIST*/
declare @tProj as table (PrjUnique char (10),Prjnumber char(10),prjstatus char(10))
insert into @tProj select prjunique,prjnumber,prjstatus from pjctmain where exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=pjctmain.custno)
declare @Proj as table (prjunique char(10))

IF @lcPrjNumber is not null and @lcPrjNumber <>'' and @lcPrjNumber<>'All'
			insert into @Proj select * from dbo.[fn_simpleVarcharlistToTable](@lcPrjNumber,',')
					where CAST (id as CHAR(10)) in (select PrjUnique from @tProj)
		ELSE

		IF  @lcPrjNumber='All'	and @lcStatus = 'All'
		BEGIN
			INSERT INTO @Proj SELECT Prjunique FROM @tProj 
		END

		IF  @lcPrjNumber='All'	and @lcStatus = 'Open'
		BEGIN
			INSERT INTO @Proj SELECT Prjunique FROM @tProj where prjstatus = 'Open'
		END

		IF  @lcPrjNumber='All'	and @lcStatus = 'Closed'
		BEGIN
			INSERT INTO @Proj SELECT Prjunique FROM @tProj where prjstatus = 'Closed'
		END

		IF  @lcPrjNumber='All'	and @lcStatus = 'Cancelled'
		BEGIN
			INSERT INTO @Proj SELECT Prjunique FROM @tProj where prjstatus = 'Cancelled'
		END
		--select * from @Proj


/*RECORD SELECTION*/
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
declare @tresults table		(sono char (10),Line_No char(7),Uniqueln char (10),custno char(10),prjnumber char(10),prjdescrp char(50),prjstatus char(10),Uniq_key char(10)
							,Balance numeric (12,5),OpenAmtP numeric(12,5), OpenAmtF numeric(12,5),part_no char(35),revision char(8),descript char (45),part_class char(8),part_type char(8)
							,SoExtd numeric(12,5))

;
with	zOpenSoAlloc as	(	
							select	sodetail.SONO,LINE_NO,sodetail.UNIQUELN,sodetail.uniq_key,BALANCE,CAST (0.00 as numeric (12,5)) as ExtdBal,pjctmain.prjnumber,PJCTMAIN.PRJDESCRP
									,pjctmain.PRJSTATUS,PJCTMAIN.CUSTNO
							from	SODETAIL
									inner join PJCTMAIN on sodetail.PRJUNIQUE = PJCTMAIN.PRJUNIQUE
							where	sodetail.STATUS <> 'Closed' and sodetail.STATUS <> 'Cancel'
									and sodetail.STATUS <> 'Archived'
									and BALANCE <> 0
									and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=pjctmain.custno)				--11/06/15 DRP:  Added
									and exists (select 1 from @Proj B inner join pjctmain P on B.prjunique=P.prjunique where P.PRJUNIQUE=pjctmain.PRJUNIQUE)	--11/06/15 DRP:  Added
								

						)
						,
		zPrice as		(
							select	sodetail.UNIQUELN
									,sum(case when soprices.recordtype = 'P' then (price*balance)else price* case when quantity>SHIPPEDQTY then quantity-shippedqty else 0 end end) as OpenAmtP,CAST (0.00 as numeric (12,5)) as OpenAmtF 
							from	SODETAIL
									inner join SOPRICES on sodetail.UNIQUELN = soprices.UNIQUELN
							where	SOPRICES.FLAT = 0 
							group by sodetail.UNIQUELN
									
						)
						,
		zFlatPrice as	(
						select	sodetail.UNIQUELN,cast (0.00 as numeric (12,5)) as OpenAmtP, SUM(price) as OpenAmtF
						from	SODETAIL
								inner join SOPRICES on SODETAIL.UNIQUELN = soprices.UNIQUELN
						where	SOPRICES.FLAT = 1
								and SODETAIL.SHIPPEDQTY = 0.00
						group by sodetail.UNIQUELN
						)
insert @tresults
	select 		zOpenSoAlloc.sono,zOpenSoAlloc.LINE_NO,zOpenSoAlloc.UNIQUELN,zOpenSoAlloc.CUSTNO,zOpenSoAlloc.PRJNUMBER,zOpenSoAlloc.PRJDESCRP,zOpenSoAlloc.PRJSTATUS,zOpenSoAlloc.UNIQ_KEY
				,zOpenSoAlloc.BALANCE,zPrice.OpenAmtP, case when zFlatPrice.OpenAmtF IS null then CAST (0.00 as numeric(12,5)) else zFlatPrice.OpenAmtF end as OpenAmtF,PART_NO,REVISION
				,DESCRIPT,PART_CLASS,PART_TYPE,isnull(zPrice.openamtp,0.00)+isnull(zflatprice.openamtf,0.00) as SoExtd
	from		zOpenSoAlloc
				LEFT OUTER JOIN	zPrice on zOpenSoAlloc.UNIQUELN = zPrice.UNIQUELN
				left outer join zFlatPrice on zOpenSoAlloc.UNIQUELN = zFlatPrice.UNIQUELN
				left outer join inventor on zOpenSoAlloc.UNIQ_KEY = INVENTOR.UNIQ_KEY
	
if @lcRptType = 'Detailed'
	Begin
		select * from @tresults	 order by prjnumber,sono
	End
Else if @lcRptType = 'Summary'
	Begin
	select prjnumber,prjdescrp,prjstatus,sono,sum (SoExtd) as SoExtd from @tresults group by prjnumber,prjdescrp,prjstatus,sono
	End

	
end