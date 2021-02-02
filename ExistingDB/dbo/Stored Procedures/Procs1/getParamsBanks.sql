-- =============================================
-- Author:		Debbie	
-- Create date:	06/02/2016
-- Description:	procedure to get list of Banks.  Used with the AP Check Register Reports
-- Modified:	
-- 04/29/20 VL This parameter is used for internal bank, so added criteria internaluse = 1
-- =============================================
CREATE PROCEDURE [dbo].[getParamsBanks] 

--declare
@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
,@top int = null							-- if not null return number of rows indicated
,@customerStatus varchar (20) = 'All'
,@userId uniqueidentifier =null

as
begin

if (@top is not null) 
	select  top(@top) bk_uniq as Value,rtrim(BANK) + ': ' + BK_ACCT_NO AS Text 
	from	banks
	where	1 = case when @paramFilter is null then 1 when banks.bank like '%'+@paramFilter+ '%' then 1 else 0 end 
	AND internalUse = 1
	order by bank,accttitle,acct_type,bk_acct_no
else
	select  bk_uniq as Value,rtrim(BANK) + ': ' + BK_ACCT_NO AS Text
	from	banks
	where	1 = case when @paramFilter is null then 1 when banks.bank like '%'+@paramFilter+ '%' then 1 else 0 end 
	AND internalUse = 1
	order by bank,accttitle,acct_type,bk_acct_no


end
