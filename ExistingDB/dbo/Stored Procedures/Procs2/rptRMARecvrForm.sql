
-- =============================================
-- Author:		<Vicky Lu> 
-- Create date: <08/05/2013>
-- Description:	<RMA receiver form report>
-- Reports:     <used on RMA Receiver report>
-- Modified:	08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
--				03/01/14 DRP: Changed how the address information is gathered. 
--				03/03/14 DRP: Changed the ordqty to be an abs value (positive)
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptRMARecvrForm] 
	@lcPackListNo char(10) = ' '
	,@userId uniqueidentifier=null



AS
BEGIN
---08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
-- 07/16/18 VL changed custname from char(35) to char(50)
Declare @tResults table	(PackListNo char(10),CustNo char (10),CustName char (50),PoNo char (20),SoNo char(10),RecvDate smalldatetime
						,OrderDate smalldatetime,Line_No char (7),sortby char(7),Uniq_key char(10),PartNo char (25),Rev char (8)
						,Descript char (45),CustPartNo char(35),CustRev char (8),CDescript char(45),UofM char (4),OrdQty numeric (12,2)
						,RecvQty numeric (12,2),Balance numeric (12,2), SerialNo varchar (max),Attn varchar (200),Rmar_Foot text
						,ShipFrom char (40),ShipFromAddress varchar(max), CreditTo char(40),CreditFromAddress varchar(max)
		/*03/01/14 DRP:	,ShipAdd1 char (40),ShipAdd2 char (40),ShipAdd3 char (40),ShipAdd4 char (40)*/
		/*03/01/14 DRP:	,BillAdd1 char (40),BillAdd2 char(40),BillAdd3 char (40), BillAdd4 char(40)*/
						,FOB char (15),ShipVia char (15), BillAccount char (20),WayBill char (20),LotCode char (15),ExpDate smalldatetime
						,Reference char(12),LotQty numeric (12,2))

SET @lcPackListNo=dbo.PADL(@lcPacklistno,10,'0')
;
with
--this section will go through and compile any Serialno information
CmSerial AS
	  (
	  SELECT CAST(DBO.fRemoveLeadingZeros(CS.Serialno) as bigint) as iSerialno,CS.packlistno,CS.UNIQUELN   
	  FROM CmSer CS
	  where CS.PACKLISTNO = @lcPackListNo
	  AND PATINDEX('%[^0-9]%',CS.serialno)=0 
	  )
	  ,startingPoints as
	  (
	  select A.*, ROW_NUMBER() OVER(PARTITION BY A.packlistno,uniqueln ORDER BY iSerialno) AS rownum
	  FROM CmSerial AS A WHERE NOT EXISTS (SELECT 1 FROM CmSerial AS B WHERE B.iSerialno=A.iSerialno-1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN )
	  )
	 --SELECT * FROM StartingPoints  
	,
	EndingPoints AS
	(
	select A.*, ROW_NUMBER() OVER(PARTITION BY packlistno,uniqueln ORDER BY iSerialno) AS rownum
	FROM CmSerial AS A WHERE NOT EXISTS (SELECT 1 FROM CmSerial AS B WHERE B.iSerialno=A.iSerialno+1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN) 
	)
	--SELECT * FROM EndingPoints
	,
	StartEndSerialno AS 
	(
	SELECT S.*,S.iSerialno AS start_range, E.iSerialno AS end_range
	FROM StartingPoints AS S
	JOIN EndingPoints AS E
	ON E.rownum = S.rownum and E.PACKLISTNO = S.PACKLISTNO and E.UNIQUELN =S.UNIQUELN 
	)
	,FinalSerialno AS
	(
	SELECT CASE WHEN A.start_range=A.End_range
			THEN CAST(RTRIM(CONVERT(char(30),A.start_range))  as varchar(MAX)) ELSE
			CAST(RTRIM(CONVERT(char(30),A.start_range))+'-'+RTRIM(CONVERT(char(30),A.End_range)) as varchar(MAX)) END as Serialno,
			packlistno,uniqueln
	FROM StartEndSerialno  A
	UNION 
	SELECT CAST(DBO.fRemoveLeadingZeros(CS.Serialno) as varchar(max)) as Serialno,CS.packlistno,CS.UNIQUELN  
		from CmSer CS 
		where CS.PACKLISTNO = @lcPackListNo
		and (CS.Serialno LIKE '%[a-z]%' OR PATINDEX('%[^0-9A-Za-z]%',CS.serialno)<>0) 
	)
	--select * from FinalSerialno

