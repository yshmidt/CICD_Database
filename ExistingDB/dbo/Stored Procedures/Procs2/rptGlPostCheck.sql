
-- =============================================
-- Author:		Debbie
-- Create date: 07/06/2012
-- Description:	Created for the Posted Check Transactions 
-- Reports Using Stored Procedure:  glpostcheck.rpt
-- Modifications: 07/24/2012 DRP:	Found that when MICSSYS was added within the CR itself that as soon as the lic_name was added to the report it would take extremely long to display or even fail.  
--									The MICSSYS table has been removed from the CR and added to the procedure below
--				  12/04/2013 DRP:  added @userid in order for the procedure to work with the WebManex.
--				  12/15/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
--  			  09/29/16 DRP:	   it was found that if the check records were generated for example from auto bank deductions where no supplier was associated with the apchkmst record that the GenrRef would then just return NULL as soon as it could not find a matching supplier      
-- =============================================
CREATE PROCEDURE [dbo].[rptGlPostCheck]

		@lcFyBeg as char(4) = '' 
		,@lcPerBeg as numeric(2) = ''
		,@lcFyEnd as char(4) = ''
		,@lcPerEnd as numeric(2) = ''
		,@lcDiv as char(2) = null		--12/15/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin
	
SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT
		,gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
		,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
		,case WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CASE WHEN apchkmst.UNIQSUPNO = '' THEN CAST('Check Number: '+apchkmst.checkno + '  *No Supplier Assigned'  as varchar(80)) ELSE CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+apchkmst.checkno as varchar(80)) END  FROM APCHKMST left outer join SUPINFO on apchkmst.uniqsupno = supinfo.uniqsupno WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+checkno as varchar(80)) FROM APCHKMST,SUPINFO WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and SUPINFO.UNIQSUPNO = apchkmst.UNIQSUPNO)	--09/29/16 DRP:  replaced with the above to adress null values display in gthe GenrRef field if Uniqsupno was blank
			ELSE CAST('Cannot Link back to source' as varchar(60))
		end as GenrRef  
		,case WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKMST' THEN (SELECT CAST(RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) 
				FROm APCHKMST  where APCHKMST.APCHK_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))
			WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKDET'  THEN (SELECT case when apchkdet.invno <> '' then  CAST('Inv No: '+ RTRIM(APCHKDET.INVNO)+'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100))
					when apchkdet.INVNO = '' then CAST (rtrim(apchkdet.item_Desc) +'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) end
				FROm APCHKDET  where APCHKDET.APCKD_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))	
			else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100))end as DetailRef,micssys.LIC_NAME

--07/24/2012 DRP:  Added the MICSSYS table and lic_name above
FROM	GLTRANSHEADER  
		inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
		inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
		inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
		cross join micssys
		
where	gltransheader.TransactionType in('CHECKS')
		 and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
		 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
		 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
					 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter. 

end