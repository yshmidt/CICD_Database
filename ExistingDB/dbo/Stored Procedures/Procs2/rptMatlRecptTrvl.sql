
-- =============================================
-- Author:		<Debbie>
-- Create date: <11/29/2011>
-- Description:	<Compiles the data for Material Receipt Traveler Report>
-- Used On:     <Crystal Report {porectrv.rpt} 
-- Modified:	10/19/2012 DRP:  Vicky helped me find that since I was adding the MICSSYS within the Crystal Report rather than within the SP below that it was causing the SP to be ran twice.
--								  Since it was being ran twice in CR it was causing the table to be updated and the final results would be a blank report because the field was updated the first time through. 
-- 04/14/15 YS Location length is changed to varchar(256)
--				11/04/15 DRP:  added the @userId  removed MICSSYS
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE [dbo].[rptMatlRecptTrvl]

@userId uniqueidentifier= NULL


AS
begin
-- 04/14/15 YS Location length is changed to varchar(256)
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @tResult table	(uniqrecdtl char(10),poittype char(9),part_no char(35),rev char(8),Descript char(45),part_class char(8),part_type char(8),ponum char (15)
						,accptqty numeric(10,2),receiverno char(10),requesttp char (10),requestor char (50),woprjnumber char (10),warehouse char (6),location varchar(256))

INSERT @tResult  select	uniqrecdtl,poitems.POITTYPE
		,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
		,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
		,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
		,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
		,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
		,POITEMS.ponum,porecloc.ACCPTQTY,porecdtl.RECEIVERNO,REQUESTTP,REQUESTOR,WOPRJNUMBER,WAREHOUS.WAREHOUSE, porecloc.LOCATION
	 
from	PORECDTL
		inner join poitems on poitems.UNIQLNNO = PORECDTL.UNIQLNNO
		left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
		LEFT OUTER JOIN PORECLOC ON PORECDTL.UNIQRECDTL = PORECLOC.FK_UNIQRECDTL
		LEFT OUTER JOIN POITSCHD ON PORECLOC.UNIQDETNO = POITSCHD.UNIQDETNO
		left outer join WAREHOUS on PORECLOC.UNIQWH = warehous.UNIQWH

where	porecdtl.IS_PRINTED <>1

--10/19/2012 DRP:  Below added the miscssys information to the SP results and removed it from the CR 
--select R1.*,Micssys.LIC_NAME from @tResult as R1 cross join MICSSYS --11/04/15 DRP:  replaced with the below. 
select * from @tresult

update PORECDTL set IS_PRINTED = 1 where UNIQRECDTL in (select UNIQRECDTL from @tResult)




		

end