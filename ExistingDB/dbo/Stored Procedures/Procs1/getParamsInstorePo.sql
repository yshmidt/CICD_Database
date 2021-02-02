-- =============================================
-- Author:		Debbie	
-- Create date:	08/13/2014
-- Description:	procedure to get list of Instore Purchase Order Numbers used for the report's parameters
-- Modified:	09/22/2014 DRP:  Instore Po's would be listed multiple times if multi-items were on the po.  Yelena suggested the below changes. 
-- =============================================
CREATE PROCEDURE [dbo].[getParamsInstorePo] 

	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
 /*09/22/2014 DRP:  replaced the entire selection to help increase speed and also address the duplicate PO listing in the selection box*/
 /*
 --  	if (@top is not null)
	--	select top(@top) pomain.PONUM as Value, SUBSTRING(pomain.ponum,PATINDEX('%[^0]%',pomain.ponum + ' '),LEN(pomain.PONUM)) AS Text 
	--	from	pomain,POITEMS 
	--	WHERE	pomain.ponum = poitems.ponum
	--			and 1 = case when @paramFilter is null then 1 else case when pomain.PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
	--			and poittype = 'In Store'
	--	ORDER BY pomain.ponum
			
	--else
	--	select	pomain.ponum as Value, SUBSTRING(pomain.ponum,PATINDEX('%[^0]%',pomain.ponum + ' '),LEN(pomain.PONUM)) AS Text 
	--	from	pomain,POITEMS 
	--	WHERE	pomain.ponum = poitems.ponum
	--			and 1 = case when @paramFilter is null then 1 else case when pomain.PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
	--			and poittype = 'In Store'
	--	ORDER BY pomain.ponum
*/	

	
		if (@top is not null)
			select  top(@top) pomain.PONUM as Value, SUBSTRING(pomain.ponum,PATINDEX('%[^0]%',pomain.ponum + ' '),LEN(pomain.PONUM)) AS Text 
				from	pomain
				where ponum in (select ponum from poitems where poitems.ponum=pomain.ponum and  poittype = 'In Store') 
			and 1 = case when @paramFilter is null then 1 when pomain.PONUM like '%'+@paramFilter+ '%' then 1 else 0 end 
			ORDER BY pomain.ponum
			
	else
		select  pomain.PONUM as Value, SUBSTRING(pomain.ponum,PATINDEX('%[^0]%',pomain.ponum + ' '),LEN(pomain.PONUM)) AS Text 
				from	pomain
				where pomain.ponum in (select ponum from poitems where poitems.ponum=pomain.ponum and  poittype = 'In Store') 
			and 1 = case when @paramFilter is null then 1 when pomain.PONUM like '%'+@paramFilter+ '%' then 1 else 0 end 
			ORDER BY pomain.ponum
		
END


