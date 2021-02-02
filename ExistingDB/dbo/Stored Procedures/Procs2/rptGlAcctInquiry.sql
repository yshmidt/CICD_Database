
-- =============================================
-- Author:		Debbie
-- Create date: 05/17/2012
-- Description:	Created for the Account Inquiry report within General Ledger
-- Reports Using Stored Procedure:  glai.rpt
-- Modified:  01/15/2014 DRP:  added the @userid parameter for WebManex
--			  04/29/2015 DRP:  change the @lcGlAcct parameter to be @lcGlNbr in order to work with params we already have created for Cloud
--							   Changed ENDDATE to be PeriodEndDate otherwise the quickview was defaulting in incorrect info into the header from the timelog
-- 06/23/15 YS use sequencenumber column in glfiscalyrs table
--			 06/26/2015 DRP:  Changed <<cast (glfiscalyrs.FISCALYR as numeric(4,0)) as FiscalYr>> to <<glfiscalyrs.FISCALYR>> because there did not appear to be a reason to have to Cast it as numeric
-- =============================================
CREATE PROCEDURE [dbo].[rptGlAcctInquiry]

		@lcGlNbr as char(13) = ''
		,@lcFyBeg as char(4) = ''
		,@lcPerBeg as numeric(2) = ''
		,@lcFyEnd as char(4) = ''
		,@lcPerEnd as numeric(2) = ''
		,@userId uniqueidentifier=null 
		
as
begin
-- 06/23/15 YS use sequencenumber column in glfiscalyrs table
declare @startSequenceNumber int=0, @endSequenceNumber int=0
select @startSequenceNumber = isnull(sequencenumber,0) from GLFISCALYRS where FISCALYR=@lcFyBeg
select @endSequenceNumber = isnull(sequencenumber,0) from GLFISCALYRS where FISCALYR=@lcFyEnd
-- 06/23/15 YS use sequencenumber column in glfiscalyrs table
-- 06/23/15 YS Debbie if you are in this report please check to why casting fiscalyr
select	gl_acct.*, gl_nbrs.gl_descr,glfyrsdetl.period,glfiscalyrs.FiscalYr --,cast (glfiscalyrs.FISCALYR as numeric(4,0)) as FiscalYr	--06/26/2015 DRP:  replaced
		,glfyrsdetl.ENDDATE as PeriodEndDate,sequenceNumber
from	gl_acct, Gl_nbrs,GLFYRSDETL,glfiscalyrs
where	gl_acct.GL_NBR = gl_nbrs.GL_NBR
		and gl_acct.FK_FYDTLUNIQ = glfyrsdetl.FYDTLUNIQ
		and glfyrsdetl.FK_FY_UNIQ = GLFISCALYRS.FY_UNIQ
		and @lcGlNbr = gl_acct.GL_NBR
		and dbo.padl(rtrim(cast(SequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(Period as CHAR(2))),2,'0')
		between dbo.padl(rtrim(cast(@startSequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(@lcPerBeg as CHAR(2))),2,'0')
		and dbo.padl(rtrim(cast(@endSequenceNumber as char(4))),4,'0')+ dbo.padl(RTRIM(CAST(@lcPerEnd as CHAR(2))),2,'0')
		--and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLFISCALYRS.FISCALYR+dbo.padl(RTRIM(LTRIM(CAST(glfyrsdetl.PERIOD  as CHAR(2)))),2,'0')
		-- and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>= GLFISCALYRS.FISCALYR+dbo.padl(RTRIM(LTRIM(CAST(glfyrsdetl.PERIOD  as CHAR(2)))),2,'0')
					
order by sequenceNumber,PERIOD
end