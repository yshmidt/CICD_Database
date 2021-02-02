
-- =============================================
-- Author:		Debbie
-- Create date: 07/06/2012
-- Description:	Created for the Posted Cash Receipt Transactions 
-- Reports Using Stored Procedure:  glpostcash.rpt
-- Modifications: 07/24/2012 DRP:	Found that when MICSSYS was added within the CR itself that as soon as the lic_name was added to the report it would take extremely long to display or even fail.  
--									The MICSSYS table has been removed from the CR and added to the procedure below
--				  12/04/2013 DRP:  added @userid in order for the procedure to work with the WebManex.
--				  12/15/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
--				  01/24/2017 VL:   Separate FC and non FC, added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptGlPostCash]

		@lcFyBeg as char(4) = '' 
		,@lcPerBeg as numeric(2) = ''
		,@lcFyEnd as char(4) = ''
		,@lcPerEnd as numeric(2) = ''
		,@lcDiv as char(2) = null		--12/15/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null
		
as
begin

IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT
			,gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case WHEN gltransheader.TransactionType = 'DEP' then cast('Deposit Number: ' + rtrim(cDrill) as varchar (80)) 
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Deposit Number: ' + rtrim(ARRETCK.DEP_NO)  as varchar(80)) from ARRETCK where gltransdetails.cdrill = arretck.UNIQRETNO) 
				ELSE CAST('Cannot Link back to source' as varchar(60))
				end as GenrRef  
			,case when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'ArCredit' then (select CAST('Inv#: '+rtrim(arcredit.INVNO) +'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(gltrans.cSubIdentifier)+': '+rtrim(cSubDrill) as varchar(100)) from ARCREDIT where arcredit.UNIQDETNO = gltransdetails.cSubDrill)
				when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'Deposits' then (select CAST(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill) as varchar(100)) from deposits where deposits.dep_no = gltransdetails.cSubDrill)
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100))end as DetailRef,micssys.LIC_NAME

	--07/24/2012 DRP:  Added the MICSSYS table and lic_name above 
	FROM	GLTRANSHEADER  
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR
			cross join micssys 
		
	where	gltransheader.TransactionType IN ('DEP','NSF')
			 and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
						 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter. 
	END
ELSE
	BEGIN
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT
			,gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			-- 01/24/17 VL added functional currency code
			,GlTransDetails.DEBITPR, GlTransDetails.CREDITPR, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol 
			,case WHEN gltransheader.TransactionType = 'DEP' then cast('Deposit Number: ' + rtrim(cDrill) as varchar (80)) 
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Deposit Number: ' + rtrim(ARRETCK.DEP_NO)  as varchar(80)) from ARRETCK where gltransdetails.cdrill = arretck.UNIQRETNO) 
				ELSE CAST('Cannot Link back to source' as varchar(60))
				end as GenrRef  
			,case when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'ArCredit' then (select CAST('Inv#: '+rtrim(arcredit.INVNO) +'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(gltrans.cSubIdentifier)+': '+rtrim(cSubDrill) as varchar(100)) from ARCREDIT where arcredit.UNIQDETNO = gltransdetails.cSubDrill)
				when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'Deposits' then (select CAST(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill) as varchar(100)) from deposits where deposits.dep_no = gltransdetails.cSubDrill)
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100))end as DetailRef,micssys.LIC_NAME

	--07/24/2012 DRP:  Added the MICSSYS table and lic_name above 
	FROM	GLTRANSHEADER  
			-- 01/24/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON GLTRANSHEADER.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON GLTRANSHEADER.FuncFcused_uniq = FF.Fcused_uniq			
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR
			cross join micssys 
		
	where	gltransheader.TransactionType IN ('DEP','NSF')
			 and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
						 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter. 

	
	END
end