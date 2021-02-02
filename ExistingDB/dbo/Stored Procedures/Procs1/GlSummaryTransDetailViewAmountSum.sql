-- =============================================  
-- Author:  Nilesh Sa  
-- Create date: 09/07/2018  
-- Description: This SP used in the GLVIEW form for the detail tab to get credit and debit sum.  
-- exec GlSummaryTransDetailViewAmountSum N'0112000-01-00',N'2017',3,'2016-09-01 00:00:000','2016-09-30 00:00:00'
-- =============================================  
CREATE PROCEDURE [dbo].[GlSummaryTransDetailViewAmountSum]  
 -- Add the parameters for the stored procedure here  
  @lcGlNbr AS VARCHAR(13) = ' '  
 ,@fiscalYear AS CHAR(4) = null  
 ,@period AS NUMERIC(2,0) = null  
 ,@lcDateStart AS SMALLDATETIME= null  
 ,@lcDateEnd AS SMALLDATETIME = null  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets FROM  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 
 SELECT SUM(GlTransDetails.DEBIT) AS DEBIT, SUM(GlTransDetails.CREDIT) AS CREDIT
 FROM GLTRANSHEADER    
 INNER JOIN gltrans ON gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique AND gltrans.GL_NBr = @lcGlNbr  
 INNER JOIN GlTransDetails ON gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key      
 WHERE DATEDIFF(Day,GLTRANSHEADER.trans_dt,@lcDateStart)<=0     
 AND DATEDIFF(Day,GLTRANSHEADER.TRANS_DT,@lcDateEnd)>=0  
 AND GLTRANSHEADER.FY = @fiscalYear AND GLTRANSHEADER.Period = @period  
END
