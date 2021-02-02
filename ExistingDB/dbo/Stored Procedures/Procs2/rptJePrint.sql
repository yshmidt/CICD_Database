-- =============================================
-- Author:		Debbie Peltier
-- Create date: 08/29/2013
-- Description:	Journal Entry Erport
--- In VFP report froms JEPRINT
-- Modified:	10/01/2013 DRP:  I needed to add the union so it would also work for Not Approved Journal Entries also. 
--			07/18/16 DRP:  The union was not working in situations where the user would have more than one entry in the same JE that used the same GL# and the same value.  because of the union it would then only display one occurrance in the results and it was also changing the order which a user did not like, they wanted the order to be the same as they seen on screen.
--						   I created the declared table @Results, removed the union and just inserted the two sections into the @results tables.			
-- 08/14/17 VL Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptJePrint] 

@lcJeNo char(6) = ''
 , @userId uniqueidentifier=null 

as
Begin	

-- 08/14/17 VL Added functional currency code
declare @Results as table (JE_NO NUMERIC(6,0),DATE DATE,GL_NBR CHAR(13),GL_DESCR CHAR(30),DEBIT NUMERIC(14,2),CREDIT NUMERIC(14,2),
							DebitFC numeric(14,2), CreditFC numeric(14,2), DebitPR numeric(14,2), CreditPR numeric(14,2), FSymbol char(3), TSymbol char(3), PSymbol char(3))		--07/18/16 DRP:  NEEDED TO DECLARE THIS TABLE AND REMOVE THE UNION BELOW

INSERT INTO @RESULTS 
select	H.Je_no,h.TRANSDATE as Date,D.GL_NBR,GL_NBRS.GL_DESCR,d.DEBIT,D.CREDIT, d.DebitFC, d.CreditFC, d.DebitPR, d.CreditPR,
	ISNULL(FF.Symbol,'') AS FSymbol, ISNULL(TF.Symbol,'') AS TSymbol, ISNULL(PF.Symbol,'') AS PSymbol
from	GLJEHDR H 
		inner join GLJEDET D on H.UNIQJEHEAD = d.UNIQJEHEAD
		inner join GL_NBRS on D.GL_NBR = GL_NBRS.GL_NBR
		LEFT OUTER JOIN Fcused FF ON H.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused TF ON H.Fcused_uniq = TF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON H.PrFcused_uniq = PF.Fcused_uniq	
where	cast(H.JE_NO as CHAR(6)) = @lcJeNo

INSERT INTO @RESULTS
--10/01/2013 DRP: ADDED THE BELOW UNION SECTION FOR NOT APPROVED JOURNAL ENTRIES
--union
--union	--07/18/16 DRP:  REMOVED THE UNION AND WE ARE NOW USING THE INSERT INTO @RESULTS INSTEAD
select	h2.JE_NO,h2.TRANSDATE as Date,d2.GL_NBR,g2.GL_DESCR,d2.DEBIT,d2.CREDIT, d2.DebitFC, d2.CreditFC, d2.DebitPR, d2.CreditPR, 
	ISNULL(FF.Symbol,'') AS FSymbol, ISNULL(TF.Symbol,'') AS TSymbol, ISNULL(PF.Symbol,'') AS PSymbol
from GLJEHDRO H2
	 inner join GLJEDETO D2 on H2.JEOHKEY = D2.FKJEOH
		inner join GL_NBRS G2 on D2.GL_NBR = G2.GL_NBR
		LEFT OUTER JOIN Fcused FF ON H2.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused TF ON H2.Fcused_uniq = TF.Fcused_uniq	
		LEFT OUTER JOIN Fcused PF ON H2.PrFcused_uniq = PF.Fcused_uniq	
where cast(H2.JE_NO as CHAR(6)) = @lcJeNo

/*--------------------
None FC installation
*/--------------------
IF dbo.fn_IsFCInstalled() = 0
	SELECT Je_no, Date, Gl_nbr, Gl_descr, Debit, Credit FROM @Results
ELSE
/*--------------------
FC installation
*/--------------------
	SELECT Je_no, Date, Gl_nbr, Gl_descr, Debit, Credit, FSymbol, DebitFC, CreditFC, TSymbol, DebitPR, CreditPR, PSymbol FROM @Results

end