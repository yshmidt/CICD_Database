
-- =============================================
-- Author:		Debbie
-- Create date: 07/09/2012
-- Description:	Created for the Posted Variance Transactions 
-- Reports Using Stored Procedure:  glpostvar.rpt
-- Modifications: 07/24/2012 DRP:	Found that when MICSSYS was added within the CR itself that as soon as the lic_name was added to the report it would take extremely long to display or even fail.  
--									The MICSSYS table has been removed from the CR and added to the procedure below
--				  12/04/2013 DRP:  added @userid in order for the procedure to work with the WebManex.
--				  12/15/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
--				  01/06/2017 VL:   added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptGlPostVar]

		@lcFyBeg as char(4) = '' 
		,@lcPerBeg as numeric(2) = ''
		,@lcFyEnd as char(4) = ''
		,@lcPerEnd as numeric(2) = ''
		,@lcDiv as char(2) = null		--12/15/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin

-- 01/06/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
IF @lFCInstalled = 0
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('Work Order: '+Confgvar.wono+'  Qty Trns: '+cast(confgvar.qtytransf as varchar(17)) as varchar(80)) FROm CONFGVAR where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Receiver No: '+Sinvoice.receiverno+'  '+'Inv: '+sinvoice.INVNO as varchar(80)) 
				FROM SINVOICE 
				where Sinvoice.SINV_UNIQ =RTRIM(gltransdetails.cSubDrill)) 
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'inventor.uniq_key: '+RTRIM(mfgrvar.uniq_key) as varchar(80)) 
				FROm MFGRVAR,INVENTOR
				 where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)
				 and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
				 WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Work Order: '+SCRAPREL.wono+'  '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(80)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
					WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
				ELSE CAST('Cannot Link back to source' as varchar(60))
			end as GenrRef 
			,case when GLTRANSHEADER.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(inventor.PART_NO)+'/'+rtrim(inventor.REVISION)+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) 
					from pur_var
					inner join SINVDETL on pur_var.SDET_UNIQ = sinvdetl.SDET_UNIQ 
					LEFT outer join POITEMS on sinvdetl.UNIQLNNO = poitems.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_Var.var_key = rtrim(gltransdetails.cdrill)) 
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('Work Order: '+MfgrVar.wono+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Qty Trnsf: '+ CAST (scraprel.qtytransf as CHAR(10))+'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill)as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) 
			end as DetailRef, micssys.LIC_NAME

	--07/24/2012 DRP:  Added the MICSSYS table and lic_name above 
	FROM	GLTRANSHEADER  
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
			cross join micssys

	where	gltransheader.TransactionType in('CONFGVAR','PURVAR','MFGRVAR','SCRAP','ROUNDVAR')
			and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
				 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter.
ELSE
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill,
			-- 01/06/17 VL added functional currency fields
			GlTransDetails.DEBITPR, GlTransDetails.CREDITPR,FF.Symbol AS FSymbol, PF.Symbol AS PSymbol
			,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('Work Order: '+Confgvar.wono+'  Qty Trns: '+cast(confgvar.qtytransf as varchar(17)) as varchar(80)) FROm CONFGVAR where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Receiver No: '+Sinvoice.receiverno+'  '+'Inv: '+sinvoice.INVNO as varchar(80)) 
				FROM SINVOICE 
				where Sinvoice.SINV_UNIQ =RTRIM(gltransdetails.cSubDrill)) 
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'inventor.uniq_key: '+RTRIM(mfgrvar.uniq_key) as varchar(80)) 
				FROm MFGRVAR,INVENTOR
				 where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)
				 and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
				 WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Work Order: '+SCRAPREL.wono+'  '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(80)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
					WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
				ELSE CAST('Cannot Link back to source' as varchar(60))
			end as GenrRef 
			,case when GLTRANSHEADER.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(inventor.PART_NO)+'/'+rtrim(inventor.REVISION)+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) 
					from pur_var
					inner join SINVDETL on pur_var.SDET_UNIQ = sinvdetl.SDET_UNIQ 
					LEFT outer join POITEMS on sinvdetl.UNIQLNNO = poitems.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_Var.var_key = rtrim(gltransdetails.cdrill)) 
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('Work Order: '+MfgrVar.wono+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Qty Trnsf: '+ CAST (scraprel.qtytransf as CHAR(10))+'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill)as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) 
			end as DetailRef, micssys.LIC_NAME

	--07/24/2012 DRP:  Added the MICSSYS table and lic_name above 
	FROM	GLTRANSHEADER  
			-- 01/06/17 VL added to show currency symbol
			INNER JOIN Fcused PF ON GLTRANSHEADER.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON GLTRANSHEADER.FuncFcused_uniq = FF.Fcused_uniq
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
			cross join micssys

	where	gltransheader.TransactionType in('CONFGVAR','PURVAR','MFGRVAR','SCRAP','ROUNDVAR')
			and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
				 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter.
end