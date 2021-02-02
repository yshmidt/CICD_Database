-- =============================================
-- Author:		Debbie	
-- Create date:	08/13/2014
-- Description:	procedure to get list of ECO Numbers used for the report's parameters
-- =============================================
create PROCEDURE [dbo].[getParamsEcoNo] 

	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select top(@top) econo as Value, SUBSTRING(econo,PATINDEX('%[^0]%',ECONO + ' '),LEN(ECONO)) AS Text 
		from	ECMAIN 
		WHERE	 1 = case when @paramFilter is null then 1 else case when econo like '%'+@paramFilter+ '%' then 1 else 0 end end
		ORDER BY ECONO
			
	else
		select	econo as Value, SUBSTRING(econo,PATINDEX('%[^0]%',ECONO + ' '),LEN(ECONO)) AS Text 
		from	ecmain 
		WHERE	1 = case when @paramFilter is null then 1 else case when econo like '%'+@paramFilter+ '%' then 1 else 0 end end
		ORDER BY econo
		
END


