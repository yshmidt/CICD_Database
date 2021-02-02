-- =============================================
-- Author:		<Nilesh S>
-- Create date: <11/14/2017>
-- Description:	<Select GL Transactions Details for a specific trans_no>
-- [GetPostReverseTransactionData] '14001'
-- =============================================
CREATE PROCEDURE [dbo].[GetPostReverseTransactionData]
	-- Add the parameters for the stored procedure here
	@transNo NUMERIC(8)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT trans.GL_NBR,gl_descr,transdet.CREDIT AS 'DEBIT' ,transdet.DEBIT AS 'CREDIT',hed.TRANS_NO,hed.TRANS_DT,trans.GLUNIQ_KEY
	FROM GLTRANSHEADER hed 
	INNER JOIN gltrans trans ON hed.GLTRANSUNIQUE = trans.Fk_GLTRansUnique
	INNER JOIN GlTransDetails transdet ON trans.GLUNIQ_KEY=transdet.fk_gluniq_key 
	LEFT OUTER JOIN gl_nbrs ON trans.GL_NBR=GL_NBRS.GL_NBR 	     
	WHERE hed.TRANS_NO=@transNo
END
