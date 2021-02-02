
-- =============================================
-- Author:			Debbie
-- Create date:		01/09/2014
-- Description:		Compiles the details for the AP Checks 1099 Form
-- Used On:			ck1099
-- Modifications:	
-- =============================================
CREATE PROCEDURE  [dbo].[rptCheck1099]

 @lcYear as char(4) = ''					--Fiscal Year is entered here
,@lcUniqSupno as varchar(max) = 'All'	--supplier Selection
,@UserId uniqueidentifier =NULL			-- userid for security


as
Begin

--This is needed in order for the WebManex to be able to select more than one Supplier Record from a list. 
DECLARE @Sup TABLE (UniqSupNo char(10))
			IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo <>'All'
				INSERT INTO @Sup SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')	



--populates the Starting and Ending dates for the Year selected
declare @lcDateStart Date = null,	
		@lcDateEnd Date = null		
select @lcDateStart = @lcYear + '0101'
select @lcDateEnd = @lcYear + '1231'



--Gathers the AP Check records for the suppliers that have been flagged as 1099
select	supinfo.SUPNAME,apchkmst.CHECKDATE,apchkmst.CHECKNO,apchkmst.CHECKAMT
		,rtrim(shipbill.Address1)+case when shipbill.address2<> '' then char(13)+char(10)+rtrim(shipbill.address2) else '' end+
		CASE WHEN shipbill.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipbill.City)+',  '+rtrim(shipbill.State)+'      '+RTRIM(shipbill.zip)  ELSE '' END +
		CASE WHEN shipbill.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(shipbill.Country) ELSE '' end+
		case when shipbill.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(shipbill.PHONE) else '' end+
		case when shipbill.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(shipbill.FAX) else '' end  as SupplierAddress
		,shipbill.PHONE,shipbill.FAX,supinfo.SUPID
from	SUPINFO
		inner join APCHKMST on supinfo.UNIQSUPNO = apchkmst.UNIQSUPNO
		inner join SHIPBILL on supinfo.R_LINK = Shipbill.LinkAdd
where	supinfo.PO1099 = 1	
		and left(apchkmst.STATUS,4) <> 'Void'
		and DATEDIFF(Day,apchkmst.CHECKDATE,@lcDateStart)<=0 AND DATEDIFF(Day,apchkmst.CHECKDATE,@lcDateEnd)>=0
		and 1 = case when @lcUniqSupno = 'All' then 1 when supinfo.UNIQSUPNO IN(select UniqSupno from @Sup) then 1 else 0 end  
order by Supinfo.SUPNAME,Apchkmst.CHECKDATE,apchkmst.CHECKNO

end

		

	