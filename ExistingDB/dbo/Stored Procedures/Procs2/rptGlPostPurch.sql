
-- =============================================
-- Author:		Debbie
-- Create date: 07/06/2012
-- Description:	Created for the Posted Purchase Transactions 
-- Reports Using Stored Procedure:  glpostpurch.rpt
-- Modifications: 07/24/2012 DRP:	Found that when MICSSYS was added within the CR itself that as soon as the lic_name was added to the report it would take extremely long to display or even fail.  
--									The MICSSYS table has been removed from the CR and added to the procedure below
--				  12/04/2013 DRP:  added @userid in order for the procedure to work with the WebManex.
--				  12/15/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
--				  01/05/2017 VL:   added functional currency fields
-- =============================================
CREATE PROCEDURE [dbo].[rptGlPostPurch]

		@lcFyBeg as char(4) = '' 
		,@lcPerBeg as numeric(2) = ''
		,@lcFyEnd as char(4) = ''
		,@lcPerEnd as numeric(2) = ''
		,@lcDiv as char(2) = null		--12/15/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin

-- 01/05/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0			
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT
			,gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT  CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(80)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
					WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('UnReconciled Receipt: '+'Recv # '+Porecloc.RECEIVERNO  as varchar(80)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('Cannot Link back to source' as varchar(60))
			end as GenrRef  
			,case WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) +'  '+'Qty: '+rtrim(cast(PORecRelGl.TRANSQTY as CHAR(17))) + '  '+rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill)as varchar(100)) 
					FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ
					INNER JOIN PORECDTL ON PORECLOC.FK_UNIQRECDTL = PORECDTL.UNIQRECDTL
					INNER JOIN POITEMS ON PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO
					INNER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))			
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100))end as DetailRef,micssys.LIC_NAME
	--07/24/2012 DRP:  Added the MICSSYS table and lic_name above
	FROM	GLTRANSHEADER 
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR
			cross join micssys 
		
	where	gltransheader.TransactionType in('PURCH','UNRECREC')
			 and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
 			 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
				 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter. 

ELSE
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT
			,gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT  CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(80)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
					WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('UnReconciled Receipt: '+'Recv # '+Porecloc.RECEIVERNO  as varchar(80)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('Cannot Link back to source' as varchar(60))
			end as GenrRef  
			,case WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) +'  '+'Qty: '+rtrim(cast(PORecRelGl.TRANSQTY as CHAR(17))) + '  '+rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill)as varchar(100)) 
					FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ
					INNER JOIN PORECDTL ON PORECLOC.FK_UNIQRECDTL = PORECDTL.UNIQRECDTL
					INNER JOIN POITEMS ON PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO
					INNER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))			
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100))end as DetailRef,micssys.LIC_NAME,
			-- 01/05/17 VL added functional currency fields
			GlTransDetails.DEBITPR, GlTransDetails.CREDITPR, FF.Symbol AS FSymbol, PF.Symbol AS PSymbol

	--07/24/2012 DRP:  Added the MICSSYS table and lic_name above
	FROM	GLTRANSHEADER 
				-- 01/05/17 VL added to show currency symbol
				INNER JOIN Fcused PF ON GLTRANSHEADER.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON GLTRANSHEADER.FuncFcused_uniq = FF.Fcused_uniq
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR
			cross join micssys 
		
	where	gltransheader.TransactionType in('PURCH','UNRECREC')
			 and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
			 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
 			 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
				 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter. 

end