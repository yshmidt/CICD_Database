
-- =============================================
-- Author:		Debbie
-- Create date: 07/09/2012
-- Description:	Created for the Posted Inventory Cost Transactions 
-- Reports Using Stored Procedure:  glpostinvtcost.rpt
-- Modifications: 07/24/2012 DRP:	Found that when MICSSYS was added within the CR itself that as soon as the lic_name was added to the report it would take extremely long to display or even fail.  
--									The MICSSYS table has been removed from the CR and added to the procedure below
--				  12/04/2013 DRP:  added @userid in order for the procedure to work with the WebManex.
--				  12/15/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
-- =============================================
CREATE PROCEDURE [dbo].[rptGlPostInvtCost]

		@lcFyBeg as char(4) = '' 
		,@lcPerBeg as numeric(2) = ''
		,@lcFyEnd as char(4) = ''
		,@lcPerEnd as numeric(2) = ''
		,@lcDiv as char(2) = null		--12/15/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin
SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
		gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
		,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
		,CASE WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO: '+confgvar.ponum+' Qty: '+CAST(rtrim(confgvar.qtytransf) as CHAR(10)) as varchar(80)) 
				else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO: '+confgvar.wono+' Qty: '+CAST(rtrim(confgvar.qtytransf) as CHAR(10)) as varchar (80))end 
				FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glTRANSDETAILS.cDrill) and Inventor.UNIQ_KEY =RTRIM(confgvar.uniq_key))
		ELSE CAST('Cannot Link back to source' as varchar(60))
		end as GenrRef  
		,CASE WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (SELECT CAST(rtrim(confgvar.vartype)+' Cost: ' +rtrim(gltrans.sourcetable)+'.'+RTRIM(gltrans.cidentifier)+': '+rtrim(cdrill)as varchar(100)) 
				FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glTRANSDETAILS.cDrill) and Inventor.UNIQ_KEY =RTRIM(confgvar.uniq_key))	
		else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) 
		end as DetailRef, micssys.LIC_NAME		

--07/24/2012 DRP:  Added the MICSSYS table and lic_name above		
FROM	GLTRANSHEADER  
		inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
		inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
		inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
		cross join micssys
		
where	gltransheader.TransactionType in('INVTCOSTS')
		and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
		 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
		 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
			 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter.
		 
end