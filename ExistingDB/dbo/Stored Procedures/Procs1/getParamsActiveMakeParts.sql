-- =============================================
-- Author:		David/Yelena
-- Create date: 08/08/2014
-- Description:	procedure to get list of active make parts used for the report's parameters
-- Modificaion:	08/14/2014 DRP:  needed to add @userId in order for it to work properly with the CloudManex
--				06/04/2015 DRP:  needed to change the filter below to include both MAKE and PHANTOM. 
-- Anuj K : 11/20/2015 Keeping the more than one spaces between the partno and revision, 
	-- it's not getting the records exact matching partno and revision so have to removed the spaces
 -- =============================================
CREATE PROCEDURE [dbo].[getParamsActiveMakeParts] 
	-- Add the parameters for the stored procedure here
	@paramFilter varchar(200) = NULL,		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier = null
	
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	if (@top is not null)
	-- Anuj K : 11/20/2015 Keeping the more than one spaces between the partno and revision, 
	-- it's not getting the records exact matching partno and revision so have to removed the spaces
		select top(@top) uniq_key as Value,rtrim(part_no)+' '+rtrim(revision) AS Text 
			from INVENTOR 
			WHERE STATUS = 'Active' and PART_SOURC IN('MAKE','PHANTOM') 
			and 1 = case when @paramFilter is null then 1 else case when 
				-- Anuj K : 11/20/2015 In auto complete displying the partno with revision , 
	            -- wherever trying to search partno with revision have search partno with revision than an only get the result
			rtrim(part_no)+' '+rtrim(revision)  like @paramFilter + '%' then 1 else 0 end end
			ORDER BY Part_no,Revision
	else
		select uniq_key as Value,rtrim(part_no)+' '+rtrim(revision) AS Text from INVENTOR 
		where 
		STATUS = 'Active' and PART_SOURC IN ('MAKE','PHANTOM') 
		and 1 = case when @paramFilter is null then 1 else case when 
		-- Anuj K : 11/20/2015 In auto complete displying the partno with revision , 
	    -- wherever trying to search partno with revision have search partno with revision than an only get the result
		rtrim(part_no)+' '+rtrim(revision) like @paramFilter + '%' then 1 else 0 end end
		ORDER BY Part_no,Revision
		
END