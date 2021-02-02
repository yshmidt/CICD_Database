-- =============================================
-- Author:		Debbie	
-- Create date:	04/17/2015
-- Description:	procedure to get list of Closed only Purchase Orders used for the report's parameters
-- Modifaction: 
-- =============================================
create PROCEDURE [dbo].[getParamsClosedPO] 



	@paramFilter varchar(200) = null,		--- first 3+ characters entered by the user
	@top int = null							-- if not null return number of rows indicated
	,@userId uniqueidentifier = null

AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select top(@top) PONUM as Value, SUBSTRING(ponum,PATINDEX('%[^0]%',ponum + ' '),LEN(ponum))  AS Text 
		from	pomain 
		WHERE	POSTATUS in ('CLOSED')
				and 1 = case when @paramFilter is null then 1 else case when PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
				
		ORDER BY PONUM
			
	else
		select	PONUM as Value, SUBSTRING(ponum,PATINDEX('%[^0]%',ponum + ' '),LEN(ponum)) AS Text 
		from	POMAIN 
		WHERE	POSTATUS in ('CLOSED') 
				--and 1 = case when @paramFilter is null then 1 else case when PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
				and 1 = case when @paramFilter is null then 1 else case when PONUM like '%'+@paramFilter+ '%' then 1 else 0 end end
		ORDER BY PONUM
		
END