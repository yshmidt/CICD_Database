


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
--					05/01/2015 DRP:	created this rptShipLblWM copy of the procedure to work with the Cloud version of the labels.
--									added the userId Parameter for Cloud, Per request of a user added the CustPartNo and CustRev to the results so they can have an option to have the CustPn on the Labels.
--									Removed the @lcLineNo parameter because with the Grid Layout in the Cloud it will not be needed they can pick the lables to print from the grid.   Added LabelQty to the results.
--					06/23/2015 DRP: Removed the CustPartNo and CustRev from the results and changed the code so the Customer Part info will display in the PartNo field depending on the @lcCustPn Parameter selection
-- 05/04/17 DRP:  added the @lcLabelQty parameter per request of the users.  This way they can enter in a Label Qty to be populated into the grid, but should also then be able to change within the grid if needed. 	
--					02/12/2020 YS : added POno to the plmain for manual invoice
-- =============================================
CREATE PROCEDURE [dbo].[rptShipLblWM] 
--	declare
	@lcPackListNo char(10) = ''
	--,@lcLineNo char (7) = '2'		--05/01/2015 DRP:  REMOVED
	,@lcCustPn char(3) = 'No'		--Yes = Display Customer Part Number, No = Display Internal Part Number	--06/23/2015 DRP:  Added
	,@lcLabelQty as int = null		--05/04/17 DRP:  added
	, @userId uniqueidentifier=null
	

AS
BEGIN


Declare @tResults table	(PackListNo char(10),SoNo char(10),PoNo char (20),uniqueln char(10),Line_No char (10),Uniq_key char(10),PartNo char (25),Rev char (8),Descript char (45),Part_Class char(8),Part_Type char(8)
						,ShippedQty numeric (12,2),ShipDate date,ShipTo char (50),ShipToAddress varchar(200),LabelQty NUMERIC(3,0))
;
with zInfo as (
--					02/12/2020 YS : added POno to the plmain for manual invoice
				Select	plmain.PACKLISTNO,plmain.SONO,ISNULL(Somain.pono,plmain.pono) as pono,pldetail.uniqueln,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No 
						,isnull(sodetail.uniq_key,space(10))as Uniq_key
						,case when @lcCustPn = 'No' then isnull(inventor.PART_NO,SPACE(25)) else isnull(i2.CUSTPARTNO,inventor.part_no) end as PartNO
						,case when @lcCustPn = 'No' then ISNULL(inventor.revision,space(8)) else ISNULL(i2.CUSTREV,inventor.revision) end as Rev
						--,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev	--06/23/2015 DRP:  replaced by the above. 
						,ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript,inventor.part_class,inventor.part_type,pldetail.shippedqty,plmain.SHIPDATE,s.SHIPTO,
						 rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
							CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
							CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end+
							case when s.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(s.PHONE) else '' end+
							case when s.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(s.FAX) else '' end  as ShipToAddress
						--,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
						--,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3		
						--,case when s.address2 <> '' then s.country else '' end as ShipAdd4		--05/01/2015 DRP:  replaced with the above ShipToAddress. 
						--,isnull(i2.CUSTPARTNO,'') as CUSTPARTNO,ISNULL(i2.CUSTREV,'') AS CUSTREV
						--, CAST (1 as numeric (3,0))as LabelQty  --05/04/17 DRP replaced with below
						,case when @lcLabelQty is null then 1 else @lcLabelQty end as LabelQty
						
				from	plmain
						left outer join SOMAIN on plmain.SONO = somain.SONO
						inner join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
						left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
						left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
						left outer join SHIPBILL as S on plmain.LINKADD = s.LINKADD
						left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO		--05/01/2015 DRP:  Added for CustPartNo
			)

INSERT @tResults
select * from zInfo

Select * from @tResults
		
where	PACKLISTNO = dbo.PADL(@lcPackListNo,10,0)
		--and Line_No = CASE WHEN Uniq_key=' ' THEN @lcLineNo ELSE dbo.PADL(@lcLineNo,7,0) END	--04/27/2015 DRP:  REMOVED
		
		
end