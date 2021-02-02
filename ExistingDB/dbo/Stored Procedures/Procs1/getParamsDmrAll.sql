-- =============================================
-- Author:		Debbie	
-- Create date:	11/09/2015
-- Description:	procedure to get list of DMR's the user is approved to see for the report's parameters
-- Modifaction: 
-- =============================================
create PROCEDURE [dbo].[getParamsDmrAll] 

--declare

	@paramFilter varchar(200) = null,		--- first 3+ characters entered by the user
	@top int = null							-- if not null return number of rows indicated
	,@userId uniqueidentifier = null

AS
BEGIN

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
--select * from @tSupplier



	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select top(@top) dmr_no as Value, SUBSTRING(DMR_NO,PATINDEX('%[^0]%',DMR_NO + ' '),LEN(DMR_NO))  AS Text 
		from	porecmrb 
				LEFT OUTER JOIN PORECDTL ON PORECMRB.FK_UNIQRECDTL = PORECDTL.UNIQRECDTL
				LEFT OUTER JOIN POITEMS ON PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO
				LEFT OUTER JOIN POMAIN ON POITEMS.PONUM = POMAIN.PONUM
				LEFT OUTER JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO	
				inner join @tSupplier C on supinfo.uniqsupno = c.uniqsupno	
		WHERE	1 = case when @paramFilter is null then 1 else case when DMR_NO like '%'+@paramFilter+ '%' then 1 else 0 end end
				
		ORDER BY DMR_NO
			
	else
		select dmr_no as Value, SUBSTRING(DMR_NO,PATINDEX('%[^0]%',DMR_NO + ' '),LEN(DMR_NO))  AS Text 
		from	porecmrb 
				LEFT OUTER JOIN PORECDTL ON PORECMRB.FK_UNIQRECDTL = PORECDTL.UNIQRECDTL
				LEFT OUTER JOIN POITEMS ON PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO
				LEFT OUTER JOIN POMAIN ON POITEMS.PONUM = POMAIN.PONUM
				LEFT OUTER JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO	
				inner join @tSupplier C on supinfo.uniqsupno = c.uniqsupno	
		WHERE	1 = case when @paramFilter is null then 1 else case when DMR_NO like '%'+@paramFilter+ '%' then 1 else 0 end end
				and 1 = case when supinfo.uniqsupno in (select uniqsupno from @tSupplier) then 1 else 0 end
		ORDER BY DMR_NO
		
END