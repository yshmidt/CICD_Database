-- =============================================
-- Author:		Debbie	
-- Create date:	03/18/2015
-- Description:	procedure to get list of Open Orders used for the report's parameters
-- Modifaction: 
-- =============================================
create PROCEDURE [dbo].[getParamsOpenPO] 


--declare
	@paramFilter varchar(200) = null		--- first 3+ characters entered by the user
	,@top int = null							-- if not null return number of rows indicated
	,@userId uniqueidentifier = null

AS
BEGIN

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
--select * from @tSupplier



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select top(@top) PONUM as Value, SUBSTRING(ponum,PATINDEX('%[^0]%',ponum + ' '),LEN(ponum))  AS Text 
		from	pomain 
		WHERE	POSTATUS in ('OPEN')
				and 1 = case when @paramFilter is null then 1 else case when PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
				and  exists (select 1 from @tSupplier t  where t.uniqsupno=pomain.uniqsupno)
		ORDER BY PONUM
			
	else
		select	PONUM as Value, SUBSTRING(ponum,PATINDEX('%[^0]%',ponum + ' '),LEN(ponum)) AS Text 
		from	POMAIN 
		WHERE	POSTATUS in ('OPEN') 
				and 1 = case when @paramFilter is null then 1 else case when PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
				and  exists (select 1 from @tSupplier t  where t.uniqsupno=pomain.uniqsupno)
		ORDER BY PONUM
		
END