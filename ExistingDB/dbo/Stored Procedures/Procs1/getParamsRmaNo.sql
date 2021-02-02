-- =============================================
-- Author:		Debbie	
-- Create date:	08/14/2014
-- Description:	procedure to get list of RMA order numbers used for the report's parameters
--	
-- =============================================
create PROCEDURE [dbo].[getParamsRmaNo] 

	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier = null

AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select  top(@top) sono as Value, SUBSTRING(sono,PATINDEX('%[^0]%',sono + ' '),LEN(sono)) AS Text 
		from	SOMAIN 
		WHERe	IS_RMA = 1
				and 1 = case when @paramFilter is null then 1 else case when sono like '%'+ @paramFilter+ '%' then 1 else 0 end end
		
	else
		select distinct	sono as Value, SUBSTRING(sono,PATINDEX('%[^0]%',sono + ' '),LEN(sono)) AS Text
		from	SOMAIN 
		WHERe	IS_RMA = 1
				and 1 = case when @paramFilter is null then 1 else case when sono like '%' +@paramFilter+ '%' then 1 else 0 end end

		
END