--This section will then gather all other Packing list information and also include the Serial Number information from above.
,
---08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
PackList as (    
	select	Cmmain.PACKLISTNO,Cmmain.CUSTNO,CUSTNAME,ISNULL(SOMAIN.PONO,SPACE(20)) AS PONO,ISNULL(somain.sono,space(10))as SONO,RecvDate,ORDERDATE
		,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(CmDetail.uniqueln as CHAR (10))) as Line_No
		,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(CmDetail.uniqueln,2,6)),6,'0')) as sortby
		,isnull(sodetail.uniq_key,space(10))as Uniq_key
		,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev
		,ISNULL(CASt(Inventor.Descript AS CHAR(45)),ISNULL(CAST(Sodet_Desc AS CHAR(45)),CAST(cmDescr AS CHAR(45)))) AS Descript
		--,ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript
		,ISNULL(i2.custpartno,SPACE(25)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (45)),cast (Cmdetail.cmdescr as CHAR(45))) as CDescript
		,Cmdetail.UOFMEAS
/*03/03/2014 DRP:,case when Cmmain.SONO = '' then Cmdetail.SHIPPEDQTY else sodetail.ORD_QTY end as OrdQty*/
		,case when Cmmain.SONO = '' then Cmdetail.SHIPPEDQTY else abs(sodetail.ORD_QTY) end as OrdQty
		,Cmdetail.CMQTY AS RecvQty,Sodetail.Balance
		,CAST(stuff((select','+CS.Serialno	from FinalSerialno CS
											where	CS.PACKLISTNO = Cmmain.PACKLISTNO
													AND CS.UNIQUELN = Cmdetail.UNIQUELN
											ORDER BY SERIALNO FOR XML PATH ('')),1,1,'') AS VARCHAR (MAX)) AS Serialno
		,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn,Cmmain.Rmar_FOOT
		,s.SHIPTO as ShipFrom
/*03/01/14 DRP:	,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
		,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
		,case when s.address2 <> '' then s.country else '' end as ShipAdd4*/	
		,rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
		CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
		CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end+
		case when s.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(s.PHONE) else '' end+
		case when s.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(s.FAX) else '' end  as ShipFromAddress
		,b.SHIPTO as CreditTo
/*03/01/14 DRP:	,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
		,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
		,case when b.address2 <> '' then b.country else '' end as BillAdd4*/
		,rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+
		CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +
		CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end+
		case when b.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(b.PHONE) else '' end+
		case when b.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(b.FAX) else '' end  as CreditToAddress
		,Cmmain.FOB,Cmmain.SHIPVIA,S.BILLACOUNT,Cmmain.WAYBILL, Cminvlot.LOTCODE,Cminvlot.expdate,CmINVLOT.REFERENCE,Cminvlot.ALLOCQTY
		
		FROM Cmmain
		inner join CUSTOMER on Cmmain.CUSTNO = customer.CUSTNO
		LEFT OUTER JOIN SOMAIN ON Cmmain.SONO = SOMAIN.SONO
		left outer join Cmdetail on Cmmain.PACKLISTNO = Cmdetail.PACKLISTNO
		left outer join SODETAIL on Cmdetail.UNIQUELN = sodetail.UNIQUELN
		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ
		left outer join CCONTACT on Cmmain.attention = ccontact.cid
		LEFT outer join SHIPBILL as S on Cmmain.LINKADD = s.LINKADD
		left outer join SHIPBILL as B on Cmmain.BLINKADD = B.LINKADD 		
		left outer join CMALLOC on Cmdetail.PACKLISTNO = CMALLOC.PACKLISTNO and Cmdetail.UNIQUELN = CMALLOC.UNIQUELN
		left outer join CMINVLOT on CMALLOC.PACKLISTNO = CMALLOC.PACKLISTNO and CMALLOC.UNIQ_ALLOC = CMINVLOT.UNIQ_ALLOC
		WHERE Cmmain.PACKLISTNO = @lcPackListNo

	)
 
INSERT @tResults
select * from PackList

Select * from @tResults 
	
end