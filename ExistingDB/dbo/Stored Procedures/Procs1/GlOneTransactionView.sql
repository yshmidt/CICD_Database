-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <06/29/11 >
-- Description:	<Select GL Transactions for a specific trans_no>
-- Modification:
-- 01/03/18 VL Added functional currency code
-- 01/04/18 VL Linked to GlJehdr table and added Fcused_uniq, Fchist_key... fields
-- =============================================
CREATE PROCEDURE [dbo].[GlOneTransactionView]
	-- Add the parameters for the stored procedure here
	@pnTransNo numeric(8)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select gltrans.GL_NBR,gl_descr,GlTrans.CREDIT,GlTrans.DEBIT,gltransheader.TRANS_NO,GLTRANSHEADER.TRANS_DT,GLTRANS.GLUNIQ_KEY,
		-- 01/03/18 VL added FC and PR fields
		GlTrans.CREDITPR,GlTrans.DEBITPR, ISNULL(Gljedet.CreditFC,0.00) AS CreditFC, ISNULL(Gljedet.DebitFC,0.00) AS DebitFC,
		-- 01/04/18 VL added the following fields
		Fcused_uniq, GLTRANSHEADER.PrFcused_uniq, GLTRANSHEADER.FuncFcused_uniq, Fchist_key, ENTERCURRBY
	    from gltrans left outer join gl_nbrs on GLTRANS.GL_NBR=GL_NBRS.GL_NBR 
	    INNER JOIN GLTRANSHEADER ON GLTRANS.Fk_GLTRansUnique=GLTRANSHEADER.GLTRANSUNIQUE  
		-- 01/03/18 VL add join with Gljedet, Gltransdetails to get FC values
		INNER JOIN GlTransDetails ON Gltrans.GlUniq_key = GlTransDetails.fk_gluniq_key
		LEFT OUTER JOIN GlJedet ON GlTransDetails.cSubDrill = GLJEDET.UniqJeDet AND GlTransDetails.cDrill = GLJEDET.UniqJeHead 
		-- 01/04/18 VL add link to GlJeHdr table
		LEFT OUTER JOIN GljeHdr ON GlTransDetails.cDrill = GLJEHDR.UniqJeHead 
		where GLTRANSheader.TRANS_NO=@pnTransNo
END