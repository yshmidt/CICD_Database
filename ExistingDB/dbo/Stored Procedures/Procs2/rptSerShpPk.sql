-- =============================================
-- Author:		Debbie
-- Create date: 02/02/2012
-- Description:	This Stored Procedure was created for the Serial Number Ship History
-- Reports Using Stored Procedure:  sershppk.rpt
-- Modified:	11/05/2012 DRP:  I used to have the parameter named:  lcPkNo, but to match other procedures/reports and work with the option tab, I changed the parameter name to @lcPackListNo 
--				11/03/15 DRP:  added the /*CUSTOMER LIST*/ and the @userId
-- =============================================
CREATE PROCEDURE [dbo].[rptSerShpPk]
--DECLARE
		@lcPackListNo char(10) = ''
		,@userId uniqueidentifier= null
		
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
where	PACKLSER.PACKLISTNO = dbo.padl(@lcPackListNo,10,'0')
		and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=plmain.custno)
end
			