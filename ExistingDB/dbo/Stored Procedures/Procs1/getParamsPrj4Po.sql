-- =============================================
-- Author:		Debbie	
-- Create date:	09/25/2014
-- Description:	procedure to get list of projects that are associated to PO item Schedules
-- Modified:	01/06/2015 DRP:  Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[getParamsPrj4Po] 


@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
,@top int = null							-- if not null return number of rows indicated
,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
,@userId uniqueidentifier = null

as
begin

/*CUSTOMER SELECTION LIST*/
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @tCustomer tCustomer
	DECLARE @tCustno tCustno ;
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomer EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;
	INSERT INTO @tCustno SELECT Custno FROM @tCustomer	


if (@top is not null)
	select  top(@top) PJCTMAIN.PRJNUMBER as Value, SUBSTRING(pjctmain.prjnumber,PATINDEX('%[^0]%',pjctmain.prjnumber + ' '),LEN(pjctmain.prjnumber)) AS Text 
	from	PJCTMAIN
	WHERE	PRJNUMBER IN (SELECT WOPRJNUMBER FROM POITSCHD WHERE POITSCHD.WOPRJNUMBER = PJCTMAIN.PRJNUMBER AND REQUESTTP = 'Prj Alloc')
			AND	1= case WHEN pjctmain.CUSTNO IN (SELECT CUSTNO FROM @tCustno) THEN 1 ELSE 0  END
			and 1 = case when @paramFilter is null then 1 when PJCTMAIN.prjnumber like '%'+@paramFilter+ '%' then 1 else 0 end 
	order by PRJNUMBER	

else
	select  PJCTMAIN.PRJNUMBER as Value, SUBSTRING(pjctmain.prjnumber,PATINDEX('%[^0]%',pjctmain.prjnumber + ' '),LEN(pjctmain.prjnumber)) AS Text
	from	PJCTMAIN
	WHERE	PRJNUMBER IN (SELECT WOPRJNUMBER FROM POITSCHD WHERE POITSCHD.WOPRJNUMBER = PJCTMAIN.PRJNUMBER AND REQUESTTP = 'Prj Alloc')
			AND	1= case WHEN pjctmain.CUSTNO IN (SELECT CUSTNO FROM @tCustno) THEN 1 ELSE 0  END
				and 1 = case when @paramFilter is null then 1 when PJCTMAIN.prjnumber like '%'+@paramFilter+ '%' then 1 else 0 end
	order by PRJNUMBER		


end