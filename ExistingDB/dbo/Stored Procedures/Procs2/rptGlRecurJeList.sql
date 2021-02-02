-- =============================================
-- Author:		Debbie
-- Create date: 05/18/2012
-- Description:	Created for the Defined Journal Entry for Recurring Journal Entry
-- Reports Using Stored Procedure:  glrelist.rpt
-- 08/16/17 VL added functional currency code and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[rptGlRecurJeList]
@userid uniqueidentifier = null
as
begin

-- 08/17/17 VL separate FC and non FC
/*----------------------
None FC installation
*/----------------------
IF dbo.fn_IsFCInstalled() = 0 
	BEGIN
	select	glrjhdr.*,glrjdet.gl_nbr,debit,credit,gl_descr
	from	GlRjHdr,GlRjDet,GL_NBRS
	where	glrjhdr.glrhdrkey = glrjdet.fkglrhdr
			and gl_nbrs.GL_NBR = glrjdet.gl_nbr
	END
ELSE
/*-----------------
 FC installation
*/-----------------
	BEGIN
	-- 08/17/17 VL added functional currency code
	select	GlRjHdr.*,GlRjDet.gl_nbr,debit,credit,ISNULL(FF.Symbol,'') AS FSymbol,debitFC,creditFC,ISNULL(TF.Symbol,'') AS TSymbol,debitPR,creditPR,ISNULL(PF.Symbol,'') AS PSymbol,GL_DESCR
	from	GlRjHdr
		LEFT OUTER JOIN Fcused FF ON GlRjHdr.FuncFcused_uniq = FF.Fcused_uniq
		LEFT OUTER JOIN Fcused TF ON GlRjHdr.Fcused_uniq = TF.Fcused_uniq
		LEFT OUTER JOIN Fcused PF ON GlRjHdr.PrFcused_uniq = PF.Fcused_uniq	
		,GlRjDet,gl_nbrs
	WHERE	GlRjHdr.glrhdrkey = GlRjDet.fkglrhdr
			AND GL_NBRS.GL_NBR = GlRjDet.gl_nbr

	END
end