
-- =============================================
-- Author:		Debbie
-- Create date: 05/18/2012
-- Description:	Created for the Defined Journal Entry for Standard Journal Entry
-- Reports Using Stored Procedure:  glsjlist.rpt
-- 08/16/17 VL added functional currency code and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[rptGlStndJeList]
@userid uniqueidentifier = null
as
begin

-- 08/15/17 VL separate FC and non FC
/*----------------------
None FC installation
*/----------------------
IF dbo.fn_IsFCInstalled() = 0 
	BEGIN
	select	glsjhdr.*,glsjdet.gl_nbr,debit,credit,GL_DESCR
	from	glsjhdr,glsjdet,gl_nbrs
	WHERE	GLSJHDR.glstndhkey = GLSJDET.fkglstndhkey
			AND GL_NBRS.GL_NBR = GLSJDET.gl_nbr
	END
ELSE
/*-----------------
 FC installation
*/-----------------
	BEGIN
	-- 08/16/17 VL added functional currency code
	select	glsjhdr.*,glsjdet.gl_nbr,debit,credit,ISNULL(FF.Symbol,'') AS FSymbol,debitFC,creditFC,ISNULL(TF.Symbol,'') AS TSymbol,debitPR,creditPR,ISNULL(PF.Symbol,'') AS PSymbol,GL_DESCR
	from	glsjhdr
		-- 08/15/17 VL added
		LEFT OUTER JOIN Fcused FF ON glsjhdr.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused TF ON glsjhdr.Fcused_uniq = TF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON glsjhdr.PrFcused_uniq = PF.Fcused_uniq	
		,glsjdet,gl_nbrs
	WHERE	GLSJHDR.glstndhkey = GLSJDET.fkglstndhkey
			AND GL_NBRS.GL_NBR = GLSJDET.gl_nbr
	END
end