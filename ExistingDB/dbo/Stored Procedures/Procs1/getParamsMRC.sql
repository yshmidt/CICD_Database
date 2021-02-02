-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/11/2018
-- Description:	procedure to get list of MRC used for the report's parameters
-- Modificaion:	
 -- =============================================
CREATE PROCEDURE [dbo].[getParamsMRC] 
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
		select DISTINCT top(@top) MRC as Value, MRC AS Text, 2 AS Seq
			from INVENTOR 
			WHERE STATUS = 'Active'
			AND MRC <> ''
			and 1 = case when @paramFilter is null then 1 else case when 
			MRC like @paramFilter + '%' then 1 else 0 end end
		UNION ALL 
		SELECT 'All' AS MRC, 'All' AS Text, 1 AS Seq
		ORDER BY Seq
	else
		select DISTINCT MRC as Value, MRC AS Text, 2 AS Seq 
			from INVENTOR 
			where STATUS = 'Active'
			AND MRC <> ''
			and 1 = case when @paramFilter is null then 1 else case when 
			MRC like @paramFilter + '%' then 1 else 0 end end
		UNION ALL 
		SELECT 'All' AS MRC, 'All' AS Text, 1 AS Seq
		ORDER BY Seq
END