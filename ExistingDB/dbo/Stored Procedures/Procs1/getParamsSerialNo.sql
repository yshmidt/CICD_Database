-- =============================================
-- Author:		Debbie	
-- Create date:	08/14/2014
-- Description:	procedure to get list of serial numbers used for the report's parameters
--	
-- =============================================
create PROCEDURE [dbo].[getParamsSerialNo] 

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
		select  top(@top) serialuniq as Value, SUBSTRING(serialno,PATINDEX('%[^0]%',SERIALNO + ' '),LEN(SERIALNO))+':: '+RTRIM(PART_NO)+ CASE WHEN i.REVISION <> '' THEN ' | ' + rtrim(i.REVISION) ELSE '' END AS Text 
		from	INVTSER s INNER JOIN INVENTOR i ON s.uniq_key = i.uniq_key
		WHERe	 1 = case when @paramFilter is null then 1 else case when serialno like '%'+ @paramFilter+ '%' then 1 else 0 end end
		
	else
		select distinct	serialuniq as Value, SUBSTRING(serialno,PATINDEX('%[^0]%',SERIALNO + ' '),LEN(SERIALNO))+':: '+RTRIM(PART_NO)+ CASE WHEN i.REVISION <> '' THEN ' | ' + rtrim(i.REVISION) ELSE '' END AS Text 
		from	INVTSER s INNER JOIN INVENTOR i ON s.uniq_key = i.uniq_key
		WHERe	 1 = case when @paramFilter is null then 1 else case when serialno like '%'+ @paramFilter+ '%' then 1 else 0 end end

		
END