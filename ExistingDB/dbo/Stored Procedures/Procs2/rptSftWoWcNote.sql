
-- =============================================
-- Author:		Debbie
-- Create date:	05/15/2012
-- Description:	Created for the Work Order Work Center Notes Report
-- Reports:		shopwowc.rpt
-- Modified:		11/12/15 DRP:  added @userId, /*CUSTOMER LIST*/ and other items to get this procedure to work with Webmanex
-- 09/18/20 VL changed to use wmNote for WO note and WO WC note
-- =============================================
CREATE PROCEDURE [dbo].[rptSftWoWcNote]
--declare
		@lcWoNo as char (10) = ''
		,@userId uniqueidentifier= NULL

as
begin


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	
		
/*RECORD SELECTION SECTION*/
select	DEPT_QTY.WONO,isnull(somain.sono,'')as sono,isnull(somain.pono,'')as pono,woentry.ORDERDATE,customer.custname,woentry.BLDQTY,inventor.PERPANEL
		,case when inventor.perpanel = 0.00 then woentry.BLDQTY else cast(woentry.bldqty/inventor.perpanel as numeric (7,0))end as PnlBlank
		,inventor.part_no,inventor.revision,inventor.descript,DEPT_QTY.number,dept_qty.DEPT_ID,depts.DEPT_NAME
		-- 09/18/20 VL added WO WC Note from wmNotes
		--,dept_qty.WO_WC_NOTE
		 ,WOWCNote.Note AS WO_WC_NOTE
		,NUMBERA
		,actv_qty.ACTIV_ID,isnull(activity.ACTIV_NAME,'') AS ACTIV_NAME,isnull(ACTV_QTY.WO_WC_NOTE,'') AS ActvWoWcNote
		-- 09/18/20 VL added WO Note from wmNotes
		--,woentry.WONOTE
		,WONote.Note AS WONOTE
from	DEPT_QTY
		inner join DEPTS on dept_Qty.DEPT_ID = depts.DEPT_ID
		inner join WOENTRY on dept_Qty.WONO = woentry.WONO
		inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY
		inner join CUSTOMER on woentry.CUSTNO = customer.CUSTNO
		left outer join ACTV_QTY on dept_qty.WONO+dept_qty.DEPTKEY = actv_qty.wono+actv_qty.DEPTKEY
		left outer join ACTIVITY on actv_qty.ACTIV_ID = activity.ACTIV_ID
		left outer join somain on woentry.sono = somain.sono
		-- 09/18/20 VL added WO WC Note from wmNotes
		OUTER APPLY (SELECT TOP 1 r.* 
		FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'WorkOrderWorkCenter' AND w.RecordId = Dept_qty.UNIQUEREC
		ORDER BY r.CreatedDate DESC) WOWCNote
		-- 09/18/20 VL added WO Note from wmNotes
		OUTER APPLY (SELECT TOP 1 r.* 
		FROM wmNoteRelationship r INNER JOIN wmNotes w ON r.FkNoteId = w.NoteID AND w.RecordType = 'WorkOrder' AND w.RecordId = Woentry.Wono
		ORDER BY r.CreatedDate DESC) WONote
		
where	woentry.wono = dbo.padl(@lcWoNo,10,'0')
		and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=WOENTRY.custno)

order by NUMBER,NUMBERA

end