

-- =============================================
-- Author:		Debbie
-- Create date: 01/03/2012
-- Description:	This Stored Procedure was created for the "Project Inventory Status Detail"
-- Reports Using Stored Procedure:  prjallst.rpt, prjallsu.rpt

-- Modified:	10/13/14   YS: removed invtmfhd table 
--				04/14/15 YS change "location" column length to 256
--				11/06/15 DRP:  add the @userId and /*CUSTOMER LIST*/ in order for it to work with the WebManex reports.  Added @lcProjStatus
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================

CREATE PROCEDURE [dbo].[rptProjectAlloc]

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
--- 04/14/15 YS change "location" column length to 256
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
declare @tresults table	(prjnumber char(10),custno char(10),prjdescrp char(50),prjstatus char(10),prjcompld smalldatetime,w_key char(10),AllocTot numeric(12,2),fk_prjunique char (10)
							,Uniq_key char(10),AvgActCost numeric (12,5),part_no char(35),revision char(8),descript char (45),part_class char(8),part_type char(8),PartMfgr char(8)
							,MfgrPartNo char (30),stdcost numeric(13,5),warehouse char (8),location varchar(256),ExtdStd numeric(12,2),ExtdAct numeric(12,2))
;
with	zOpenAllocs as	(

						select	PRJNUMBER,PJCTMAIN.CUSTNO,PRJDESCRP,PRJSTATUS,PRJCOMPLD,invt_res.W_KEY,SUM(qtyalloc) as AllocTot,invt_res.FK_PRJUNIQUE,warehouse,CAST (0.00 as numeric (12,2)) as AvgActCost
								,invt_res.UNIQ_KEY
						from	pjctmain
								inner join INVT_RES on pjctmain.PRJUNIQUE = invt_res.FK_PRJUNIQUE
								inner join INVtmfgr on invt_res.W_KEY = invtmfgr.W_KEY
								left outer join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
						where	exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=pjctmain.custno)				--11/06/15 DRP:  Added
								and exists (select 1 from @Proj B inner join pjctmain P on B.prjunique=P.prjunique where P.PRJUNIQUE=pjctmain.PRJUNIQUE)	--11/06/15 DRP:  Added
								--prjnumber like case when @lcProj = '*' then '%' else @lcProj+'%' end	--11/06/15 DRP:  removed
						group by PRJNUMBER,PJCTMAIN.CUSTNO,PRJDESCRP,PRJSTATUS,PRJCOMPLD,invt_res.W_KEY,invt_res.FK_PRJUNIQUE,warehouse,invt_res.UNIQ_KEY
						
						)
						,
		zPoSource as	(Select	poitems.UNIQ_KEY, poitschd.WOPRJNUMBER, (SUM(poitschd.RECDQTY*poitems.COSTEACH)/SUM(POITSCHD.RECDQTY)) as AvgActCost
						from	poitems
								inner join POITSCHD on POITEMs.UNIQLNNO = POITSCHD.UNIQLNNO
						where	REQUESTTP = 'Prj Alloc'
								and RECDQTY > 0
								and POITSCHD.WOPRJNUMBER in (select prjnumber from zOpenAllocs)
						group by poitems.UNIQ_KEY,poitschd.WOPRJNUMBER
						)	
							

insert @tresults 
	select	PRJNUMBER,zopenallocs.CUSTNO,PRJDESCRP,PRJSTATUS,PRJCOMPLD,zopenallocs.W_KEY,AllocTot,FK_PRJUNIQUE
			,zopenAllocs.UNIQ_KEY,zposource.AvgActCost,PART_NO,REVISION,DESCRIPT,PART_CLASS,PART_TYPE,m.partmfgr,
			m.MFGR_PT_NO,STDCOST,warehouse,LOCATION,stdcost*alloctot as ExtdStd,alloctot*zposource.avgactcost as ExtdAct
	from	zOpenAllocs
			left outer join zPoSource on zOpenAllocs.UNIQ_KEY+zOpenAllocs.PRJNUMBER = zPoSource.UNIQ_KEY+zPoSource.WOPRJNUMBER
			inner join inventor on zOpenAllocs.UNIQ_KEY = inventor.UNIQ_KEY
			inner join INVTMFGR on zOpenAllocs.W_KEY = invtmfgr.W_KEY 
			--	10/13/14   YS: removed invtmfhd table 
			--inner join INVTMFHD on INVTMFGR.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
			inner join InvtMPNLink L on INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD
			INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId

if @lcRptType = 'Detailed'
	Begin
		select * from @tresults	
	End
Else if @lcRptType = 'Summary'
	Begin
	select prjnumber,prjdescrp,prjstatus,sum (ExtdStd) as ExtdStd from @tresults group by prjnumber,prjdescrp,prjstatus
	End
										
end