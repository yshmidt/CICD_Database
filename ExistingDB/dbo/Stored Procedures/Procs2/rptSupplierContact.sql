
-- =============================================
-- Author:		Debbie
-- Create date: 11/19/15
-- Description:	This Stored Procedure was created for the Supplier Contact
-- Reports:		supcont
-- Modified:	
-- =============================================
create PROCEDURE [dbo].[rptSupplierContact]
--DECLARE

	@lcUniqSupNo varchar(max) = 'All'
	,@userId uniqueidentifier = null

as 
begin

/*SUPPLIER LIST*/
	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'Active';
	
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
select	SUPNAME,SUPPREFX,SUPID,SUPINFO.STATUS,CCONTACT.LASTNAME,CCONTACT.FIRSTNAME,CCONTACT.TITLE,CCONTACT.WORKPHONE,CCONTACT.CONTACTFAX,CCONTACT.EMAIL
from	SUPINFO
		LEFT OUTER JOIN CCONTACT ON SUPINFO.SUPID = CCONTACT.CUSTNO
WHERE	CCONTACT.TYPE = 'S'
		and (@lcUniqSupNo = 'All' or exists (select 1 from @tSupNo t inner join supinfo s on t.Uniqsupno=s.uniqsupno where s.uniqsupno=supinfo.uniqsupno))

		SELECT * FROM CCONTACT
		SELECT * FROM SUPiNFO

end