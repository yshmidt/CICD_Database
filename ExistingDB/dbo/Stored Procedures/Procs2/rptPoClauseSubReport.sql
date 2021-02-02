
-- =============================================
-- Author:		Debbie Peltier
-- Create date: 03/09/2012
-- Description:	This Stored Procedure will gather any Note clause used on either PO item or PO Main and display it in the subreport to follow thePurchase Order form
-- Reports Using Stored Procedure:  po.rpt
-- Modified:	09/16/2014 DRP:  added NoteText to the results so that it could be used within the Report results instead of needing to pull in the table in the report designer, also removed the group by
--							 added where noteunique <> '' at the end so that I would not pull in any results that had a blank noteunique. 
-- =============================================
CREATE PROCEDURE [dbo].[rptPoClauseSubReport]

	@lcPonum char(15) = '',@lcAllItems char (3) = 'No'
as
begin
 
;
with
ZPoItemClause as (
					select	ponum
					,case when @lcAllItems = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY = 0.00 then '' else 
						case when @lcAllItems  = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY > 0.00 then notesetup.noteunique else	
							case when @lcAllItems = 'Yes' then notesetup.noteunique else '' end end end as noteunique
					,NOTENAME
					,case when @lcAllItems = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY = 0.00 then '' else 
						case when @lcAllItems  = 'No' and poitems.ORD_QTY-poitems.ACPT_QTY > 0.00 then notesetup.NOTETEXT else	
							case when @lcAllItems = 'Yes' then notesetup.NOTETEXT else '' end end end as notetext
					from	POITEMS
							inner join NOTEASSIGN on poitems.uniqlnno = NOTEASSIGN.TABLEUNIQUE
							inner join NOTESETUP on notesetup.NOTEUNIQUE = NOTEASSIGN.FKNOTEUNIQUE
					where	POITEMS.PONUM = dbo.padl(@lcPoNum,15,'0')
							and poitems.LCANCEL <> 1

							
					
				)

				,
ZPoMainClause as	(
						select	 ponum,notesetup.NOTEUNIQUE,notename,notesetup.NOTETEXT
						from	POMAIN
								inner join NOTEASSIGN on pomain.POUNIQUE = NOTEASSIGN.TABLEUNIQUE
								inner join NOTESETUP on notesetup.NOTEUNIQUE = NOTEASSIGN.FKNOTEUNIQUE
						where	POMAIN.PONUM = dbo.padl(@lcPoNum,15,'0')
					)
			

select 	t1.ponum,t1.noteunique,t1.notename,t1.notetext
from
(
select * from ZPoItemClause where noteunique <> ''
union all 
select * from zpomainclause where NOTEUNIQUE <> ''
)t1

--group by ponum,NOTEUNIQUE,NOTENAME,notetext	--09/16/2014 DRP:  removed the group by 

end


				