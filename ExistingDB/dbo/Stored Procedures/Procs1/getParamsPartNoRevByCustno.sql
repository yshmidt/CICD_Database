-- =============================================
-- Author:		David	
-- Create date:	01/27/15
-- Description:	added to get internal or consigned parts based on provided custno. If blank, internal part will be returned
-- Modified:		01/16/2015 DRP:  Copied this from the [getParamsInternalPn] procedure that is setup to pass the Part Number instead of the uniq_key.  This procedure is needed to pass the parts Uniq_key.
-- =============================================
CREATE PROCEDURE [dbo].[getParamsPartNoRevByCustno]
--declare
	 @paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
	,@top int = null					-- if not null return number of rows indicated
	,@userId uniqueidentifier = null
	,@custno varchar(20) = ''
	,@showInternal bit = 1 -- not used now, but will eventually allow to find parts by customer part number, but return the intneral part number
	,@showRevision bit = 1
AS
BEGIN


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   		if (@top is not null)
			SELECT distinct  top(@top) uniq_key as Value, 
						CASE WHEN @custno = '' 
							THEN rtrim(PART_NO)+ rtrim(COALESCE(' | '+NULLIF(REVISION,''),'')) 
							ELSE rtrim(CUSTPARTNO) + rtrim(COALESCE(' | '+NULLIF(CUSTREV,''),'')) 
							END AS Text 
			from	inventor
			WHERE	custno = @custno
					and STATUS = 'Active'
					and 1 = CASE WHEN @custno='' THEN
								case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
							ELSE
								case when @paramFilter is null then 1 else case when CUSTPARTNO like @paramFilter+ '%' then 1 else 0 end end
							END
		
		else
			select distinct	uniq_key as Value, 
						CASE WHEN @custno = '' 
							THEN rtrim(PART_NO)+ rtrim(COALESCE(' | '+NULLIF(REVISION,''),'')) 
							ELSE rtrim(CUSTPARTNO) + rtrim(COALESCE(' | '+NULLIF(CUSTREV,''),'')) 
							END AS Text 
			from	inventor
			WHERE	custno = @custno
					and STATUS = 'Active'
					and 1 = CASE WHEN @custno='' THEN
								case when @paramFilter is null then 1 else case when part_no like @paramFilter+ '%' then 1 else 0 end end
							ELSE
								case when @paramFilter is null then 1 else case when CUSTPARTNO like @paramFilter+ '%' then 1 else 0 end end
							END
		
END
