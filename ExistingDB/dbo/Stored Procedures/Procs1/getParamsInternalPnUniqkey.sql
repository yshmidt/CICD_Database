-- =============================================
-- Author:		Debbie	
-- Create date:	01/16/2015
-- Description:	procedure to get list of Internal Inventory Part numbers (both Make and Buy) used for the report's parameters
-- Modified:		01/16/2015 DRP:  Copied this from the [getParamsInternalPn] procedure that is setup to pass the Part Number instead of the uniq_key.  This procedure is needed to pass the parts Uniq_key.
--					02/17/2015 DRP:  added @showRevision 
--					02/20/15 YS added @custno becuase .net hardcoded @custno as a parameter that sent to this procedure
--					04/28/2015 DRP:  removed STATUS = 'Active' because all of the reports that this procedure was used on was for history information.  If that is the case you will need to look up all Active and/or Inactive parts on the parameter
--	    			10/26/2015 Sachin S: remove the extra space between part no and revision becasue search functionility is not working while type part number manually
-- =============================================
CREATE PROCEDURE [dbo].[getParamsInternalPnUniqkey] 
--declare
	@paramFilter varchar(200) = '',		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@showrevision bit =1,
	@custno char(10)=' ',      -------------	02/20/15 YS added @custno becuase .net hardcoded @custno as a parameter that sent to this procedure
	@userId uniqueidentifier = null
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
	--                  10/26/2015 DRP: remove the extra space between part no and revision becasue search functionility is not working while type part number manually
		select distinct  top(@top) uniq_key as Value, cast(rtrim(part_no)+case when @showrevision=1 then ' '+rtrim(revision) else '' end as varchar(50))  AS Text 
		from	inventor
		WHERE	custno = ''
				--and STATUS = 'Active'		--04/28/2015 DRP: removed
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
		
	else
	--                  10/26/2015 DRP: remove the extra space between part no and revision becasue search functionility is not working while type part number manually
		select distinct	uniq_key as Value, cast(rtrim(part_no)+case when @showrevision=1 then ' '+rtrim(revision) else ' ' end as varchar(50)) as text
		from	inventor
		WHERE	custno = ''
				--and STATUS = 'Active'		--04/28/2015 DRP: removed
				and 1 = case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end

		
END