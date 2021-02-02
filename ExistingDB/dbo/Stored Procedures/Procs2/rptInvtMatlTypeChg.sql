

-- =============================================
-- Author:		Debbie
-- Create date: 10/24/2011
-- Description:	This Stored Procedure was created for the  Material Type Change Report  
-- Reports Using Stored Procedure:  icrptmt.rpt
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
--			  06/12/2015 DRP:  needed to change the Parameter @lcSince to be @lcDate so I could use already existing parameters within the tables. 
-- =============================================

CREATE PROCEDURE [dbo].[rptInvtMatlTypeChg]

@lcDate as smalldatetime= null
,@userId uniqueidentifier=null

as
Begin

	select	uniq_key,case when part_sourc = 'CONSG' then custpartno else Part_no end as Part_no, case when part_sourc = 'CONSG' then custrev else REVISION end as revision
	,PART_SOURC,part_class,part_type,DESCRIPT,custname,MATLTYPE,MTCHGDT,MTCHGINIT 

	from	INVENTOR
			left outer join CUSTOMER on inventor.CUSTNO = customer.CUSTNO
			
	where	mtchgdt is not null 
			and MTCHGDT >= @lcDate

end