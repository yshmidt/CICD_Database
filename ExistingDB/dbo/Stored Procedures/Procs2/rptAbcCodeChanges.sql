-- =============================================
-- Author:		Debbie	
-- Create date:	10/27/2015
-- Report:		abcrpt
-- Description:	Proposed ABC Code Changes                         
-- Modifaction: 
-- =============================================
create PROCEDURE [dbo].[rptAbcCodeChanges] 

--declare 

@RecordSelect char(25) = 'Proposed Changes Only'	--Proposed Changes Only or All Parts
,@Source char(5) = 'BUY'	--MAKE or BUY
,@userId uniqueidentifier = null

as
begin
		
select	PART_CLASS,PART_TYPE,PART_NO,REVISION,DESCRIPT,inventor.part_sourc,inventor.ABC as CurrentABC,tempabc.ABC as ProposedABC
		,tempabc.REASON as CalcBasedOn,case when tempabc.reason = 'EAU' then inventor.eau else 0 end as EAU,inventor.uniq_key
from	INVENTOR
		inner join TEMPABC on inventor.UNIQ_KEY = TEMPABC.UNIQ_KEY
where	1 = case when @RecordSelect = 'Proposed Changes Only' and TEMPABC.abc <> INVENTOR.ABC then 1 else
				case when @RecordSelect = 'All Parts' and TEMPABC.ABC=INVENTOR.ABC then 1 else 0 end end
		and @Source = inventor.PART_SOURC
order by	part_class,Part_type,part_no,revision

end