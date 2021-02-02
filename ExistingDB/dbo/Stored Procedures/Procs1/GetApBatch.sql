-- =============================================
-- Author:		Debbie
-- Create date: 06/12/2014
-- Description:	Get list of all Open AP Check Batches
--- used as a source for 'apBatch4Bank' sourcename in mnxParamSources  (rptAPBatchDetails)
-- =============================================
CREATE PROCEDURE [dbo].[GetApBatch] 

	@lcBank varchar (max) = 'All' -- if null will select all product, @lcbk_uniq could have a single value for a Bank or a CSV
	,@UserId uniqueidentifier = null  -- check the user's limitation

as
begin
	
/*BANK LIST*/
	DECLARE  @tBank as tBank
			DECLARE @Bank TABLE (bk_uniq char(10))
		-- get list of Banks for @userid with access
		INSERT INTO @tbank select bk_uniq,BANK,accttitle,bk_acct_no from Banks;
		
		--SELECT * FROM @tBank	
		
		IF @lcBank is not null and @lcBank <>'' and @lcBank<>'All'
			insert into @Bank select * from dbo.[fn_simpleVarcharlistToTable](@lcBank,',')
					where CAST (id as CHAR(10)) in (select bk_uniq from @tBank)
		ELSE

		IF  @lcBank='All'	
		BEGIN
			INSERT INTO @Bank SELECT bk_uniq FROM @tBank
		END

select	distinct BATCHUNIQ,BATCHDESCR + bank,BATCH_DATE,apbatch.BK_UNIQ 
from	APBATCH 
		inner join BANKS on APBATCH.BK_UNIQ = banks.BK_UNIQ
where	IS_CLOSED <> 1 
		and  1 = CASE WHEN apbatch.bk_uniq IN(SELECT bk_uniq FROM @Bank) THEN 1 ELSE 0 END


	
END