


-- =============================================
-- Author:			<Debbie> 
-- Create date:		<02/10/2012>
-- Description:		<compiles details for the Shipping Labels>
-- Reports:			<used on shiplbl.rpt>
-- Modifications:	08/29/2012 DRP:  Testing reported that the labels were not working against a couple Customer datasets.  
--									 upon investigation it was found that the ShipTo,ShipAdd1,ShipAdd2, ShipAdd3 and ShipAdd4 were too small and causing truncation against their data.  
--									 I increased the field sizes to char(50) within the @tResults table below.
--					10/05/2012 DRP:  Found that if the users did not have a Shipping address selected that it would not pull the packing List detail forward at all.
--									 Change the Inner Join to Outer Join
--					02/12/2020 YS : added POno to the plmain for manual invoice
-- =============================================
CREATE PROCEDURE [dbo].[rptShipLbl] 
	@lcPackListNo char(10) = ' '
	,@lcLineNo char (7) = ''

AS
BEGIN

Declare @tResults table	(PackListNo char(10),SoNo char(10),PoNo char (20),uniqueln char(10),Line_No char (10),Uniq_key char(10),PartNo char (25),Rev char (8),Descript char (45)
						,Part_Class char(8),Part_Type char(8),ShippedQty numeric (12,2),ShipDate date,ShipTo char (50),ShipAdd1 char (50),ShipAdd2 char (50),ShipAdd3 char (50),ShipAdd4 char (50))
;
with zInfo as (
--					02/12/2020 YS : added POno to the plmain for manual invoice
				Select	plmain.PACKLISTNO,plmain.SONO,ISNULL(Somain.pono,plmain.pono) as pono,pldetail.uniqueln,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No 
						,isnull(sodetail.uniq_key,space(10))as Uniq_key,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev
						,ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript,part_class,part_type,pldetail.shippedqty,plmain.SHIPDATE
						,s.SHIPTO,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
						,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
						,case when s.address2 <> '' then s.country else '' end as ShipAdd4
						
				from	plmain
						left outer join SOMAIN on plmain.SONO = somain.SONO
						inner join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
						left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
						left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
						left outer join SHIPBILL as S on plmain.LINKADD = s.LINKADD
			)

INSERT @tResults
select * from zInfo

Select * from @tResults
		
where	PACKLISTNO = dbo.PADL(@lcPackListNo,10,0)
		and Line_No = CASE WHEN Uniq_key=' ' THEN @lcLineNo ELSE dbo.PADL(@lcLineNo,7,0) END
		
		
end