-- =============================================
-- Author:		Debbie	
-- Create date:	11/12/2015
-- Description:	procedure to get list of serial numbers associated with MAKE product used for the report's parameters
-- Modified:	
-- =============================================
create PROCEDURE [dbo].[getParamsSerialNo4Make] 

--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier = null

AS
BEGIN

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
		--SELECT * FROM @tCustomer	
		


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select  top(@top) serialuniq as Value, SUBSTRING(serialno,PATINDEX('%[^0]%',SERIALNO + ' '),LEN(SERIALNO))+':: '+RTRIM(PART_NO)+ CASE WHEN INVENTOR.REVISION <> '' THEN ' | ' + rtrim(Inventor.REVISION) ELSE '' END AS Text 
		FROM	INVTSER
				INNER JOIN INVENTOR ON INVTSER.UNIQ_KEY = INVENTOR.UNIQ_KEY
				inner join WOENTRY on invtser.WONO = woentry.WONO
		WHERe	 1 = case when @paramFilter is null then 1 else case when serialno like '%'+ @paramFilter+ '%' then 1 else 0 end end
				and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=WOENTRY.custno)

		
	else
		select distinct	serialuniq as Value, SUBSTRING(serialno,PATINDEX('%[^0]%',SERIALNO + ' '),LEN(SERIALNO))+':: '+RTRIM(PART_NO)+ CASE WHEN inventor.REVISION <> '' THEN ' | ' + rtrim(inventor.REVISION) ELSE '' END AS Text 
		FROM	INVTSER
				INNER JOIN INVENTOR ON INVTSER.UNIQ_KEY = INVENTOR.UNIQ_KEY
				inner join WOENTRY on invtser.WONO = woentry.WONO
		WHERe	 1 = case when @paramFilter is null then 1 else case when serialno like '%'+ @paramFilter+ '%' then 1 else 0 end end
				and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=WOENTRY.custno)

		
END