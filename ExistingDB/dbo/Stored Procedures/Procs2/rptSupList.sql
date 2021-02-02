
-- =============================================
-- Author:	Debbie
-- Create date: 01/08/2015
-- Description:	This was created for Supplier Information report (suplist)
-- Modified:		01/12/2015:  it was brought to my attention that I forgot to inlcude the Attention and Contname fields in the output.  
--				01/23/2015:  I originally did not take into consideration that they could have more than one address related to Remit or Confirm To.  
--							 had to also take into consideration where the Supplier exist but does not have any corresponding Address records. 
--							 Added the ShipTo title in the case where the Ship To happen to be different from the Supplier itself. 
--							 completely removed the --GATHERS THE CONFIRM INFORMATION-- section because I needed to put it into the one section.
-- 07/16/18 VL changed supname from char(30) to char(50)
-- =============================================

CREATE PROC [dbo].[rptSupList]

--declare
 @lcUniqSupNo as varchar(max) = 'All'	--This is newly added for Cloud and did not exist in VFP.  I figured it would be nice for the users to be able to run the results for selected suppliers. 
,@supplierStatus char(20) = 'All'	--This is needed to show all of the suppliers, will be included in the CloudParameters so the users can control the status of the suppliers that are displayed. 
,@userId uniqueidentifier= null


AS
BEGIN

/*SUPPLIER LIST*/
	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus;
	
	--- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
		insert into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	--- empty or null customer or part number means no selection were made
	IF  @lcUniqSupNo='All'	
	BEGIN
		INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier	
	
	END	

/*SELECT STATEMENT*/

------------------------------------
--GATHERS THE SUPPLIER INFORMATION--
------------------------------------
-- 07/16/18 VL changed supname from char(30) to char(50)
declare @tSup table (uniqsupno char(10),supid char(10),supname char(50),supprefx char(4),Phone char(19),Fax char(19),[Status] char(16),R_LINK CHAR(10),C_LINK CHAR(10))

INSERT INTO @TSUP 
		select	UNIQSUPNO,SUPID,SUPNAME,SUPINFO.SUPPREFX,supinfo.PHONE,supinfo.FAX,SUPINFO.STATUS,R_LINK,C_LINK
		from	supinfo
		where	1= case WHEN supinfo.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END

------------------------------------
--GATHERS THE REMIT/CONFIRM TO INFORMATION--
------------------------------------
select	S1.UNIQSUPNO,S1.SUPID,S1.SUPNAME,S1.SUPPREFX,S1.PHONE,S1.FAX
		,isnull(rtrim(R.Shipto)+ char(13)+char(10)+rtrim(R.ADDRESS1)+case when R.ADDRESS2<> '' then char(13)+char(10)+rtrim(R.address2) else '' end+
			CASE WHEN R.CITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(R.CITY)+',  '+rtrim(R.State)+'      '+RTRIM(R.zip)  ELSE '' END +
			CASE WHEN R.COUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(R.COUNTRY) ELSE '' END,'') AS LAddress
		,isnull(R.Phone,'')as LPhone,isnull(R.Fax,'') as LFax,isnull(R.E_MAIL,'') as LEmail
		,S1.STATUS,isnull(r.RECORDTYPE,'') as Recordtype,isnull(ATTENTION,'') as Attention,ISNULL(RTRIM(LASTNAME)+', '+RTRIM(FIRSTNAME),'') AS CONTNAME
from	@tSup AS S1
		--left outer join	SHIPBILL R ON S1.SUPID = R.CUSTNO AND S1.R_LINK = R.LINKADD	--01/23/2015 DRP:  replaced by the below
		left outer join	(select * from SHIPBILL where RECORDTYPE in('R','C')) R ON S1.SUPID = R.CUSTNO
		left outer join CCONTACT on LEFT(rtrim(R.attention),10) = CCONTACT.cid

order by supname,Recordtype

/*01/23/2015 DRP:  Completely removed the below section. It can be included within the above changes */
/*
--UNION all
-------------------------------------
----GATHERS THE CONFIRM INFORMATION--
-------------------------------------
--select	S2.UNIQSUPNO,S2.SUPID,S2.SUPNAME,S2.SUPPREFX,S2.PHONE,S2.FAX
--		,isnull(rtrim(C.Shipto)+ char(13)+char(10)+rtrim(C.ADDRESS1)+case when C.ADDRESS2<> '' then char(13)+char(10)+rtrim(C.address2) else '' end+
--			CASE WHEN C.CITY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(C.CITY)+',  '+rtrim(C.State)+'      '+RTRIM(C.zip)  ELSE '' END +
--			CASE WHEN C.COUNTRY<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(C.COUNTRY) ELSE '' END,'') AS LAddress
--		,isnull(C.Phone,'')as LPhone,isnull(C.Fax,'') as LFax,isnull(C.E_MAIL,'') as LEmail
--		,S2.STATUS,isnull(c.RECORDTYPE,'')as RecordType,isnull(ATTENTION,'') as Attention--,ISNULL(RTRIM(LASTNAME)+', '+RTRIM(FIRSTNAME),'') AS CONTNAME
--from	@tSup AS S2
--		--LEFT OUTER JOIN SHIPBILL C ON S2.SUPID = C.CUSTNO AND S2.C_LINK = C.LINKADD	--01/23/2015 DRP:  replaced by the following 
--		LEFT OUTER JOIN (select * from SHIPBILL where RECORDTYPE = 'C')  C ON S2.SUPID = C.CUSTNO 
--		left outer join CCONTACT on LEFT(rtrim(c.attention),10) = CCONTACT.cid
*/

END