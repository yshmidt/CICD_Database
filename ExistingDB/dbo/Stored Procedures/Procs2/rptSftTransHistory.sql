
-- =============================================
-- Author:		Debbie
-- Create date: 05/11/2012
-- Description:	Created for Tranfer History Reprt for Selected Work Centers
-- Reports Using Stored Procedure:  trhistrp.rpt
--06/13/18 serialuniq saved in transfsnx table
-- =============================================

CREATE PROCEDURE [dbo].[rptSftTransHistory]

		 @lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@lcDeptiD as VARchar(4) = '*'
		
as
begin		
--This section will gather the from information 
select	XFER_UNIQ,transfer.WONO,woentry.UNIQ_KEY,PART_NO,REVISION,PROD_ID,transfer.DATE,transfer.QTY,FR_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then frDept.DEPT_NAME 
			else case when fr_actvkey = '' and to_actvkey <> '' then frDept.dept_name 
				else case when fr_actvkey <> '' and to_Actvkey <> '' then FrActv.ACTIV_NAME 
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then FrActv.ACTIV_NAME end end end end as FrName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when fr_actvkey = '' and to_actvkey <> '' then CAST('' as CHAR(1))
				else case when fr_actvkey <> '' and to_Actvkey <> '' then CAST('A' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('A' as CHAR(1)) end end end end as FrActvInd
		,TO_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then todept.DEPT_NAME
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then toActv.ACTIV_NAME
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then todept.dept_name
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then ToActv.ACTIV_NAME 	end end end end as ToName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1))
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1)) 	end end end end as ToActvInd
		,[By] AS XferBy,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo

from		TRANSFER 
			left outer join DEPTS as FrDept on transfer.FR_DEPT_ID = FrDept.DEPT_ID
			left outer join DEPTS as ToDept on transfer.TO_DEPT_ID = ToDept.DEPT_ID
			left outer join QUOTDPDT as frQ  on transfer.FR_ACTVKEY = frQ.UNIQNBRA
			left outer join ACTIVITY as FrActv on FrActv.ACTIV_ID = frQ.ACTIV_ID
			LEFT OUTER JOIN QUOTDPDT AS ToQ on transfer.TO_ACTVKEY = ToQ.UNIQNBRA
			left outer join ACTIVITY as ToActv on ToActv.ACTIV_ID = Toq.ACTIV_ID
			--06/13/18 serialuniq saved in transfsnx table
			left outer join TRANSFERSNX ts on transfer.XFER_UNIQ=ts.FK_XFR_UNIQ
			left outer join invtser s on ts.fk_serialuniq=s.SERIALNO
			inner join woentry on transfer.wono = woentry.wono
			inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY

--this section will gather the to information			
where			TRANSFER.DATE>=@lcDateStart AND transfer.DATE<@lcDateEnd+1
				and TRANSFER.FR_DEPT_ID like case when @lcDeptiD ='*' then '%' else @lcDeptiD + '%' end

union
select	XFER_UNIQ,transfer.WONO,woentry.UNIQ_KEY,PART_NO,REVISION,PROD_ID,transfer.DATE,transfer.QTY,FR_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then frDept.DEPT_NAME 
			else case when fr_actvkey = '' and to_actvkey <> '' then frDept.dept_name 
				else case when fr_actvkey <> '' and to_Actvkey <> '' then FrActv.ACTIV_NAME 
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then FrActv.ACTIV_NAME end end end end as FrName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when fr_actvkey = '' and to_actvkey <> '' then CAST('' as CHAR(1))
				else case when fr_actvkey <> '' and to_Actvkey <> '' then CAST('A' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('A' as CHAR(1)) end end end end as FrActvInd
		,TO_DEPT_ID
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then todept.DEPT_NAME
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then toActv.ACTIV_NAME
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then todept.dept_name
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then ToActv.ACTIV_NAME 	end end end end as ToName
		,case when FR_ACTVKEY = '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
			else case when FR_ACTVKEY = '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1))
				else case when FR_ACTVKEY <> '' and TO_ACTVKEY = '' then CAST('' as CHAR(1))
					else case when FR_ACTVKEY <> '' and TO_ACTVKEY <> '' then CAST('A' as CHAR(1)) 	end end end end as ToActvInd
		,[By] AS XferBy,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo

from		TRANSFER 
			left outer join DEPTS as FrDept on transfer.FR_DEPT_ID = FrDept.DEPT_ID
			left outer join DEPTS as ToDept on transfer.TO_DEPT_ID = ToDept.DEPT_ID
			left outer join QUOTDPDT as frQ  on transfer.FR_ACTVKEY = frQ.UNIQNBRA
			left outer join ACTIVITY as FrActv on FrActv.ACTIV_ID = frQ.ACTIV_ID
			LEFT OUTER JOIN QUOTDPDT AS ToQ on transfer.TO_ACTVKEY = ToQ.UNIQNBRA
			left outer join ACTIVITY as ToActv on ToActv.ACTIV_ID = Toq.ACTIV_ID
			--06/13/18 serialuniq saved in transfsnx table
			left outer join TRANSFERSNX ts on transfer.XFER_UNIQ=ts.FK_XFR_UNIQ
			left outer join invtser s on ts.fk_serialuniq=s.SERIALNO
			inner join woentry on transfer.wono = woentry.wono
			inner join INVENTOR on woentry.UNIQ_KEY = inventor.UNIQ_KEY
			where	TRANSFER.DATE>=@lcDateStart AND transfer.DATE<@lcDateEnd+1
				and TRANSFER.TO_DEPT_ID like case when @lcDeptiD ='*' then '%' else @lcDeptiD + '%' end				

order by date

end
		 

		