-- =============================================
-- Author:		Debbie	
-- Create date:	08/14/2014
-- Description:	procedure to get list of part numbers but return Uniq_key  for the MRP used for the report's parameters
--	
-- =============================================
create PROCEDURE [dbo].[getParamsMrpUniqkey] 

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
		select  top(@top) uniq_key as Value, rtrim(part_no)+'   '+rtrim(revision) AS Text 
		from	View_MrpInvtNoConsg
		WHERe	1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
		
	else
		select distinct	UNIQ_KEY as Value, rtrim(part_no)+'   '+RTRIM(REVISION) AS Text 
		from	View_MrpInvtNoConsg
		WHERE  1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end

		
END
