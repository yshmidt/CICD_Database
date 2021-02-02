-- =============================================
-- Author:		Debbie	
-- Create date:	08/13/2014
-- Description:	procedure to get list of Internal Inventory Part numbers (both Make and Buy) used for the report's parameters . . . PASSED PN BECAUSE IT IS USED FOR PN RANGE PARAMETER SELECTIONS
--				I would normally pass the Uniq_key, but there were three existing reports that were just passing the Part Number itself for Range's, etc. . . this is why I created it to still pass the Part_no instead of the uniq_key
-- Modified:			
-- =============================================
CREATE PROCEDURE [dbo].[getParamsInternalPn] 

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
		select distinct  top(@top) Part_no as Value, rtrim(part_no) AS Text 
		from	inventor
		WHERE	custno = ''
				and STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
		
	else
		select distinct	part_no as Value, rtrim(part_no) AS Text 
		from	inventor
		WHERE	custno = ''
				and STATUS = 'Active'
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end

		
END
