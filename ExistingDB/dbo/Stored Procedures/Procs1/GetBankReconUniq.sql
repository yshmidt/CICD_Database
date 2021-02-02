
-- =============================================
-- Author:			Debbie
-- Create date:		10/22/2013
-- Description:		Compiles the details for the Bank Reconciliation reports
-- Used On:			Created to be used with the Parameter selection for the Bank Recon Report [bkrecon]
-- Modifications:	10/22/2013:  David helped adjust the code below to work properly with the Cascading Parameter for WebManex. 
--					07/11/2016 DRP:  needed to make sure that in the case where there were a large number of bank reconciliatin records that the user would be able to begin typing partial Statement Month and display the close matches
-- =============================================

CREATE procedure [dbo].[GetBankReconUniq]

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
		select  top(@top) RECONUNIQ as value,CAST(STMTDATE AS varchar(11)) as text 
	from	BKRECON br 
			INNER JOIN BANKS b on b.BK_UNIQ=br.BK_UNIQ 
	where	1 = case when @paramFilter is null then 1 when cast(stmtdate as varchar(11)) like '%'+@paramFilter+ '%' then 1 else 0 end 
			and br.BK_UNIQ=@lcBank
	order by stmtdate desc

	ELSE
	--select  RECONUNIQ as value,RTRIM(b.BANK)+' - '+ CAST(STMTDATE AS varchar(11)) as text
	select  RECONUNIQ as value,CAST(STMTDATE AS varchar(11)) as text
	from	BKRECON  br
			INNER JOIN BANKS b on b.BK_UNIQ=br.BK_UNIQ 
	where	1 = case when @paramFilter is null then 1 when cast(stmtdate as varchar(11)) like '%'+@paramFilter+ '%' then 1 else 0 end 
			and br.BK_UNIQ=@lcBank
	order by stmtdate desc


		
/***************************************/
/*the below was replaced with the above*/	--07/11/2016 DRP:  
/***************************************/
 /*
 	@UserId uniqueidentifier = null   -- check the user's limitation
	,@lcBank char(10) = null
	
as
begin	
	IF @lcBank IS NULL
		select RECONUNIQ,RTRIM(b.BANK)+' - '+ CAST(STMTDATE AS varchar(11)) from BKRECON br INNER JOIN BANKS b on b.BK_UNIQ=br.BK_UNIQ 
	ELSE
		select RECONUNIQ,STMTDATE from BKRECON where BK_UNIQ=@lcBank
end


*/

end