
-- =============================================
-- Author:		Debbie Peltier
-- Create date: 06/27/2013
-- Description:	This Stored Procedure was created to gather the Serial Number and Lot Code detail to be displayed within the  Bar Code Addendum subreport to follow the Packing List form
-- Reports:		pkaddndm.rpt
-- Modified: 01/15/2014 DRP:  added the @userid parameter for WebManex
--		   : 03/12/2014 DRP:  increased the Line_no char(7) to Line_no char(10)
--		   : 02/09/15 YS change iserialno to be varchar(max) when serial number is alpha numeric
--		   : 06/23/2015 DRP:  Added the CustPartNo and CustRev to the results so that if the users selects to display Customer part number instead that the Bar Code Addendum would properly display the CustPartno Also
--		   : 10/25/2017:Satish B : Convert inventor.revision into uppercase as Code 39 is not able to scan lowercase charactors
--		   : 03/01/18 YS lotcode size change to 25
--		   : 06/8/2018 : Satish B : Added IpKey in @tResults
--		   : 06/8/2018 : Satish B : Insert Iempty IpKey into @tResults 
--		   : 06/8/2018 : Satish B : Get sid details against each line item
--		   : 06/8/2018 : Satish B : Select IpKey from @tResults 
-- exec rptPackListBarCodeSubReport '0000000693'
-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptPackListBarCodeSubReport]
--declare
 @lcPackListNo char(10) = ''
 ,@userId uniqueidentifier=null


as
begin

--re-assignes the leading zero's to the packing list number
SET @lcPackListNo=dbo.PADL(@lcPacklistno,10,'0')
-- 09/26/19 YS changed part no and cust part no from char(25) to char(35)
Declare @tResults table	(PoNo char (20),PackListNo char(10),SoNo char(10),ShipDate smalldatetime
						,Line_no char (10) /*03/12/2014 DRP: ,Line_No char (7)*/
						, SortBy char(7),uniqueln char(10),ShippedQty numeric (12,2)
						--03/01/18 YS lotcode size change to 25
            ,PartNo char (25),Rev char (8),Descript char(45), Type char(8),SerialNo varchar (max),LotCode char (25),ExpDate smalldatetime,Reference char(12), pkinvlot char(10)
						,CustPartNo char(35),CustRev char (8)
						-- 06/8/2018 : Satish B : Added IpKey in @tResults
						,IpKey VARCHAR(MAX))

--Then the below will then only insert lot code detail pertaining to the selected packing list
insert into @tResults
select	somain.PONO,plmain.PACKLISTNO,plmain.SONO,plmain.SHIPDATE,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
		,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby
		,pldetail.UNIQUELN,pldetail.SHIPPEDQTY,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev,ISNULL(pldetail.cDESCR,SPACE(45))as Descript
		, CAST('Lot Code' as CHAR(8)) as Type
		, cast ('' as varchar(max)) as iSerialno
		,isnull(pkinvlot.LOTCODE,'')as LotCode,isnull(pkinvlot.expdate,'') as ExpDate ,isnull(PKINVLOT.REFERENCE,'') as Reference,isnull(PKINVLOT.UKPKINVLOT,'') as pkinvlot
		,isnull(i2.custpartno,space(25)) as CustPartNo
		,isnull(i2.custrev,space(8)) as CustRev
		-- 06/8/2018 : Satish B : Insert Iempty IpKey into @tResults 
		,'' AS IpKey
from	PLMAIN
		LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO 
		left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
		left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join PKALLOC on pldetail.PACKLISTNO = PKALLOC.PACKLISTNO and pldetail.UNIQUELN = PKALLOC.UNIQUELN
		left outer join PKINVLOT on pkalloc.PACKLISTNO = pkalloc.PACKLISTNO and pkalloc.UNIQ_ALLOC = PKINVLOT.UNIQ_ALLOC
		left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO
Where	plmain.PACKLISTNO = @lcPackListNo


--this section will first only gather any serial number information for selected packing list
insert into @tResults 
select	somain.PONO,plmain.PACKLISTNO,plmain.SONO,plmain.SHIPDATE,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
		,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby
		,pldetail.UNIQUELN,pldetail.SHIPPEDQTY,isnull(inventor.PART_NO,SPACE(25)) as PartNO,
		--10/25/2017 Satish B : Convert inventor.revision into uppercase as Code 39 is not able to scan lowercase charactors
		UPPER(ISNULL(inventor.revision,space(8))) as Rev,ISNULL(pldetail.cDESCR,SPACE(45))as Descript
		, CAST ('Serial' as CHAR(8)) as Type
		,(CAST(DBO.fRemoveLeadingZeros(PACKLSER.Serialno) as varchar(max))) as iSerialno
		 --03/01/18 YS lotcode size change to 25
		,CAST ('' as CHAR(25)) as LotCode
		,CAST ('' as smalldatetime) as expdate
		,cast ('' as char(12)) as REFERENCE
		,cast ('' as char(10)) as UKPKINVLOT
		,isnull(i2.custpartno,space(25)) as CustPartNo
		,isnull(i2.custrev,space(8)) as CustRev
		-- 06/8/2018 : Satish B : Insert Iempty IpKey into @tResults 
		,'' AS IpKey
from	PLMAIN
		LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO 
		left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
		left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join PACKLSER on plmain.PACKLISTNO = packlser.PACKLISTNO and pldetail.UNIQUELN = PACKLSER.UNIQUELN
		left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO
Where	plmain.PACKLISTNO = @lcPackListNo

-- 06/8/2018 : Satish B : Get sid details against each line item
--This section get sid info
insert into @tResults
select	somain.PONO,plmain.PACKLISTNO,plmain.SONO,plmain.SHIPDATE,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
		,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby
		,pldetail.UNIQUELN,pldetail.SHIPPEDQTY,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev,ISNULL(pldetail.cDESCR,SPACE(45))as Descript
		, CAST('Sid' as CHAR(8)) as Type
		, cast ('' as varchar(max)) as iSerialno
		,isnull(pkinvlot.LOTCODE,'')as LotCode,isnull(pkinvlot.expdate,'') as ExpDate ,isnull(PKINVLOT.REFERENCE,'') as Reference,isnull(PKINVLOT.UKPKINVLOT,'') as pkinvlot
		,isnull(i2.custpartno,space(25)) as CustPartNo
		,isnull(i2.custrev,space(8)) as CustRev
		,ISNULL(p.FK_IPKEYUNIQUE,'') AS IpKey
from	PLMAIN
		LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO 
		left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
		left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join PKALLOC on pldetail.PACKLISTNO = PKALLOC.PACKLISTNO and pldetail.UNIQUELN = PKALLOC.UNIQUELN
		left outer join PKINVLOT on pkalloc.PACKLISTNO = pkalloc.PACKLISTNO and pkalloc.UNIQ_ALLOC = PKINVLOT.UNIQ_ALLOC
		left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO
		LEFT OUTER JOIN pldtlipkey p on p.FK_INV_LINK=pldetail.INV_LINK
Where	plmain.PACKLISTNO = @lcPackListNo

--select * from @tResults
select PoNo,PackListNo,SoNo,ShipDate,Line_No,sortby,uniqueln,ShippedQty,PartNo,Rev,Descript, Type,isnull(SerialNo,'') as SerialNo,LotCode,ExpDate,Reference,
   -- 06/8/2018 : Satish B : Select IpKey from @tResults 
		pkinvlot,CustPartNo,CustRev,IpKey from @tResults
end