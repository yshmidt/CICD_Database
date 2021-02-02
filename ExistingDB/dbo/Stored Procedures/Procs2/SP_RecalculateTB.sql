-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/23/2012
-- Description:	Recalculate TB
-- Modification:
-- 12/09/16 VL Added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[SP_RecalculateTB]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--re-calculate debit and credit

-- 12/19/16 VL added presentation currency fields
declare @RTEndB as numeric(14,2)=0.00,@RTBegBal as Numeric(14,2)=0.00, @RTEndBPR as numeric(14,2)=0.00,@RTBegBalPR as Numeric(14,2)=0.00
update View_GlAccts set  Beg_bal= 0, 
            End_bal = 0,
            Debit = 0,
            Credit = 0,
			-- 12/09/16 VL update presentation currency fields
			Beg_balPR= 0, 
            End_balPR = 0,
            DebitPR = 0,
            CreditPR = 0    


	
;with TransSum as
(
SELECT   Gltrans.Gl_nbr,GlTRansHeader.fy,GlTRansHeader.period, Gl_nbrs.STMT ,sum(gltrans.credit) as sum_credit,SUM(gltrans.debit) sum_debit,
	CAST(0.00 as numeric(14,2)) as begin_balance,CAST(0.00 as numeric(14,2)) as end_balance,
	-- 12/09/16 VL added presentation currency fields
	sum(gltrans.creditPR) as sum_creditPR,SUM(gltrans.debitPR) sum_debitPR,
	CAST(0.00 as numeric(14,2)) as begin_balancePR,CAST(0.00 as numeric(14,2)) as end_balancePR 
	,ROW_NUMBER() OVER(PARTITION BY gltrans.GL_nbr ORDER BY GlTRansHeader.FY,GlTRansHeader.Period ) as nseq
	from Gltrans inner join GLTRANSHEADER on Gltrans.Fk_GLTRansUnique = glTransHeader.GLTRANSUNIQUE
   INNER JOIN GL_NBRS ON GlTrans.GL_NBR =GL_NBRS.gl_nbr  
   GROUP BY  Gltrans.Gl_nbr,GlTRansHeader.fy,GlTRansHeader.period, Gl_nbrs.STMT
 ) 
 -- 12/09/16 VL added presentation currency fields
 update View_GlAccts SET debit=TransSum.sum_Debit,Credit=TransSum.Sum_Credit,
						debitPR=TransSum.sum_DebitPR,CreditPR=TransSum.Sum_CreditPR  
	FROM TransSum WHERE TransSum.GL_NBR =View_GlAccts.gl_nbr and TransSum.FY =View_GlAccts.FISCALYR  and TransSum.PERIOD =View_GlAccts.Period
	
update View_GlAccts SET @RTBegBal=Beg_bal=CASE WHEN Sequencenumber=1 THEN 0 ELSE @RTEndB END,
			  @RTEndB=End_bal=CASE WHEN Sequencenumber=1 THEN 0 ELSE @RTEndB END+Debit-Credit,
			   -- 12/09/16 VL added presentation currency fields	
			  @RTBegBalPR=Beg_balPR=CASE WHEN Sequencenumber=1 THEN 0 ELSE @RTEndBPR END,
			  @RTEndBPR=End_balPR=CASE WHEN Sequencenumber=1 THEN 0 ELSE @RTEndBPR END+DebitPR-CreditPR


END