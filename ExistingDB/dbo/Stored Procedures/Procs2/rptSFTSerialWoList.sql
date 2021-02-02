
-- =============================================
-- Author:		Debbie
-- Create date: 05/11/2012
-- Description:	This Stored Procedure was created for the Work Order Connected to the Serial Number Report
-- Reports:		woserial.rpt
-- Modified:	11/12/15 DRP:  added @userId, /*CUSTOMRE LIST*/ for it to work with the webmanex
-- =============================================

CREATE PROCEDURE [dbo].[rptSFTSerialWoList]
--declare
			@lcSerialUniq as char(10) = ''
			,@userId uniqueidentifier = null

as 
begin	

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	
		
	
SELECT	INVTSER.SERIALNO,INVTSER.WONO,INVENTOR.PART_NO,INVENTOR.REVISION,woentry.ORDERDATE,OPENCLOS
FROM	INVTSER
		INNER JOIN INVENTOR ON INVTSER.UNIQ_KEY = INVENTOR.UNIQ_KEY
		inner join WOENTRY on invtser.WONO = woentry.WONO
WHERE	 @lcSerialUniq = invtser.serialuniq
		--INVTSER.SERIALNO = dbo.padl(@lcSerialNo,30,'0')	--11/12/15 DRP:  replaced with above
		and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=WOENTRY.custno)


end