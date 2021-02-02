

-- =============================================
-- Author:		Debbie
-- Create date: 10/25/2011
-- Description:	This Stored Procedure was created for the  "Material Type Change Log Detail Report"  
-- Reports Using Stored Procedure:  icrptmtd.rpt
-- Modified:	01/15/2014 DRP:  added the @userid parameter for WebManex
--				07/13/15 DRP:  changed the parameter from @lcSince to @lcDate to work with the already existing Cloud Params
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtMatlTypeChgLogDtl]

@lcDate as smalldatetime= null		--07/13/15 DRP:  changed from @lcSince to @lcDate
,@userId uniqueidentifier=null

as
Begin
	select	updmattplog.UNIQ_KEY,case when part_sourc = 'CONSG' then custpartno else part_no end as Part_no
			,Case when PART_SOURC = 'CONSG' then CUSTREV else revision end as revision,part_sourc,inventor.CUSTNO,custname,part_class,Part_type,descript
			,FROMMATLTYPE,TOMATLTYPE,updmattplog.MTCHGDT,updmattplog.MTCHGINIT
			
	from	UPDMATTPLOG
			left outer join INVENTOR on UPDMATTPLOG.UNIQ_KEY = inventor.UNIQ_KEY
			left outer join CUSTOMER on inventor.CUSTNO = customer.CUSTNO
			
	where	inventor.STATUS = 'Active'
			and updmattplog.mtchgdt >= @lcDate		--07/13/15 DRP:  changed from @lcSince to @lcDate

end