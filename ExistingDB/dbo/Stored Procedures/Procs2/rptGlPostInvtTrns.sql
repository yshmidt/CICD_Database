
-- =============================================
-- Author:		Debbie
-- Create date: 07/09/2012
-- Description:	Created for the Posted Inventory Transactions 
-- Reports Using Stored Procedure:  glpostInvtTrns.rpt
-- Modifications: 07/24/2012 DRP:	Found that when MICSSYS was added within the CR itself that as soon as the lic_name was added to the report it would take extremely long to display or even fail.  
--									The MICSSYS table has been removed from the CR and added to the procedure below
-- 10/10/14 YS replace invtmfhd with 2 new tables
--				  12/04/2013 DRP:  added @userid in order for the procedure to work with the WebManex.
--				  12/15/2014 DRP:  Originally forgot to include the Division parameter when converted from VFP to SQL.  Added @lcDiv and filters for that new parameter 
-- =============================================
CREATE PROCEDURE [dbo].[rptGlPostInvtTrns]

		@lcFyBeg as char(4) = '' 
		,@lcPerBeg as numeric(2) = ''
		,@lcFyEnd as char(4) = ''
		,@lcPerEnd as numeric(2) = ''
		,@lcDiv as char(2) = null		--12/15/2014 DRP:  added the Division Paramater.   Null then it will show all Division. 
		,@userId uniqueidentifier=null

as
begin
--10/10/14 YS replace invtmfhd with 2 new tables
SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
		gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
		,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
		,CASE WHEN gltransheader.TransactionType = 'INVTISU' and gltrans.SourceSubTable = 'INVENTOR' THEN (SELECT  CAST('Inventory Issue: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill) as varchar (80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
			WHEN gltransheader.TransactionType = 'INVTISU' AND gltrans.SourceSubTable ='INVT_ISU' THEN CAST('Inventory Issue: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(CDRILL) as varchar (80)) 
			WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVENTOR' THEN (SELECT  CAST('Inventory Receipt: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill) as varchar (80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
			WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVT_REC' THEN CAST('Inventory Receipt: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(CDRILL) as varchar (80)) 
			when gltransheader.TransactionType = 'INVTTRNS' THEN 
			(SELECT CAST('Inventory Transfer: ' + rtrim(inventor.part_no)+'/'+ RTRIM(inventor.revision)+'  '+ RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+RTRIM(GLTRANS.CSUBIDENTIFIER)+': '+ rtrim(cDrill)as Varchar(80))
			FROM INVENTOR,INVTTRNS,INVTMFGR,
			--,INVTMFHD
			--10/10/14 YS replace invtmfhd with 2 new tables
			InvtMPNLink L , MfgrMaster M 
				WHERE INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) 
				AND INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.CDRILL) 
				AND INVTTRNS.FROMWKEY = INVTMFGR.W_KEY 
				--AND INVTMFGR.UNIQMFGRHD = INVTMFHD.UNIQMFGRHD)	
				AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD
				AND L.mfgrMasterId=M.MfgrMasterId)
		ELSE CAST('Cannot Link back to source' as varchar(60))
		end as GenrRef  
		,CASE when gltransheader.TransactionType = 'INVTISU' and gltrans.SourceSubTable = 'INVENTOR' 
		then (SELECT CAST('MFGR: '+ RTRIM(m.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ 'invtmfgr.w_key: '+ rtrim(invtmfgr.w_key)AS VARCHAR(100)) 
				FROM INVENTOR,INVT_ISU,INVTMFGR,--INVTMFHD
				InvtMPNLink L , MfgrMaster M
				--10/10/14 YS replace invtmfhd with 2 new tables
				WHERE L.mfgrMasterId=M.MfgrMasterId 
				AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) AND INVT_ISU.INVTISU_NO = RTRIM(GLTRANSDETAILS.CDRILL) AND INVT_ISU.W_KEY = INVTMFGR.W_KEY 
				AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)
			WHEN gltransheader.TransactionType = 'INVTISU' AND gltrans.SourceSubTable ='INVT_ISU' THEN CAST('Cannot Link back to source' as varchar (80)) 
			when gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVENTOR'  THEN (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ 'invtmfgr.w_key: '+ rtrim(invtmfgr.w_key)AS VARCHAR(100)) 
				FROM INVENTOR,INVT_REC,INVTMFGR,
				--INVTMFHD 
				--10/10/14 YS replace invtmfhd with 2 new tables
				InvtMPNLink L , MfgrMaster M 
				WHERE L.mfgrMasterId=M.MfgrMasterId 
				AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) AND INVT_REC.INVTREC_NO = RTRIM(GLTRANSDETAILS.CDRILL) AND INVT_REC.W_KEY = INVTMFGR.W_KEY 
				AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)
			WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVT_REC' THEN CAST('Cannot Link back to source' as varchar (80)) 
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill)AS VARCHAR(100)) 
				FROM INVENTOR,INVTTRNS,INVTMFGR,
				--INVTMFHD 
				--10/10/14 YS replace invtmfhd with 2 new tables
				InvtMPNLink L , MfgrMaster M 
				WHERE L.mfgrMasterId=M.MfgrMasterId 
				AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) 
				AND INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.CDRILL) 
				AND INVTTRNS.FROMWKEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)	
			else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) 
			end as DetailRef,micssys.LIC_NAME

--07/24/2012 DRP:  Added the MICSSYS table and lic_name above
FROM	GLTRANSHEADER  
		inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
		inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
		inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
		cross join micssys
		
WHERE	gltransheader.TransactionType in('INVTISU','INVTREC','INVTTRNS')
		and @lcFyBeg +dbo.padl(RTRIM(LTRIM(CAST(@lcPerBeg as CHAR(2)))),2,'0')<= GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
		 and @lcFyEnd +dbo.padl(RTRIM(LTRIM(CAST(@lcPerEnd as CHAR(2)))),2,'0')>=GLTRANSHEADER.FY+dbo.padl(RTRIM(LTRIM(CAST(GLTRANSHEADER.PERIOD  as CHAR(2)))),2,'0')
		 and 1 = case when @lcDiv is null OR @lcDiv = '*' then 1 else  
			 case when right(LEFT(gl_nbrs.gl_nbr,10),2) = @lcDiv then 1 else 0 END end	--12/15/2014 DRP:  Added this filter to work with the Division parameter. 
		 
end