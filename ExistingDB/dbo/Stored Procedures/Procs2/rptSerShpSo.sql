-- =============================================
-- Author:		Debbie
-- Create date:	02/02/2012
-- Description:	This Stored Procedure was created for the Serial Number Ship History by Sales Order
-- Reports:		 sershpso.rpt
-- Modified:		11/04/15 DRP:  Added the @userId and /*CUSTOMER LIST*/
-- =============================================
CREATE PROCEDURE [dbo].[rptSerShpSo]
--DECLARE
		@lcSoNo char(10) = ''
		,@lcDateStart as smalldatetime= NULL
		,@lcDateEnd as smalldatetime = NULL
		,@userId uniqueidentifier= NULL
		
AS 
BEGIN

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	

/*RECORD SELECTION*/
SELECT	SODETAIL.uniq_key,Part_no, Revision, Part_class, Part_type, Descript, Sodetail.Sono, Packlser.Packlistno,LINE_NO, ShipDate
		,cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) as SerialNo 
FROM	Packlser
		inner join sodetail on PACKLSER.UNIQUELN = sodetail.UNIQUELN
		inner join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		inner join PLMAIN  on packlser.PACKLISTNO = plmain.PACKLISTNO
where	PLMAIN.sono = dbo.padl(@lcSoNo,10,'0')
		and plmain.SHIPDATE>=@lcDateStart AND plmain.SHIPDATE<@lcDateEnd+1
		and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=plmain.custno)
end
			