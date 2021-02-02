-- =============================================
-- Author:		Debbie	
-- Create date:	06/06/17
-- Description:	procedure to get list of Open Corrective Action Request list
-- Modifaction: 06/06/17 DRP:  removed the code that removed the leading zeros so it will sort on screen properly
-- =============================================
CREATE PROCEDURE [dbo].[getParamsOpenCar] 

--declare

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
		select top(@top) CARNO as Value,  CARNO+'     '+PROB_TYPE  AS Text  
		from	CRACTION 
		WHERE	COMPDATE is null
		--POSTATUS in ('CLOSED')
				and 1 = case when @paramFilter is null then 1 else case when CARNO like '%'+@paramFilter+ '%' then 1 else 0 end end
				
		ORDER BY CARNO
			
	else
		select	carno as Value, CARNO+'     '+PROB_TYPE  AS Text  
		from	CRACTION 
		WHERE	COMPDATE is null
				and 1 = case when @paramFilter is null then 1 else case when CARNO like '%'+@paramFilter+ '%' then 1 else 0 end end
		ORDER BY carno
		
END