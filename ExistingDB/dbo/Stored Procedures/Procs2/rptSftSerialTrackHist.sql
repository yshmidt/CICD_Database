
-- =============================================
-- Author:		Debbie
-- Create date: 05/16/2012
-- Description:	Created for the Serial Numbers Tracking History report within the SFT module
-- Reports Using Stored Procedure:  serhist.rpt
-- 06/13/18 YS serial transfer history moved to transferSNx
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptSftSerialTrackHist]

		@lcSnStart as VARchar(30) = ''
		, @lcSnEnd as VARchar (30) = ''

as 
begin
--This section will compile the transfer history for serial numbers 
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
SELECT	cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo,TRANSFER.WONO,I1.PART_NO AS WoPartNo,i1.REVISION as WoRev,i1.descript,transfer.DATE as TrnsDate,FR_DEPT_ID,TO_DEPT_ID,[BY]
		,'T' as DispFlag,CAST('' as CHAR(4)) as CHGDEPT, CAST (null as smalldatetime) as DefDate,CAST ('' AS CHAR(10)) AS DEF_CODE,CAST ('' AS CHAR (30)) AS LOCATION
		,CAST('' AS CHAR (8)) AS PARTMFGR,CAST ('' AS CHAR(35)) AS CompPart, CAST ('' as CHAR(8)) as CompRev,CAST('' as CHAR (10)) as InspBy
		-- 06/13/18 YS serial transfer history moved to transferSNx
FROM	TRANSFER inner join TRANSFERSNX ts on transfer.XFER_UNIQ=ts.FK_XFR_UNIQ
inner join INVTSER s on ts.FK_SERIALUNIQ=s.serialuniq
		INNER JOIN WOENTRY ON TRANSFER.WONO = WOENTRY.WONO
		INNER JOIN INVENTOR AS I1 ON WOENTRY.UNIQ_KEY = I1.UNIQ_KEY 

where	s.SERIALNO >= dbo.PADL(@lcSnStart,30,'0') and serialno <= dbo.PADL(@lcSnEnd,30,'0')


union

--This section will gather and include the detailed information recorded from the Defect Code entry per serial number
Select	cast(dbo.fremoveLeadingZeros(qadef.SERIALNO) as varchar(MAx)) as SerialNo, qadef.WONO,I1.part_no as WoPartNo,i1.revision as WoRev,i1.DESCRIPT
		,cast(null as smalldatetime ) as TrnsDate,cast('' as char(8)) as FR_DEPT_ID,cast('' as char(8)) as TO_DEPT_ID
		,cast ('' as CHAR(10)) as [BY],'D' as DispFlag,CHGDEPT_ID,qainsp.date as DefDate,qadefloc.DEF_CODE,qadefloc.LOCATION,qadefloc.PARTMFGR
		,inventor.part_no as CompPart,inventor.REVISION as CompRev,qainsp.INSPBY as InspBy

from	QADEF
		inner join QAINSP on QADEF.QASEQMAIN = qainsp.QASEQMAIN
		inner join QADEFLOC on qadef.LOCSEQNO = qadefloc.LOCSEQNO
		left outer join INVENTOR on qadefloc.UNIQ_KEY = inventor.UNIQ_KEY
		inner join WOENTRY on qadef.WONO = woentry.WONO
		inner join INVENTOR as I1 on woentry.UNIQ_KEY = i1. UNIQ_KEY

where	SERIALNO >= dbo.PADL(@lcSnStart,30,'0') and serialno <= dbo.PADL(@lcSnEnd,30,'0')


end