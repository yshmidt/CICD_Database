-- =============================================
-- Author:		Debbie	
-- Create date:	11/04/2015
-- Description:	procedure to get list of Open or Closed Purchase orders that have had Receipts created against them. 
-- Modifaction: 
-- =============================================
create PROCEDURE [dbo].[getParamsAllPoRecv] 


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
		select distinct top(@top) pomain.PONUM as Value, SUBSTRING(pomain.ponum,PATINDEX('%[^0]%',pomain.ponum + ' '),LEN(pomain.ponum))  AS Text 
		from	pomain
				INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
				inner join PORECDTL on poitems.UNIQLNNO = PORECDTL.UNIQLNNO
		WHERE	POSTATUS not in ('CANCEL','NEW')
				and 1 = case when @paramFilter is null then 1 else case when pomain.PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
				and  exists (select 1 from @tSupplier t  where t.uniqsupno=pomain.uniqsupno)
		ORDER BY pomain.PONUM
			
	else
		select	distinct pomain.PONUM as Value, SUBSTRING(pomain.ponum,PATINDEX('%[^0]%',pomain.ponum + ' '),LEN(pomain.ponum)) AS Text 
		from	pomain
				INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
				inner join PORECDTL on poitems.UNIQLNNO = PORECDTL.UNIQLNNO 
		WHERE	POSTATUS not in ('CANCEL','NEW') 
				and 1 = case when @paramFilter is null then 1 else case when pomain.PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
				and  exists (select 1 from @tSupplier t  where t.uniqsupno=pomain.uniqsupno)
		ORDER BY pomain.PONUM
		
END