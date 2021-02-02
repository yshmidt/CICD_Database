-- =============================================
-- Author:		Debbie	
-- Create date:	05/10/2016 
-- Description:	Procedure that will gather the banks that have existsing Cashbook records
-- Modified:	
-- =============================================
 create PROCEDURE [dbo].[getParamsBanks4CashBook] 
--declare
	@paramFilter varchar(200) = null,		--- first 3+ characters entered by the user
	@top int = null,							-- if not null return number of rows indicated
	@userId uniqueidentifier = null

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select distinct  banks.bk_uniq as Value,rtrim(BANK)+'     Acct# ' + rtrim(BK_ACCT_NO) +'     ' +rtrim(ACCTTITLE) as Text
		from	banks 
		where	bk_uniq in (select bk_uniq from cashbook)
				and 1 = case when @paramFilter is null then 1 else case when bank like @paramFilter+ '%' then 1 else 0 end end
	else
		select distinct	banks.bk_uniq as Value,rtrim(BANK)+'     Acct# ' + rtrim(BK_ACCT_NO) +'     ' +rtrim(ACCTTITLE) as Text 
		from	banks 
		where	bk_uniq in (select bk_uniq from cashbook)
				and 1 = case when @paramFilter is null then 1 else case when bank like @paramFilter+ '%' then 1 else 0 end end
END