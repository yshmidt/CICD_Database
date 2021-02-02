
-- =============================================
-- Author:			Debbie
-- Create date:		07/13/16
-- Description:		Compiles a list of banks to select from for the Bank Reconciliation reports
-- Used On:			Created to be used with the Parameter selection for the Bank Recon Report [bkrecon]
-- Modifications:	07/25/16 DRP:  added a filter records from the Banks table that are not InternalUse 
-- =============================================

CREATE procedure [dbo].[GetBanks4Params]

--declare
@paramFilter varchar(200) = ''		--- first 3+ characters entered by the user
,@top int = null	
,@lcBank char(10) = ''						-- if not null return number of rows indicated
,@userId uniqueidentifier = null

			
as
begin	

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if (@top is not null) 
	--select  top(@top) RECONUNIQ as value,RTRIM(b.BANK)+' - '+ CAST(STMTDATE AS varchar(11)) as text 
	select  top(@top) bk_uniq as value,rtrim(BANK)+'     Acct# ' + rtrim(BK_ACCT_NO) +'     ' +rtrim(ACCTTITLE) as Text
	from	banks 
	where	1 = case when @paramFilter is null then 1 when rtrim(BANK) like '%'+@paramFilter+ '%' then 1 else 0 end 
			and banks.internaluse = 1
	order by bank 

	ELSE
	--select  RECONUNIQ as value,RTRIM(b.BANK)+' - '+ CAST(STMTDATE AS varchar(11)) as text
	select  bk_uniq as value,rtrim(BANK)+'     Acct# ' + rtrim(BK_ACCT_NO) +'     ' +rtrim(ACCTTITLE) as Text
	from	banks 
	where	1 = case when @paramFilter is null then 1 when rtrim(BANK) like '%'+@paramFilter+ '%' then 1 else 0 end 
			and banks.internalUse = 1
	order by bank
	
end 

		